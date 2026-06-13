#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
tmp_bin="$tmp_home/bin"
output_file="$tmp_home/install-antigravity.out"
settings_dir="$tmp_home/.config/Antigravity IDE/User"
settings_file="$settings_dir/settings.json"

cleanup() { rm -rf "$tmp_home"; }
trap cleanup EXIT

mkdir -p "$tmp_bin" "$tmp_home/.antigravity-ide/extensions" "$tmp_home/.gemini/antigravity-ide" "$settings_dir"

cat >"$tmp_bin/agy-ide" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$tmp_bin/agy-ide"

cat >"$tmp_bin/jq" <<'EOF'
#!/bin/bash
set -euo pipefail
if [ "$1" != "-s" ]; then
  exit 1
fi
python3 - "$3" "$4" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as left_file:
    merged = json.load(left_file)
with open(sys.argv[2], encoding="utf-8") as right_file:
    merged.update(json.load(right_file))
print(json.dumps(merged, indent=2))
PY
EOF
chmod +x "$tmp_bin/jq"

cat >"$tmp_bin/date" <<'EOF'
#!/bin/bash
set -euo pipefail
if [ "${1:-}" = "+%Y%m%d-%H%M%S" ]; then
  counter_file="$HOME/.date-counter"
  counter=0
  if [ -f "$counter_file" ]; then
    counter=$(cat "$counter_file")
  fi
  counter=$((counter + 1))
  printf '%s' "$counter" > "$counter_file"
  printf '20260613-12000%d\n' "$counter"
else
  /bin/date "$@"
fi
EOF
chmod +x "$tmp_bin/date"

printf '%s\n' '[{"identifier":{"id":"other.extension"},"version":"1.2.3"}]' > "$tmp_home/.antigravity-ide/extensions/extensions.json"

cat >"$settings_file" <<'EOF'
{
  "editor.fontSize": 15,
  "workbench.colorTheme": "Default Dark+"
}
EOF

: > "$output_file"
for run in 1 2; do
  if HOME="$tmp_home" PATH="$tmp_bin:$PATH" OSTYPE=linux-gnu /bin/bash "$repo_root/install-antigravity.sh" >>"$output_file" 2>&1; then
    :
  else
    echo "install-antigravity.sh run $run exited nonzero" >&2
    cat "$output_file" >&2
    exit 1
  fi
done

ext_dir="$tmp_home/.antigravity-ide/extensions/bwya77.islands-dark-0.0.2"
if [ ! -d "$ext_dir" ]; then
  echo "ERROR: expected package.json-derived extension dir at $ext_dir" >&2
  cat "$output_file" >&2
  exit 1
fi

if [ ! -f "$tmp_home/.antigravity-ide/extensions/extensions.json" ]; then
  echo "ERROR: extensions.json was deleted" >&2
  cat "$output_file" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node -e "const fs=require('fs'); const data=JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); if (!Array.isArray(data) || !data.some(e => e.identifier?.id === 'other.extension')) process.exit(1);" "$tmp_home/.antigravity-ide/extensions/extensions.json" || {
    echo "ERROR: unrelated extension entry was not preserved in extensions.json" >&2
    cat "$output_file" >&2
    exit 1
  }
fi

python3 - "$settings_file" "$settings_dir" <<'PY'
import glob
import json
import os
import sys

settings_file, settings_dir = sys.argv[1:3]
with open(settings_file, encoding="utf-8") as file:
    settings = json.load(file)

if settings.get("editor.fontSize") != 15:
    raise SystemExit("ERROR: existing user settings were not preserved")
if settings.get("workbench.colorTheme") != "Islands Dark":
    raise SystemExit("ERROR: Islands Dark theme settings were not applied")

fixed_backup = settings_file + ".pre-islands-dark"
if os.path.exists(fixed_backup):
    raise SystemExit("ERROR: installer created fixed backup path instead of timestamped backup")

backups = sorted(glob.glob(os.path.join(settings_dir, "settings.json.pre-islands-dark.*")))
if len(backups) < 2:
    raise SystemExit("ERROR: repeated installer runs did not create distinct timestamped backups")

for backup in backups:
    with open(backup, encoding="utf-8") as file:
        backup_settings = json.load(file)
    if backup_settings.get("workbench.colorTheme") == "Default Dark+" and backup_settings.get("editor.fontSize") == 15:
        break
else:
    raise SystemExit("ERROR: original user settings were not preserved in a timestamped backup")
PY

echo "PASS"
