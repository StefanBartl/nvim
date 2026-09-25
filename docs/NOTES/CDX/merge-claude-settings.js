#!/usr/bin/env node
// Shared merge logic for ~/.claude/settings.json, used by both
// setup-claude-code.ps1 (Windows) and setup-claude-code.sh (Linux/macOS)
// so the two platform scripts can't drift out of sync on this logic.
//
// Usage: node merge-claude-settings.js <templatePath> <settingsPath> <nvimConfigPath>
//
// - Merges permissions.allow as a deduplicated union.
// - Appends hooks.PostToolUse entries from the template that aren't
//   already present (matched by matcher + hooks[0].command).
// - Leaves every other existing top-level key untouched.
// - Backs up an existing settings.json before overwriting it.

const fs = require('fs');

const [, , templatePath, settingsPath, nvimConfigPathRaw] = process.argv;
if (!templatePath || !settingsPath || !nvimConfigPathRaw) {
  console.error('usage: node merge-claude-settings.js <templatePath> <settingsPath> <nvimConfigPath>');
  process.exit(1);
}

const nvimConfigPath = nvimConfigPathRaw.replace(/\\/g, '/');
const templateJson = fs.readFileSync(templatePath, 'utf8').replace(/__NVIM_CONFIG__/g, nvimConfigPath);
const template = JSON.parse(templateJson);

let existing = {};
if (fs.existsSync(settingsPath)) {
  const backup = `${settingsPath}.bak-${new Date().toISOString().replace(/[:.]/g, '-')}`;
  fs.copyFileSync(settingsPath, backup);
  console.log(`  Bestehende settings.json gesichert nach: ${backup}`);
  existing = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
}

existing.permissions ??= {};
existing.permissions.allow ??= [];
existing.permissions.allow = [...new Set([...existing.permissions.allow, ...(template.permissions?.allow ?? [])])];

existing.hooks ??= {};
existing.hooks.PostToolUse ??= [];
// Drop the superseded Lua-only hook (replaced by check-hook.js) to avoid double runs.
existing.hooks.PostToolUse = existing.hooks.PostToolUse.filter((e) => {
  const stale = e.hooks?.some((h) => h.command?.includes('check-lua-hook.js'));
  if (stale) console.log('  Veralteten Hook check-lua-hook.js entfernt.');
  return !stale;
});
for (const entry of template.hooks?.PostToolUse ?? []) {
  const entryCommand = entry.hooks?.[0]?.command;
  const alreadyPresent = existing.hooks.PostToolUse.some(
    (e) => e.matcher === entry.matcher && e.hooks?.[0]?.command === entryCommand
  );
  if (alreadyPresent) {
    console.log(`  Hook fuer Matcher '${entry.matcher}' bereits vorhanden - uebersprungen.`);
  } else {
    existing.hooks.PostToolUse.push(entry);
    console.log(`  Hook fuer Matcher '${entry.matcher}' ergaenzt.`);
  }
}

fs.writeFileSync(settingsPath, `${JSON.stringify(existing, null, 2)}\n`, 'utf8');
console.log(`  settings.json geschrieben: ${settingsPath}`);
