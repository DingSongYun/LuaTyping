#!/usr/bin/env bash
# Copies the built tlua-language-server runtime into vscode-tlua/server/.
# Layout (server runtime expects exe in a bin/ subdir so bootstrap can resolve
# root as exe's grandparent = server/, and find script/ there):
#   server/bin/lua-language-server.exe   (the server executable)
#   server/bin/main.lua                  (bootstrap, from bin/main.lua — NOT the top-level main.lua)
#   server/main.lua                      (main program)
#   server/{script,meta,locale,errors.json}
# Prerequisite: tlua-language-server/ has been built (bin/lua-language-server.exe exists).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/../../../tlua-language-server" && pwd)"
DEST="$SCRIPT_DIR/../server"

if [ ! -f "$SRC/bin/lua-language-server.exe" ]; then
  echo "ERROR: $SRC/bin/lua-language-server.exe not found. Build tlua-language-server first." >&2
  exit 1
fi
if [ ! -f "$SRC/bin/main.lua" ]; then
  echo "ERROR: $SRC/bin/main.lua (bootstrap) not found. Build tlua-language-server first." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST/bin"

cp "$SRC/bin/lua-language-server.exe" "$DEST/bin/"
cp "$SRC/bin/main.lua"                "$DEST/bin/"   # bootstrap (renamed by make.lua from make/bootstrap.lua)
cp "$SRC/main.lua"                    "$DEST/"        # main program
cp "$SRC/debugger.lua"                "$DEST/"        # dofile'd by brave workers (pub.lua)
cp "$SRC/errors.json"                 "$DEST/"
cp -r "$SRC/script"                   "$DEST/"
cp -r "$SRC/meta"                     "$DEST/"
cp -r "$SRC/locale"                   "$DEST/"

echo "Copied tlua-language-server runtime to $DEST"
