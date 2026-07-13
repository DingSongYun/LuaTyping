#!/usr/bin/env bash
# Copies the built tlua-language-server runtime into rider-tlua/src/main/resources/bin/.
# Prerequisite: tlua-language-server/ has been built (bin/lua-language-server.exe exists).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/../../../tlua-language-server" && pwd)"
DEST="$SCRIPT_DIR/../src/main/resources/bin"

if [ ! -f "$SRC/bin/lua-language-server.exe" ]; then
  echo "ERROR: $SRC/bin/lua-language-server.exe not found. Build tlua-language-server first." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"

cp "$SRC/bin/lua-language-server.exe" "$DEST/"
cp "$SRC/main.lua"        "$DEST/"
cp "$SRC/errors.json"     "$DEST/"
cp -r "$SRC/script"       "$DEST/"
cp -r "$SRC/meta"         "$DEST/"
cp -r "$SRC/locale"       "$DEST/"

echo "Copied tlua-language-server runtime to $DEST"
