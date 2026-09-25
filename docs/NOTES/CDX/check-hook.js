#!/usr/bin/env node
// Claude Code PostToolUse hook (Edit|Write): after touching a source file,
// run the fast format/lint checks for its language. Exit 2 feeds the failure
// back to Claude as blocking feedback so it has to fix the file first.
//
// Only fast, per-file checks live here (no cargo check/clippy). Missing tools
// and missing project config are skipped, never blocking.
//
// Uses execFileSync (no shell) so the file path is never interpreted by a
// shell, even if it contains quotes or shell metacharacters.

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const IS_WIN = process.platform === 'win32';

/** Walk up from `start` and return the first existing `rel` path, or null. */
function findUp(start, rel) {
  let dir = start;
  for (;;) {
    const candidate = path.join(dir, rel);
    if (fs.existsSync(candidate)) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

/** Project-local node binary (node_modules/.bin), or null. */
function localBin(dir, name) {
  return findUp(dir, path.join('node_modules', '.bin', IS_WIN ? `${name}.cmd` : name));
}

/** Returns a list of [bin, args] checks for `file`, or [] when none apply. */
function checksFor(file) {
  const dir = path.dirname(file);
  const ext = path.extname(file).toLowerCase();

  switch (ext) {
    case '.lua':
      return [
        ['stylua', ['--check', file]],
        ['luacheck', [file]],
      ];
    case '.rs':
      return [['rustfmt', ['--check', '--edition', '2021', file]]];
    case '.c':
    case '.cc':
    case '.cpp':
    case '.cxx':
    case '.h':
    case '.hpp':
      // Without a .clang-format the defaults would flag every file.
      return findUp(dir, '.clang-format') ? [['clang-format', ['--dry-run', '--Werror', file]]] : [];
    case '.ts':
    case '.tsx':
    case '.js':
    case '.jsx':
    case '.css':
    case '.json': {
      const prettier = localBin(dir, 'prettier');
      return prettier ? [[prettier, ['--check', file]]] : [];
    }
    default:
      return [];
  }
}

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
  if (!file || file.split(/[\\/]/).includes('node_modules')) process.exit(0);

  const errors = [];
  for (const [bin, args] of checksFor(file)) {
    try {
      // .cmd shims on Windows need a shell; args are still a fixed, quoted list.
      const needsShell = IS_WIN && bin.toLowerCase().endsWith('.cmd');
      execFileSync(needsShell ? `"${bin}"` : bin, needsShell ? args.map((a) => `"${a}"`) : args, {
        stdio: 'pipe',
        shell: needsShell,
      });
    } catch (err) {
      if (err.code === 'ENOENT') {
        console.error(`hint: '${bin}' not found on PATH, skipping this check.`);
        continue;
      }
      const out = (err.stdout || '').toString();
      const errOut = (err.stderr || '').toString();
      errors.push(`$ ${path.basename(bin)} ${args.join(' ')}\n${out}${errOut}`);
    }
  }

  if (errors.length) {
    console.error(`format/lint check failed for ${file}:\n\n${errors.join('\n\n')}`);
    process.exit(2);
  }
  process.exit(0);
});
