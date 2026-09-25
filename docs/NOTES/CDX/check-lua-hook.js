#!/usr/bin/env node
// Claude Code PostToolUse hook (Edit|Write): after touching a .lua file,
// run stylua --check + luacheck on it. Exit 2 feeds the failure back to
// Claude as blocking feedback so it has to fix the file before continuing.
//
// Uses execFileSync (no shell) so the file path is never interpreted by a
// shell, even if it contains quotes or shell metacharacters.

const { execFileSync } = require('child_process');

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

  const checks = [
    ['stylua', ['--check', file]],
    ['luacheck', [file]],
  ];

  const errors = [];
  for (const [bin, args] of checks) {
    try {
      execFileSync(bin, args, { stdio: 'pipe' });
    } catch (err) {
      if (err.code === 'ENOENT') {
        console.error(`hint: '${bin}' not found on PATH, skipping this check.`);
        continue;
      }
      const out = (err.stdout || '').toString();
      const errOut = (err.stderr || '').toString();
      errors.push(`$ ${bin} ${args.join(' ')}\n${out}${errOut}`);
    }
  }

  if (errors.length) {
    console.error(`stylua/luacheck failed for ${file}:\n\n${errors.join('\n\n')}`);
    process.exit(2);
  }
  process.exit(0);
});
