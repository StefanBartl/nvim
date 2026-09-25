#!/usr/bin/env bash
# Richtet Claude Code auf dieser Maschine (Linux/macOS) gemaess der in
# diesem Ordner versionierten Vorlagen ein (Env-Vars, ~/.claude/CLAUDE.md,
# ~/.claude/settings.json). Idempotent - nach jedem Pull erneut ausfuehrbar.
# Windows-Pendant: setup-claude-code.ps1
#
# Usage: ./setup-claude-code.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# CDX -> NOTES -> docs -> nvim-config-root
NVIM_CONFIG="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "NVIM_CONFIG = $NVIM_CONFIG"

# --- 1. Env-Variablen -------------------------------------------------------

echo
echo "[1/3] Env-Variablen"

mkdir -p "$CLAUDE_DIR"
ENV_FILE="$CLAUDE_DIR/env.sh"

REPOS_DIR_VALUE="${REPOS_DIR:-}"
if [ -z "$REPOS_DIR_VALUE" ] && [ -f "$ENV_FILE" ]; then
  REPOS_DIR_VALUE="$(sed -n 's/^export REPOS_DIR="\(.*\)"$/\1/p' "$ENV_FILE" | tail -1)"
fi
if [ -z "$REPOS_DIR_VALUE" ]; then
  while true; do
    read -r -p "  REPOS_DIR ist auf dieser Maschine nicht gesetzt. Pfad zur Repos-Wurzel eingeben (z.B. /home/user/repos): " REPOS_DIR_VALUE
    if [ -n "$REPOS_DIR_VALUE" ] && [ -d "$REPOS_DIR_VALUE" ]; then
      break
    fi
    echo "  Pfad '$REPOS_DIR_VALUE' existiert nicht - bitte erneut eingeben."
  done
  echo "  REPOS_DIR gesetzt: $REPOS_DIR_VALUE"
else
  echo "  REPOS_DIR bereits gesetzt: $REPOS_DIR_VALUE"
fi

cat > "$ENV_FILE" <<EOF
# Generiert von setup-claude-code.sh - nicht von Hand editieren.
export NVIM_CONFIG="$NVIM_CONFIG"
export REPOS_DIR="$REPOS_DIR_VALUE"
EOF
echo "  $ENV_FILE geschrieben."

SOURCE_LINE="[ -f \"$ENV_FILE\" ] && . \"$ENV_FILE\""
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ]; then
    if ! grep -qF "$ENV_FILE" "$rc"; then
      printf '\n# Claude Code env (siehe %s)\n%s\n' "$ENV_FILE" "$SOURCE_LINE" >> "$rc"
      echo "  Sourcing-Zeile ergaenzt in $rc"
    else
      echo "  $rc sourced $ENV_FILE bereits."
    fi
  fi
done

echo "  Hinweis: neue Shell starten (oder 'source $ENV_FILE'), damit die Env-Vars gelten."

# --- 2. ~/.claude/CLAUDE.md (Symlink, Fallback Kopie) -----------------------

echo
echo "[2/3] CLAUDE.md"

CLAUDE_MD_SOURCE="$SCRIPT_DIR/CLAUDE.global.md"
CLAUDE_MD_TARGET="$CLAUDE_DIR/CLAUDE.md"

if [ -L "$CLAUDE_MD_TARGET" ] && [ "$(readlink "$CLAUDE_MD_TARGET")" = "$CLAUDE_MD_SOURCE" ]; then
  echo "  Symlink bereits korrekt."
else
  if [ -e "$CLAUDE_MD_TARGET" ] || [ -L "$CLAUDE_MD_TARGET" ]; then
    backup="$CLAUDE_MD_TARGET.bak-$(date +%Y%m%d-%H%M%S%N)"
    mv "$CLAUDE_MD_TARGET" "$backup"
    echo "  Bestehende CLAUDE.md gesichert nach: $backup"
  fi
  ln -s "$CLAUDE_MD_SOURCE" "$CLAUDE_MD_TARGET"
  echo "  Symlink angelegt: $CLAUDE_MD_TARGET -> $CLAUDE_MD_SOURCE"
fi

# --- 3. ~/.claude/settings.json (Merge, via gemeinsames Node-Skript) --------

echo
echo "[3/3] settings.json"

if ! command -v node > /dev/null 2>&1; then
  echo "  FEHLER: node nicht gefunden. Wird sowohl fuer den Merge als auch fuer" >&2
  echo "  check-lua-hook.js gebraucht - bitte Node.js installieren und Skript erneut ausfuehren." >&2
  exit 1
fi

node "$SCRIPT_DIR/merge-claude-settings.js" \
  "$SCRIPT_DIR/settings.global.json" \
  "$CLAUDE_DIR/settings.json" \
  "$NVIM_CONFIG"

echo
echo "Fertig."
