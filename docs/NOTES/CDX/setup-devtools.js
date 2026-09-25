#!/usr/bin/env node
// Installs missing dev toolchains per profile (winget / apt / brew).
// Idempotent: only missing tools are installed; asks before installing.
//
// Usage: node setup-devtools.js [--profile nvim,rust,...] [--yes] [--dry-run]
//   Profiles: core (always), nvim, cpp, rust, web, tauri (= rust + web + webview2)
//   Without --profile the profiles saved in ~/.claude/devtools.profile are used.

const { execFileSync, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const readline = require('readline');

const PLATFORM = process.platform;
const profileFile = path.join(os.homedir(), '.claude', 'devtools.profile');
const table = JSON.parse(fs.readFileSync(path.join(__dirname, 'tools.json'), 'utf8'));

const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const opt = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};

function readSavedProfiles() {
  try {
    return fs.readFileSync(profileFile, 'utf8').split(/[\s,]+/).filter(Boolean);
  } catch {
    return [];
  }
}

const requested = (opt('--profile') ? opt('--profile').split(',') : readSavedProfiles()).map((p) => p.trim());
if (!requested.length) {
  console.error('Kein Profil angegeben. Beispiel: node setup-devtools.js --profile nvim,rust,web');
  console.error('Profile: core (immer), nvim, cpp, rust, web, tauri');
  process.exit(1);
}

const profiles = new Set(['core']);
for (const p of requested) {
  profiles.add(p);
  for (const implied of table.implies[p] ?? []) profiles.add(implied);
}

function onPath(cmd) {
  const probe = PLATFORM === 'win32' ? 'where' : 'which';
  return spawnSync(probe, [cmd], { stdio: 'ignore' }).status === 0;
}

function hasMsvc() {
  const base = process.env['ProgramFiles(x86)'];
  if (!base) return false;
  const vswhere = path.join(base, 'Microsoft Visual Studio', 'Installer', 'vswhere.exe');
  if (!fs.existsSync(vswhere)) return false;
  const out = spawnSync(
    vswhere,
    ['-latest', '-products', '*', '-requires', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', '-property', 'installationPath'],
    { encoding: 'utf8' }
  );
  return out.status === 0 && out.stdout.trim().length > 0;
}

function hasWebView2() {
  const base = process.env['ProgramFiles(x86)'];
  return !!base && fs.existsSync(path.join(base, 'Microsoft', 'EdgeWebView', 'Application'));
}

function isInstalled(tool) {
  if (tool.check === 'vswhere') return hasMsvc();
  if (tool.check === 'webview2') return hasWebView2();
  // Debian/Ubuntu ships fd as 'fdfind'.
  return onPath(tool.check) || (tool.check === 'fd' && onPath('fdfind'));
}

function installCommand(tool) {
  if (PLATFORM === 'win32' && tool.winget) {
    const cmd = ['winget', 'install', '--id', tool.winget, '-e', '--accept-source-agreements', '--accept-package-agreements'];
    if (tool.wingetOverride) cmd.push('--override', tool.wingetOverride);
    return cmd;
  }
  if (PLATFORM === 'linux' && tool.apt) return ['sudo', 'apt-get', 'install', '-y', ...tool.apt.split(' ')];
  if (PLATFORM === 'darwin' && tool.brew) return ['brew', 'install', tool.brew];
  return null;
}

function ask(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) =>
    rl.question(question, (a) => {
      rl.close();
      resolve(/^(j|y)/i.test(a.trim()));
    })
  );
}

(async () => {
  console.log(`Profile: ${[...profiles].join(', ')}  (Plattform: ${PLATFORM})\n`);

  const relevant = table.tools.filter(
    (t) => t.profiles.some((p) => profiles.has(p)) && (!t.osOnly || t.osOnly === PLATFORM)
  );

  const missing = new Map();
  for (const tool of relevant) {
    if (isInstalled(tool)) {
      console.log(`  ok        ${tool.name}`);
    } else {
      console.log(`  fehlt     ${tool.name}`);
      missing.set(tool.name, tool);
    }
  }

  // Fallback tools are only wanted if their primary is missing; drop the rest.
  const wanted = [...missing.values()].filter((t) => !t.fallbackFor || missing.has(t.fallbackFor));
  const todo = [];
  const manual = [];
  for (const tool of wanted) {
    const cmd = installCommand(tool);
    if (cmd) todo.push({ tool, cmd });
    else manual.push(tool);
  }

  if (!todo.length && !manual.length) {
    console.log('\nNichts zu tun.');
  }

  if (todo.length) {
    console.log('\nWird installiert:');
    for (const { cmd } of todo) console.log(`  ${cmd.join(' ')}`);
    if (flag('--dry-run')) {
      console.log('\n(--dry-run: nichts ausgefuehrt)');
    } else if (flag('--yes') || (await ask('\nJetzt installieren? [j/N] '))) {
      for (const { tool, cmd } of todo) {
        console.log(`\n== ${tool.name} ==`);
        const res = spawnSync(cmd[0], cmd.slice(1), { stdio: 'inherit' });
        if (res.status !== 0) {
          console.error(`  Fehler bei ${tool.name} (Exit ${res.status}).`);
          if (tool.name === 'msvc') {
            console.error('  Fallback: clang wird beim naechsten Lauf angeboten (Profil cpp).');
          }
        }
      }
      console.log('\nHinweis: neu installierte Tools stehen erst in neuen Shells im PATH.');
    }
  }

  if (manual.length) {
    console.log('\nManuell zu installieren (kein Paket fuer diese Plattform):');
    for (const t of manual) console.log(`  ${t.name}: ${t.manual ?? 'siehe Herstellerseite'}`);
  }

  if (!flag('--dry-run') && opt('--profile')) {
    fs.mkdirSync(path.dirname(profileFile), { recursive: true });
    fs.writeFileSync(profileFile, `${requested.join(',')}\n`, 'utf8');
    console.log(`\nProfil gemerkt in ${profileFile}`);
  }
})();
