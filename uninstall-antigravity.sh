#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Uninstaller for Antigravity IDE (macOS/Linux)"
echo "==================================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Restore old settings
echo "⚙️  Step 1: Restoring Antigravity IDE settings..."
SETTINGS_DIR="$HOME/.config/Antigravity IDE/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Antigravity IDE/User"
fi

SETTINGS_FILE="$SETTINGS_DIR/settings.json"
LEGACY_BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark"
BACKUP_FILE=""

if [ -d "$SETTINGS_DIR" ]; then
    for candidate in "$SETTINGS_DIR"/settings.json.pre-islands-dark.*; do
        if [ -f "$candidate" ]; then
            BACKUP_FILE="$candidate"
            break
        fi
    done
fi

if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings restored from backup${NC}"
    echo "   Backup file: $BACKUP_FILE"
elif [ -f "$LEGACY_BACKUP_FILE" ]; then
    cp "$LEGACY_BACKUP_FILE" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings restored from backup${NC}"
    echo "   Backup file: $LEGACY_BACKUP_FILE"
else
    echo -e "${YELLOW}⚠️  No Antigravity settings backup found${NC}"
    echo "   You may need to manually update your Antigravity IDE settings."
fi

# Step 2: Disable Custom UI Style
echo ""
echo "🔧 Step 2: Disabling Custom UI Style..."
echo -e "${YELLOW}   Please disable Custom UI Style manually:${NC}"
echo "   1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)"
echo "   2. Run 'Custom UI Style: Disable'"
echo "   3. Antigravity IDE will reload"

# Step 3: Remove theme extension
echo ""
echo "🗑️  Step 3: Removing Islands Dark theme extension..."
EXT_BASE="$HOME/.antigravity-ide/extensions"
if [ -d "$EXT_BASE" ] || [ -L "$EXT_BASE" ]; then
    removed_any=false
    for ext_dir in "$EXT_BASE"/bwya77.islands-dark-*; do
        if [ -e "$ext_dir" ] || [ -L "$ext_dir" ]; then
            rm -rf "$ext_dir"
            removed_any=true
        fi
    done
    if [ "$removed_any" = true ]; then
        echo -e "${GREEN}✓ Theme extension removed${NC}"
    else
        echo -e "${YELLOW}⚠️  No Islands Dark extension directories found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Extensions directory not found (may already be removed)${NC}"
fi

# Step 4: Remove extension from extensions.json
echo ""
echo "📋 Step 4: Unregistering extension..."
if command -v node &> /dev/null; then
    if UNREGISTER_RESULT=$(node << 'UNREGISTER_SCRIPT'
const fs = require('fs');
const path = require('path');

const extJsonPath = path.join(process.env.HOME, '.antigravity-ide', 'extensions', 'extensions.json');
if (!fs.existsSync(extJsonPath)) {
    console.log('NO_FILE');
    process.exit(1);
}
try {
    const raw = fs.readFileSync(extJsonPath, 'utf8');
    let extensions = JSON.parse(raw);
    if (!Array.isArray(extensions)) {
        console.log('PARSE_ERROR');
        process.exit(1);
    }
    const islandsDarkIds = new Set(['bwya77.islands-dark']);
    const before = extensions.length;
    extensions = extensions.filter(e => !islandsDarkIds.has(e?.identifier?.id));
    if (extensions.length < before) {
        fs.writeFileSync(extJsonPath, JSON.stringify(extensions, null, 2) + '\n');
        console.log('REMOVED');
        process.exit(0);
    } else {
        console.log('NO_ENTRY');
        process.exit(1);
    }
} catch (e) {
    console.log('ERROR');
    process.exit(1);
}
UNREGISTER_SCRIPT
    ); then
        if [ "$UNREGISTER_RESULT" = "REMOVED" ]; then
            echo -e "${GREEN}✓ Extension unregistered${NC}"
        else
            echo -e "${YELLOW}⚠️  Unexpected unregister result: $UNREGISTER_RESULT${NC}"
        fi
    else
        case "$UNREGISTER_RESULT" in
            NO_FILE)
                echo -e "${YELLOW}⚠️  No extensions.json found${NC}"
                ;;
            NO_ENTRY)
                echo -e "${YELLOW}⚠️  Islands Dark was not registered${NC}"
                ;;
            PARSE_ERROR|ERROR)
                echo -e "${YELLOW}⚠️  Could not update extensions.json${NC}"
                ;;
            *)
                echo -e "${YELLOW}⚠️  Could not update extensions.json${NC}"
                ;;
        esac
    fi
else
    echo -e "${YELLOW}⚠️  Node.js not found; cannot unregister extension automatically${NC}"
fi

# Step 5: Change theme
echo ""
echo "🎨 Step 5: Change your color theme..."
echo "   1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)"
echo "   2. Search for 'Preferences: Color Theme'"
echo "   3. Select your preferred theme"

echo ""
echo -e "${GREEN}✓ Islands Dark has been uninstalled from Antigravity IDE!${NC}"
echo ""
echo "   Reload Antigravity IDE to complete the process."
echo ""
