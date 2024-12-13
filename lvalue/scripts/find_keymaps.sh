#!/bin/bash
# Dieses Skript durchsucht die Keymaps-Datei nach einem bestimmten Begriff

KEYMAP_FILE="$HOME/.config/nvim/lua/custom/mappings.lua"

if [ ! -f "$KEYMAP_FILE" ]; then
  echo "Keymap-Datei nicht gefunden: $KEYMAP_FILE"
  exit 1
fi

echo "Geben Sie den Suchbegriff ein:"
read -r query

echo "Ergebnisse für '$query' in $KEYMAP_FILE:"
grep -n "$query" "$KEYMAP_FILE"
