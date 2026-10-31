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

const EDITIONS = new Set(['2015', '2018', '2021', '2024']);
// Used when nothing better is known: no manifest, unreadable manifest, or an
// edition this hook does not know (rustfmt would reject it anyway).
const FALLBACK_EDITION = '2021';

/**
 * The edition-relevant keys of a Cargo.toml: `[package] edition`, whether the
 * package inherits it (`edition.workspace = true` or
 * `edition = { workspace = true }`), and `[workspace.package] edition`.
 * Only keys in those two tables count; multi-line strings are skipped.
 *
 * This is a heuristic, not a TOML parser. It is built so that a misread
 * manifest ends in FALLBACK_EDITION rather than a confident wrong answer:
 * - `mentionsEdition`: the raw text names an edition at all; only a manifest
 *   that does not may yield cargo's default 2015.
 * - `ambiguous`: the text has multi-line strings (where the line scan can
 *   lose track) and the raw text holds more than one distinct edition value.
 * - `hasWorkspace`: the manifest is a workspace root, where cargo stops
 *   looking for inherited keys.
 */
function parseManifest(text) {
  const rawEditions = new Set([...text.matchAll(/^\s*edition\s*=\s*["'](\d{4})/gm)].map((m) => m[1]));
  const out = {
    hasPackage: false,
    hasWorkspace: false,
    pkgEdition: null,
    inherits: false,
    wsEdition: null,
    mentionsEdition: /^\s*\[?\s*["']?(package\.)?edition\b/m.test(text),
    ambiguous: /"""|'''/.test(text) && rawEditions.size > 1,
  };
  let table = '';
  let closer = null; // delimiter of the open multi-line string, if any
  for (const line of text.split(/\r?\n/)) {
    if (closer) {
      if (line.includes(closer)) closer = null;
      continue;
    }
    // A line opening a multi-line string: """ or ''' where a value starts
    // (after `=`, `[`, `,` or at the line start), not closed on the same
    // line. A delimiter inside a one-line string or comment can still be
    // taken for one; `ambiguous` makes that case fail safe.
    const open = line.match(/(^|[=[,])\s*("""|''')/);
    if (open) {
      const rest = line.slice(open.index + open[0].length);
      if (!rest.includes(open[2])) closer = open[2];
    }
    // A header is a whole line ([name] or [[name]], optional comment), so
    // array elements such as `  ["a", "b"],` are not taken for one.
    const header = line.match(/^\s*\[{1,2}\s*([^\]]+?)\s*\]{1,2}\s*(#.*)?$/);
    if (header) {
      table = header[1];
      if (table === 'package') out.hasPackage = true;
      if (table === 'workspace' || table.startsWith('workspace.')) out.hasWorkspace = true;
      continue;
    }
    if (table === '' && /^\s*workspace\s*[.=]/.test(line)) out.hasWorkspace = true;
    const value = line.match(/^\s*edition\s*=\s*["'](\d{4})["']/);
    if (table === 'package') {
      if (value) out.pkgEdition = value[1];
      if (/^\s*edition\.workspace\s*=\s*true\b/.test(line) || /^\s*edition\s*=\s*\{[^}]*\bworkspace\s*=\s*true\b/.test(line)) {
        out.inherits = true;
      }
    } else if (table === 'workspace.package' && value) {
      out.wsEdition = value[1];
    }
  }
  return out;
}

/** Parsed manifest at `file`, or null when it cannot be read. */
function readManifest(file) {
  try {
    return parseManifest(fs.readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
}

function known(edition) {
  return EDITIONS.has(edition) ? edition : FALLBACK_EDITION;
}

// Without a .git there is no repo root to stop at; the search checks the
// file's directory plus this many parents, enough for src/bin/x/main.rs.
const NO_GIT_LEVELS = 3;

/** Nearest Cargo.toml at most `levels` directories above `start` (inclusive). */
function findManifestNear(start, levels) {
  let dir = start;
  for (let i = 0; i <= levels; i++) {
    const candidate = path.join(dir, 'Cargo.toml');
    if (fs.existsSync(candidate)) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
  return null;
}

/**
 * Rust edition for `file`, as cargo would pick it: the nearest Cargo.toml's
 * `[package] edition`; `2015` (cargo's default) when the package names none;
 * the nearest ancestor's `[workspace.package] edition` when the package
 * inherits it. The edition matters because 2024 sorts imports differently.
 *
 * Reading a manifest runs nothing, so the search is not bounded the way tool
 * lookup is: inside a repo the package manifest is searched up to the repo
 * root, without a .git only a few levels up (an unrelated Cargo.toml in a
 * home directory must not decide), and the workspace manifest of an
 * inheriting package anywhere above (it may sit above a submodule's .git).
 */
function rustEdition(file, root) {
  const start = path.dirname(file);
  const manifest = fs.existsSync(path.join(root, '.git'))
    ? findUp(start, 'Cargo.toml', root)
    : findManifestNear(start, NO_GIT_LEVELS);
  if (!manifest) return FALLBACK_EDITION;
  const own = readManifest(manifest);
  if (!own || !own.hasPackage || own.ambiguous) return FALLBACK_EDITION;
  if (own.pkgEdition) return known(own.pkgEdition);
  if (!own.inherits) return own.mentionsEdition ? FALLBACK_EDITION : '2015';
  if (own.hasWorkspace) return own.wsEdition ? known(own.wsEdition) : FALLBACK_EDITION;

  // Like cargo: the nearest ancestor that is a workspace root decides, even
  // if this heuristic cannot read its edition (then the fallback applies).
  let dir = path.dirname(manifest);
  for (;;) {
    const parent = path.dirname(dir);
    if (parent === dir) break;
    const ws = findUp(parent, 'Cargo.toml');
    if (!ws) break;
    const parsed = readManifest(ws);
    if (!parsed) return FALLBACK_EDITION;
    if (parsed.hasWorkspace) {
      return parsed.wsEdition && !parsed.ambiguous ? known(parsed.wsEdition) : FALLBACK_EDITION;
    }
    dir = path.dirname(ws);
  }
  return FALLBACK_EDITION;
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
      return [['rustfmt', ['--check', '--edition', rustEdition(file, root), file]]];
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

  const raw = data.tool_input && data.tool_input.file_path;
  if (!raw || raw.split(/[\\/]/).includes('node_modules')) process.exit(0);
  // Normalised once: findUp compares directories as strings, so a path with
  // forward slashes on Windows would never equal the (backslashed) repo root
  // and the search would run past it -- up to tools outside the repo.
  const file = path.resolve(raw);

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
