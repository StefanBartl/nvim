#!/usr/bin/env node
// Copies the Claude Code project template for a stack into a repo.
//
// Usage: node new-project-claude.js <stack> [targetDir]
//   stack: see templates/ (nvim-plugin, rust, cpp, tauri, web)
//   targetDir defaults to the current directory.
//
// Never overwrites: an existing file is kept and the template is written next
// to it as '<name>.new' for a manual merge.

const fs = require('fs');
const path = require('path');

const templatesDir = path.join(__dirname, 'templates');
const [, , stack, targetArg] = process.argv;
const stacks = fs.readdirSync(templatesDir);

if (!stack || !stacks.includes(stack)) {
  console.error(`usage: node new-project-claude.js <${stacks.join('|')}> [targetDir]`);
  process.exit(1);
}

const target = path.resolve(targetArg ?? process.cwd());
if (!fs.existsSync(target)) {
  console.error(`Zielordner existiert nicht: ${target}`);
  process.exit(1);
}

function copyTree(src, dst) {
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name);
    let to = path.join(dst, entry.name);
    if (entry.isDirectory()) {
      fs.mkdirSync(to, { recursive: true });
      copyTree(from, to);
      continue;
    }
    if (fs.existsSync(to)) {
      to = `${to}.new`;
      console.log(`  vorhanden, Vorlage stattdessen als: ${to}`);
    } else {
      console.log(`  angelegt: ${to}`);
    }
    fs.copyFileSync(from, to);
  }
}

copyTree(path.join(templatesDir, stack), target);
console.log('Fertig. CLAUDE.md und .claude/settings.json im Repo anpassen und mit ins Repo committen.');
