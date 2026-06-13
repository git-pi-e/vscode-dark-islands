#!/bin/bash

set -e


echo "🏝️  Islands Dark Theme Installer for Antigravity IDE (macOS/Linux)"
echo "=================================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if agy-ide command is available
if ! command -v agy-ide &> /dev/null; then
    echo -e "${RED}❌ Error: Antigravity IDE CLI (agy-ide) not found!${NC}"
    echo "Please install Antigravity IDE and make sure 'agy-ide' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open Antigravity IDE"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install agy-ide command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ Antigravity IDE CLI found (agy-ide)${NC}"

# Antigravity-specific safety check: Ensure Antigravity IDE should also have its product data directory initialized.
ANTIGRAVITY_IDE_DIR="$HOME/.gemini/antigravity-ide"
if [ ! -d "$ANTIGRAVITY_IDE_DIR" ]; then
    echo -e "${RED}❌ Error: Antigravity IDE directory not found!${NC}"
    echo "   Expected location: $ANTIGRAVITY_IDE_DIR"
    echo "   Please ensure Antigravity IDE is installed and has been run at least once."
    exit 1
fi

echo -e "${GREEN}✓ Antigravity IDE installation found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGE_VERSION=$(awk -F'"' '/"version"[[:space:]]*:/ { print $4; exit }' "$SCRIPT_DIR/package.json")
if [ -z "$PACKAGE_VERSION" ]; then
    echo -e "${RED}❌ Could not read theme version from package.json${NC}"
    exit 1
fi

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to Antigravity IDE extensions directory
EXT_BASE="$HOME/.antigravity-ide/extensions"
EXT_DIR="$EXT_BASE/bwya77.islands-dark-$PACKAGE_VERSION"
mkdir -p "$EXT_BASE"
rm -rf "$EXT_BASE"/bwya77.islands-dark-*
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}✓ Theme extension installed to $EXT_DIR${NC}"
else
    echo -e "${RED}❌ Failed to install theme extension${NC}"
    exit 1
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if agy-ide --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace in Antigravity IDE"
fi

echo ""
echo "🔤 Step 3: Installing Bear Sans UI fonts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed to Font Book${NC}"
    echo "   Note: You may need to restart applications to use the new fonts"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect OS type for automatic font installation${NC}"
    echo "   Please manually install the fonts from the 'fonts/' folder"
fi

echo ""
echo "⚙️  Step 4: Applying Antigravity IDE settings..."

SETTINGS_DIR="$HOME/.config/Antigravity IDE/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Antigravity IDE/User"
fi

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Backup existing settings if they exist, then merge
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."

    if command -v jq &> /dev/null; then
        # Merge: user's non-theme settings are preserved, Islands Dark theme keys win
        # This ensures updated fixes are applied while keeping user customizations
        if MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$SCRIPT_DIR/settings.json" 2>/dev/null); then
            echo "$MERGED" > "$SETTINGS_FILE"
            echo -e "${GREEN}✓ Settings merged (your non-theme settings preserved, theme settings updated)${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not parse existing settings.json - leaving it untouched${NC}"
            echo "   Your backup is at: $BACKUP_FILE"
            echo "   To apply Islands Dark settings, manually merge from: $SCRIPT_DIR/settings.json"
        fi
    else
        echo -e "${YELLOW}⚠️  jq not found - cannot merge settings safely${NC}"
        echo "   Your backup is at: $BACKUP_FILE"
        echo "   To apply Islands Dark settings, manually merge from: $SCRIPT_DIR/settings.json"
        echo "   Or install jq (https://jqlang.github.io/jq/) and re-run this script"
    fi
else
    # No existing settings - just copy
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Islands Dark settings applied${NC}"
fi

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   Antigravity IDE will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run_antigravity"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes for Antigravity IDE users:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After Antigravity IDE reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected — click the gear icon and select 'Don't Show Again'"
    echo "   • To activate the theme in Antigravity IDE, use the theme picker (Cmd/Ctrl+K Cmd/Ctrl+T)"
    echo "   • After every Antigravity IDE update, re-run 'Custom UI Style: Reload' to reapply"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload Antigravity IDE..."
    fi
fi

echo "   Applying CSS customizations..."

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed for Antigravity IDE!"
echo "   Antigravity IDE will now reload to apply the custom UI style."
echo ""

if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed for Antigravity IDE!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading Antigravity-IDE..."
agy-ide --reload-window 2>/dev/null || agy-ide . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
