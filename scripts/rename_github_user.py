"""Rename the GitHub owner in every repo under $REPOS_DIR and in the nvim config.

Dry run by default: prints what would change, per rule and per repo. With --apply it rewrites
the files in place (bytes in, bytes out: line endings and BOMs stay) and, with --remotes, points
each local clone's `origin` at the new owner. It never commits; commit per repo afterwards.

Only owner-shaped strings are rewritten (URLs, `owner/repo` slugs, `uses:`, `owner:`). What is NOT
touched on purpose, and listed in the report instead:
  - Windows profile paths (`C:/Users/<old>/...`): the account folder is not the GitHub name
  - the Tauri bundle identifier `dev.<old>.*` (changing it moves the app's data folder)
  - the personal domain, author/copyright names in prose
  - history: tasks-vault `_Telemetry/`, `Backlog/`, `rohdaten/`
  - generated maps (`module_map.json`, `.deps/`): regenerate them with docmap instead

Usage: python rename_github_user.py [--old StefanBartl] [--new WKDSteve] [--apply] [--remotes]
"""
import argparse, collections, os, re, subprocess, sys

SKIP_DIRS = {"node_modules", "target", ".git", "dist", "build", ".svelte-kit", "__pycache__",
             ".venv", "ARCHIV_NICHT_BEARBEITEN", "RessourcenBackup", "_Telemetry", "Backlog",
             "rohdaten", ".deps", ".claude"}
SKIP_FILES = {"module_map.json", "lazy-lock.json"}
MAX_SIZE = 3_000_000


def build_rules(old, new):
    o = re.escape(old)
    return [
        # (name, compiled pattern, replacement function)
        ("github.com url/ssh", re.compile(rf"(github\.com[/:]){o}(?=/)", re.I), lambda m: m.group(1) + new),
        ("raw.githubusercontent", re.compile(rf"(raw\.githubusercontent\.com/){o}(?=/)", re.I), lambda m: m.group(1) + new),
        ("api.github.com", re.compile(rf"(api\.github\.com/(?:repos|users)/){o}(?=[/\"'\s]|$)", re.I), lambda m: m.group(1) + new),
        ("github pages host", re.compile(rf"{o}(\.github\.io)", re.I), lambda m: new.lower() + m.group(1)),
        ("pnpm github: spec", re.compile(rf"(github:){o}(?=/)", re.I), lambda m: m.group(1) + new),
        ("workflow uses/repository", re.compile(rf"((?:uses|repository):\s*[\"']?){o}(?=/)", re.I), lambda m: m.group(1) + new),
        ("goreleaser owner", re.compile(rf"(\bowner:\s*[\"']?){o}\b", re.I), lambda m: m.group(1) + new),
        ("owner key (json, lua)", re.compile(rf"((?:\"owner\"\s*:|\bowner\s*=|DEFAULT_OWNER\s*=)\s*\"){o}(?=\")", re.I), lambda m: m.group(1) + new),
        # slug `owner/repo` in quotes, backticks, parens, after a space or at a path start;
        # `Users/<old>/` is excluded by the lookbehind (a profile folder, not the account)
        ("owner/repo slug", re.compile(rf"(?<![\w.\\-])(?<!Users/)(?<!Users\\){o}(?=/[\w.-])", re.I), lambda m: new),
    ]


def walk(roots):
    for root in roots:
        for d, dirs, files in os.walk(root):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
            for f in files:
                if f in SKIP_FILES:
                    continue
                fp = os.path.join(d, f)
                try:
                    if os.path.getsize(fp) > MAX_SIZE:
                        continue
                except OSError:
                    continue
                yield root, fp


def repo_of(root, fp, nvim_root):
    if os.path.normcase(root) == os.path.normcase(nvim_root):
        return "NVIM-CONFIG"
    return os.path.relpath(fp, root).split(os.sep)[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", default="StefanBartl")
    ap.add_argument("--new", default="WKDSteve")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--remotes", action="store_true")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    repos_dir = os.environ.get("REPOS_DIR", r"E:\repos")
    nvim_root = os.environ.get("NVIM_CONFIG_DIR", r"C:\Users\bartl\AppData\Local\nvim")
    rules = build_rules(a.old, a.new)
    rest = re.compile(re.escape(a.old), re.I)
    stale = re.compile(rf"Users[/\\]{re.escape(a.old)}", re.I)
    ident = re.compile(rf"\.{re.escape(a.old)}\.", re.I)

    changed = collections.Counter()
    by_rule = collections.Counter()
    leftovers = collections.Counter()
    leftover_kinds = collections.Counter()
    sample = {}

    for root, fp in walk([repos_dir, nvim_root]):
        try:
            raw = open(fp, "rb").read()
        except OSError:
            continue
        if b"\0" in raw[:4096] or not rest.search(raw.decode("latin-1")):
            continue
        try:
            txt = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        repo = repo_of(root, fp, nvim_root)
        out = txt
        for name, pat, fn in rules:
            out, n = pat.subn(fn, out)
            if n:
                by_rule[name] += n
                changed[repo] += n
        for m in rest.finditer(out):
            line_start = out.rfind("\n", 0, m.start()) + 1
            line = out[line_start: out.find("\n", m.end()) if out.find("\n", m.end()) != -1 else len(out)]
            kind = ("windows profile path" if stale.search(line) else
                    "bundle identifier" if ident.search(line) else
                    "slug built or matched in code (fix by hand)" if rest.search(line) and re.search(rf"{re.escape(a.old)}/", line, re.I) else
                    "name/prose")
            leftover_kinds[kind] += 1
            leftovers[repo] += 1
            sample.setdefault(kind, []).append(f"{fp}: {line.strip()[:110]}")
        if a.apply and out != txt:
            with open(fp, "wb") as fh:
                fh.write(out.encode("utf-8"))

    print(f"{'APPLIED' if a.apply else 'DRY RUN'}: {a.old} -> {a.new}")
    print("\nrewritten by rule:")
    for k, v in by_rule.most_common():
        print(f"  {v:6d} {k}")
    print(f"\nrewritten per repo ({sum(changed.values())} total):")
    for k, v in changed.most_common():
        print(f"  {v:6d} {k}")
    print("\nleft untouched (review by hand):")
    for k, v in leftover_kinds.most_common():
        print(f"  {v:6d} {k}")
        for s in sample[k][:4]:
            print(f"           e.g. {s}")

    if a.remotes:
        for name in sorted(os.listdir(repos_dir)) + ["<nvim>"]:
            path = nvim_root if name == "<nvim>" else os.path.join(repos_dir, name)
            if not os.path.isdir(os.path.join(path, ".git")) and not os.path.isfile(os.path.join(path, ".git")):
                continue
            try:
                url = subprocess.run(["git", "-C", path, "remote", "get-url", "origin"],
                                     capture_output=True, text=True).stdout.strip()
            except OSError:
                continue
            if not re.search(rf"github\.com[/:]{re.escape(a.old)}/", url, re.I):
                continue
            new_url = re.sub(rf"(github\.com[/:]){re.escape(a.old)}/", rf"\g<1>{a.new}/", url, flags=re.I)
            print(f"remote {name}: {url} -> {new_url}" + ("" if a.apply else "  (dry)"))
            if a.apply:
                subprocess.run(["git", "-C", path, "remote", "set-url", "origin", new_url], check=False)


if __name__ == "__main__":
    sys.exit(main())
