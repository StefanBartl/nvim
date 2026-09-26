#!/usr/bin/env node
// Claude Code PostToolUse hook (Edit|Write): after touching a source file,
// run the fast format/lint checks for its language. Exit 2 feeds the failure
// back to Claude as blocking feedback so it has to fix the file first.
//
// Only fast, per-file checks live here (no cargo check/clippy). Missing tools
// and missing project config are skipped, never blocking.
//
// Uses execFileSync (no shell) so the file path is never interpreted by a
// shell, even if it contains quotes or shell metacharacters -- except for a
// .cmd shim on Windows (see needsShell below), which is a shell by necessity
// and gets its own, narrower guard.

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const IS_WIN = process.platform === 'win32';

/**
 * Walk up from `start` and return the first existing `rel` path, or null.
 * Stops at `boundary` (inclusive) when given, so a repo with no local install
 * of a tool does not pick one up from an unrelated ancestor directory -- or,
 * worse, from a directory writable by something other than this project.
 */
function findUp(start, rel, boundary) {
  let dir = start;
  for (;;) {
    const candidate = path.join(dir, rel);
    if (fs.existsSync(candidate)) return candidate;
    if (boundary && dir === boundary) return null;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

/** Project-local node binary (node_modules/.bin) within `boundary`, or null. */
function localBin(dir, name, boundary) {
  return findUp(dir, path.join('node_modules', '.bin', IS_WIN ? `${name}.cmd` : name), boundary);
}

/**
 * Nearest ancestor of `file`'s directory that owns a `.git` (repo root), or
 * that directory itself when none is found. Deliberately unbounded -- this
 * IS the search for the boundary everything else bounds itself to.
 *
 * luacheck walks up from cwd for `.luacheckrc` on its own, but stylua does
 * not -- it only ever looks in cwd itself, never a parent -- so cwd has to
 * already be the directory the config lives in (normally the repo root) for
 * a file more than one level deep to be checked against the right config at
 * all.
 */
function projectRoot(file) {
  const dir = path.dirname(file);
  const git = findUp(dir, '.git');
  return git ? path.dirname(git) : dir;
}

/** Returns a list of [bin, args] checks for `file` under `root`, or [] when none apply. */
function checksFor(file, root) {
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
      return findUp(dir, '.clang-format', root) ? [['clang-format', ['--dry-run', '--Werror', file]]] : [];
    case '.ts':
    case '.tsx':
    case '.js':
    case '.jsx':
    case '.css':
    case '.json': {
      const prettier = localBin(dir, 'prettier', root);
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

  // Computed once and reused for both the binary search boundary and cwd --
  // it does its own filesystem walk up to .git, and neither use changes
  // within a single hook invocation.
  const root = projectRoot(file);

  const errors = [];
  for (const [bin, args] of checksFor(file, root)) {
    try {
      // .cmd shims on Windows need a shell; args are still a fixed, quoted list
      // -- EXCEPT that quoting does not stop cmd.exe from expanding a `%VAR%`
      // pattern anywhere in the command line, quoted or not (verified: it
      // substitutes the real environment variable value in place, regardless
      // of surrounding quotes or doubled percents). A `%` in `bin` or an arg
      // therefore either corrupts the path being checked or, if it happens to
      // name a real variable, leaks that variable's value into the tool
      // output this hook prints back to Claude. There is no shell-level
      // escape for it short of not reaching cmd.exe's parser at all, so this
      // skips the check rather than risk it -- a `%` in a source file's own
      // path is vanishingly rare, unlike the risk of silently leaking a
      // token-shaped env var through it.
      const needsShell = IS_WIN && bin.toLowerCase().endsWith('.cmd');
      if (needsShell && (bin.includes('%') || args.some((a) => a.includes('%')))) {
        console.error(`hint: skipping ${bin} -- a '%' in the path would be expanded by cmd.exe, so this is skipped rather than risk it.`);
        continue;
      }
      // cwd: the file's own repo root, not this process's. Without this, a
      // file written into another repo (e.g. a *.nvim plugin checkout) is
      // checked against whatever config luacheck/stylua find from wherever
      // this hook happened to be launched -- silently wrong rather than
      // missing. See projectRoot() for why it is the repo root and not just
      // the file's own directory.
      execFileSync(needsShell ? `"${bin}"` : bin, needsShell ? args.map((a) => `"${a}"`) : args, {
        stdio: 'pipe',
        shell: needsShell,
        cwd: root,
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
