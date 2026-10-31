// End-to-end test for check-hook.js: Rust edition detection.
// Run: node check-hook.test.js   (skips with exit 0 when rustfmt is missing)
//
// Every case is a deliberately misformatted main.rs, so the hook always fails
// and prints the `rustfmt --edition` it chose. The bar for the heuristic: the
// correct edition, or the fallback 2021 -- never a confident wrong one.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const HOOK = path.join(__dirname, 'check-hook.js');

if (spawnSync('rustfmt', ['--version']).error) {
  console.log('skip: rustfmt not on PATH');
  process.exit(0);
}

/** True when `dir` or one of its ancestors holds a .git. */
function underGit(dir) {
  for (let d = dir; ; d = path.dirname(d)) {
    if (fs.existsSync(path.join(d, '.git'))) return true;
    if (path.dirname(d) === d) return false;
  }
}

const base = fs.mkdtempSync(path.join(os.tmpdir(), 'check-hook-test-'));
let failed = 0;
try {
  const BAD = 'fn  main(){}\n';
  const mk = (rel, text) => {
    const p = path.join(base, rel);
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, text);
  };
  const git = (rel) => fs.mkdirSync(path.join(base, rel, '.git'), { recursive: true });

  const cases = [];
  const crate = (name, manifest, expect, opts = {}) => {
    mk(`${name}/Cargo.toml`, manifest);
    mk(`${name}/src/main.rs`, BAD);
    if (!opts.noGit) git(name);
    cases.push([`${name}/src/main.rs`, expect]);
  };

  crate('pkg2018', '[package]\nname="a"\nedition = "2018"\n', '2018');
  crate('noedition', '[package]\nname="a"\n', '2015');
  crate('comment3q', '[package]\nname="a"\n# use """ for docs\nedition = "2024"\n', '2024');
  crate('sq3inline', "[package]\nname=\"a\"\ndescription = 'say \"\"\" hi'\nedition = \"2024\"\n", '2024');
  crate('mixed', '[package]\nname="a"\ndescription = """\nit\'\'\'s\n"""\nedition = "2024"\n', '2024');
  crate('arrays', '[package]\nname="a"\nkeywords = [\n  ["a","b"],\n]\nedition = "2024"\n', '2024');
  crate('quotedkey', '[package]\nname="a"\n"edition" = "2024"\n', '2021');
  // An edition line inside a multi-line string next to the real one: ambiguous.
  crate('multiline', '[package]\nname="g"\ndescription = """\nedition = "2015"\n"""\nedition = "2024"\n', '2021');
  crate('mlarray', '[package]\nname="a"\nx = ["""\na\n""", """\nedition = "2015"\n"""]\nedition = "2024"\n', '2021');
  crate(
    'template',
    "[package]\nname=\"a\"\ndescription = 'x, \"\"\" y'\nedition = \"2024\"\n[package.metadata.t]\nt = \"\"\"\n[package]\nedition = \"2015\"\n\"\"\"\n",
    '2021',
  );
  crate('invalid', '[package]\nname="i"\nedition = "2019"\n', '2021');
  crate('nogit', '[package]\nname="f"\nedition = "2024"\n', '2024', { noGit: true });

  // workspace member inheriting
  mk('ws/Cargo.toml', '[workspace]\nmembers=["m"]\n[workspace.package]\nedition = "2024"\n');
  mk('ws/m/Cargo.toml', '[package]\nname="m"\nedition.workspace = true\n');
  mk('ws/m/src/main.rs', BAD);
  git('ws');
  cases.push(['ws/m/src/main.rs', '2024']);

  // submodule member: own .git, workspace root above it
  mk('sub/Cargo.toml', '[workspace]\nmembers=["m"]\n[workspace.package]\nedition = "2024"\n');
  mk('sub/m/Cargo.toml', '[package]\nname="m"\nedition = { workspace = true }\n');
  mk('sub/m/src/main.rs', BAD);
  git('sub');
  fs.writeFileSync(path.join(base, 'sub/m/.git'), 'gitdir: ../.git/modules/m\n');
  cases.push(['sub/m/src/main.rs', '2024']);

  // the nearest workspace root decides, even when its edition is unreadable
  mk('outer/Cargo.toml', '[workspace]\nmembers=["inner/m"]\n[workspace.package]\nedition = "2024"\n');
  mk('outer/inner/Cargo.toml', '[workspace]\nmembers=["m"]\npackage.edition = "2018"\n');
  mk('outer/inner/m/Cargo.toml', '[package]\nname="m"\nedition.workspace = true\n');
  mk('outer/inner/m/src/main.rs', BAD);
  git('outer');
  cases.push(['outer/inner/m/src/main.rs', '2021']);

  // unrelated manifest far above a git-less scratch file; meaningless when
  // the temp dir itself sits inside a git checkout (the repo bound applies)
  if (!underGit(base)) {
    mk('home/Cargo.toml', '[package]\nname="h"\nedition = "2024"\n');
    mk('home/a/b/c/d/t.rs', BAD);
    cases.push(['home/a/b/c/d/t.rs', '2021']);
  } else {
    console.log('skip: home case (temp dir is inside a git checkout)');
  }

  // unreadable manifest (a directory)
  fs.mkdirSync(path.join(base, 'dir/Cargo.toml'), { recursive: true });
  mk('dir/src/main.rs', BAD);
  git('dir');
  cases.push(['dir/src/main.rs', '2021']);

  for (const [rel, expect] of cases) {
    const file = path.join(base, rel).replace(/\\/g, '/');
    const r = spawnSync(process.execPath, [HOOK], { input: JSON.stringify({ tool_input: { file_path: file } }) });
    const out = r.stderr ? r.stderr.toString() : String(r.error);
    const m = out.match(/--edition (\d{4})/);
    const got = m ? m[1] : `none (exit ${r.status})`;
    const ok = got === expect && r.status === 2;
    if (!ok) failed++;
    console.log(`${ok ? 'ok  ' : 'FAIL'} ${rel.padEnd(26)} expect ${expect} got ${got}`);
  }
} finally {
  fs.rmSync(base, { recursive: true, force: true });
}
console.log(failed ? `${failed} failed` : 'all ok');
process.exit(failed ? 1 : 0);
