#!/usr/bin/env node
// Claude Code PostToolUse hook (Edit|Write): after touching a .lua file,
// run stylua --check + luacheck on it. Exit 2 feeds the failure back to
// Claude as blocking feedback so it has to fix the file before continuing.

const { execSync } = require('child_process');

let input = '';
process.stdin.on('data', (chunk) => (input += chunk));
process.stdin.on('end', () => {
  let data;
  try {
    data = JSON.parse(input);
  } catch {
    process.exit(0);
  }

  const file = data.tool_input && data.tool_input.file_path;
  if (!file || !file.endsWith('.lua')) process.exit(0);

  const errors = [];
  for (const cmd of [`stylua --check "${file}"`, `luacheck "${file}"`]) {
    try {
      execSync(cmd, { stdio: 'pipe' });
    } catch (err) {
      const out = (err.stdout || '').toString();
      const errOut = (err.stderr || '').toString();
      errors.push(`$ ${cmd}\n${out}${errOut}`);
    }
  }

  if (errors.length) {
    console.error(`stylua/luacheck failed for ${file}:\n\n${errors.join('\n\n')}`);
    process.exit(2);
  }
  process.exit(0);
});
