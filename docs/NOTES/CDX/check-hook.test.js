// End-to-end test for check-hook.js: Rust edition detection. Needs rustfmt on PATH.
// Run: node check-hook.test.js
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const HOOK = path.join(__dirname, 'check-hook.js');
const base = fs.mkdtempSync(path.join(require('os').tmpdir(), 'check-hook-test-'));

const BAD = 'fn  main(){}\n';
function mk(rel, text) {
  const p = path.join(base, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, text);
}
const git = (rel) => fs.mkdirSync(path.join(base, rel, '.git'), { recursive: true });

const cases = [];
function crate(name, manifest, expect, opts = {}) {
  mk(`${name}/Cargo.toml`, manifest);
  mk(`${name}/src/main.rs`, BAD);
  if (!opts.noGit) git(name);
  cases.push([`${name}/src/main.rs`, expect]);
}

crate('pkg2018', '[package]\nname="a"\nedition = "2018"\n', '2018');
crate('noedition', '[package]\nname="a"\n', '2015');
crate('comment3q', '[package]\nname="a"\n# use """ for docs\nedition = "2024"\n', '2024');
crate('sq3inline', "[package]\nname=\"a\"\ndescription = 'say \"\"\" hi'\nedition = \"2024\"\n", '2024');
crate('mixed', '[package]\nname="a"\ndescription = """\nit\'\'\'s\n"""\nedition = "2024"\n', '2024');
crate('arrays', '[package]\nname="a"\nkeywords = [\n  ["a","b"],\n]\nedition = "2024"\n', '2024');
crate('quotedkey', '[package]\nname="a"\n"edition" = "2024"\n', '2021');
crate('multiline', '[package]\nname="g"\ndescription = """\nedition = "2015"\n"""\nedition = "2024"\n', '2024');
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

// unrelated manifest far above a git-less scratch file
mk('home/Cargo.toml', '[package]\nname="h"\nedition = "2024"\n');
mk('home/a/b/c/d/t.rs', BAD);
cases.push(['home/a/b/c/d/t.rs', '2021']);

// unreadable manifest (a directory)
fs.mkdirSync(path.join(base, 'dir/Cargo.toml'), { recursive: true });
mk('dir/src/main.rs', BAD);
git('dir');
cases.push(['dir/src/main.rs', '2021']);

let failed = 0;
for (const [rel, expect] of cases) {
  const file = path.join(base, rel).replace(/\\/g, '/');
  const r = spawnSync('node', [HOOK], { input: JSON.stringify({ tool_input: { file_path: file } }) });
  const out = r.stderr.toString();
  const m = out.match(/--edition (\d{4})/);
  const got = m ? m[1] : `none (exit ${r.status})`;
  const ok = got === expect && r.status === 2;
  if (!ok) failed++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${rel.padEnd(22)} expect ${expect} got ${got}`);
}
fs.rmSync(base, { recursive: true, force: true });
console.log(failed ? `${failed} failed` : 'all ok');
process.exit(failed ? 1 : 0);
