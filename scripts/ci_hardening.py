#!/usr/bin/env python3
"""One-off CI hardening across the plugin fleet.

Rollout tool for docs/ROADMAP/LONG_RUN/IDEAS/sofortmassnahmen.md (measures
1/2/3/5 of testing.md D.9.0). Lives in scripts/ because it iterates every
*.nvim checkout under E:/repos (TOOL-PLACEMENT case 5); delete it once the
rollout is done -- the commits that used it are the record.

    python scripts/ci_hardening.py --dry-run E:/repos/*.nvim
    python scripts/ci_hardening.py --apply   E:/repos/lib.nvim [...]

Per repo:
  * .github/workflows/*.yml   timeout-minutes per job; ref: pins on dependency
                              checkouts; `-n -i NONE` on nvim invocations;
                              (ci.yml only) failure-log artifact for test jobs
  * scripts/test.sh, scripts/ci.sh   `-n -i NONE` on nvim invocations
  * TESTS|scripts/minimal_init.lua   swapfile/shada off for child processes

Line based on purpose: PyYAML would drop every comment in these files.
"""

from __future__ import annotations

import difflib
import glob
import os
import re
import sys

PIN_BRANCH = {
    "StefanBartl/lib.nvim": "ci-verified",
    "StefanBartl/runtime-analysis.nvim": "ci-verified",
    "StefanBartl/hover.nvim": "ci-verified",
}
# Third-party: current HEAD on 2026-09-20 (git ls-remote), bumped deliberately.
PIN_SHA = {
    "nvim-lua/plenary.nvim": "74b06c6c75e4eeb3108ec01852001636d85a932b",
    "MunifTanjim/nui.nvim": "10fc361835c856ba4233ef5ea135b919bf3dce97",
    "nvim-neo-tree/neo-tree.nvim": "162f9b953a692b559afe43e38d60afee81e8e79b",
    "nvim-telescope/telescope.nvim": "40aedd8a68c78a656a10a8d62d80c54af59420fb",
    "nvim-tree/nvim-tree.lua": "8d814495983e8db87d02d2f1da293f25b2fd1bdc",
}
HEAVY_RE = re.compile(r"cargo|wasm-pack|npm ci|npm install|tree-sitter build|goreleaser|apt-get")
TEST_STEP_RE = re.compile(r"(nvim\s+-|scripts/test\.sh|scripts/ci\.sh\s+(tests|standalone)|TESTS/)")
NVIM_RE = re.compile(r"(?<![\w./-])nvim(?=\s+-)")
LOG_LINE = 'exec > >(tee -a "$RUNNER_TEMP/test-output.log") 2>&1'
MINIMAL_INIT_SNIPPET = """
-- Swap and shada stay off for the whole suite, including plenary's child
-- processes that reuse this file: stale swap files fail suites with E326.
vim.o.swapfile = false
vim.o.shadafile = "NONE"
"""


def add_flags(line: str) -> str:
    """Insert `-n` (and `-i NONE` unless --clean) after every nvim invocation."""
    if "--version" in line:
        return line
    out = []
    pos = 0
    for m in NVIM_RE.finditer(line):
        rest = line[m.end():]
        extra = []
        if not re.search(r"(^|\s)-n(\s|$)", rest):
            extra.append("-n")
        if "--clean" not in rest and not re.search(r"-i\s+NONE", rest):
            extra.append("-i NONE")
        out.append(line[pos:m.end()])
        if extra:
            out.append(" " + " ".join(extra))
        pos = m.end()
    out.append(line[pos:])
    return "".join(out)


def indent_of(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def job_ranges(lines: list[str]) -> list[tuple[str, int, int]]:
    jobs = []
    in_jobs = False
    for i, l in enumerate(lines):
        if l.rstrip() == "jobs:":
            in_jobs = True
            continue
        if not in_jobs:
            continue
        if l.strip() and indent_of(l) == 0:
            break
        m = re.match(r"^  ([A-Za-z0-9_-]+):\s*(#.*)?$", l)
        if m:
            if jobs:
                jobs[-1] = (jobs[-1][0], jobs[-1][1], i)
            jobs.append((m.group(1), i, len(lines)))
    # trim trailing blank/comment-only lines from each job end
    trimmed = []
    for name, s, e in jobs:
        while e > s + 1 and (not lines[e - 1].strip() or lines[e - 1].lstrip().startswith("#")):
            e -= 1
        trimmed.append((name, s, e))
    return trimmed


def step_ranges(lines: list[str], s: int, e: int) -> list[tuple[int, int]]:
    steps = []
    for i in range(s, e):
        if re.match(r"^      - ", lines[i]):
            if steps:
                steps[-1] = (steps[-1][0], i)
            steps.append((i, e))
    return steps


def process_workflow(lines: list[str], allow_artifact: bool) -> tuple[list[str], list[str]]:
    notes = []
    jobs = job_ranges(lines)
    for name, s, e in reversed(jobs):
        job = lines[s:e]
        text = "".join(job)
        has_matrix_os = re.search(r"^\s+os:\s*\[", text, re.M) is not None
        windows = "windows" in text
        shell_bash = re.search(r"^\s+shell:\s*bash\s*$", text, re.M) is not None
        # (index, priority, new lines): inserted before index; at equal index the
        # higher priority is applied first and therefore ends up *after* the
        # lower one (needed when a wrapped run step is the job's last line).
        insertions: list[tuple[int, int, list[str]]] = []
        replacements: dict[int, str] = {}

        # --- nvim flags + artifact wrap per step
        wrapped_any = False
        for ss, se in step_ranges(lines, s, e):
            for i in range(ss, se):
                m = re.match(r"^(\s*)(- )?run:\s*(.*)$", lines[i])
                if not m:
                    continue
                key_col = len(m.group(1)) + (2 if m.group(2) else 0)
                value = m.group(3).strip()
                is_block = value in ("|", ">", "|-", ">-")
                block = []
                if is_block:
                    j = i + 1
                    while j < se and (not lines[j].strip() or indent_of(lines[j]) > key_col):
                        block.append(j)
                        j += 1
                    while block and not lines[block[-1]].strip():
                        block.pop()
                    run_text = "".join(lines[j2] for j2 in block)
                else:
                    run_text = value
                # flags
                if is_block:
                    for j2 in block:
                        new = add_flags(lines[j2])
                        if new != lines[j2]:
                            replacements[j2] = new
                else:
                    new = add_flags(lines[i])
                    if new != lines[i]:
                        replacements[i] = new
                        value = re.match(r"^(\s*)(- )?run:\s*(.*)$", new).group(3).strip()
                # artifact wrap
                if allow_artifact and TEST_STEP_RE.search(run_text) and "--version" not in run_text:
                    if windows and not shell_bash:
                        notes.append(f"job {name}: windows without shell:bash, artifact wrap skipped")
                        continue
                    if LOG_LINE in text:
                        continue
                    if is_block:
                        content_col = indent_of(lines[block[0]]) if block else key_col + 2
                        insertions.append((i + 1, 0, [" " * content_col + LOG_LINE + "\n"]))
                    else:
                        head = lines[i][: lines[i].index("run:")] + "run: |\n"
                        replacements[i] = head
                        content_col = key_col + 2
                        insertions.append((i + 1, 0, [" " * content_col + LOG_LINE + "\n",
                                                      " " * content_col + value + "\n"]))
                    wrapped_any = True
        if wrapped_any:
            art_name = f"test-output-{name}" + ("-${{ matrix.os }}" if has_matrix_os else "")
            insertions.append((e, 1, [
                "      - uses: actions/upload-artifact@v4\n",
                "        if: failure()\n",
                "        with:\n",
                f"          name: {art_name}\n",
                "          path: ${{ runner.temp }}/test-output.log\n",
                "          if-no-files-found: ignore\n",
            ]))

        # --- dependency pins
        for ss, se in step_ranges(lines, s, e):
            step_text = "".join(lines[ss:se])
            if "actions/checkout@" not in step_text or "repository:" not in step_text:
                continue
            if re.search(r"^\s+ref:", step_text, re.M):
                continue
            repo_line = next(i for i in range(ss, se) if re.match(r"^\s+repository:", lines[i]))
            repo = lines[repo_line].split("repository:")[1].strip()
            col = indent_of(lines[repo_line])
            anchor = repo_line
            for i in range(ss, se):
                if re.match(r"^\s+path:", lines[i]):
                    anchor = i
            if repo in PIN_BRANCH:
                insertions.append((anchor + 1, 0, [" " * col + f"ref: {PIN_BRANCH[repo]}\n"]))
            elif repo in PIN_SHA:
                insertions.append((anchor + 1, 0, [
                    " " * col + "# Pinned to the 2026-09-20 HEAD; bump deliberately, not by drifting.\n",
                    " " * col + f"ref: {PIN_SHA[repo]}\n",
                ]))
            else:
                notes.append(f"job {name}: {repo} left unpinned (no ci-verified branch yet)")

        # --- timeout
        if "timeout-minutes" not in text:
            for i in range(s, e):
                if re.match(r"^    runs-on:", lines[i]):
                    minutes = 30 if HEAVY_RE.search(text) else 15
                    insertions.append((i + 1, 0, [f"    timeout-minutes: {minutes}\n"]))
                    break

        # apply to this job (indices are absolute; go bottom-up)
        for i, new in replacements.items():
            lines[i] = new
        for idx, _prio, new_lines in sorted(insertions, key=lambda t: (t[0], t[1]), reverse=True):
            lines[idx:idx] = new_lines
    return lines, notes


def process_shell(lines: list[str]) -> list[str]:
    out = []
    for l in lines:
        if l.lstrip().startswith("#"):
            out.append(l)
        else:
            out.append(add_flags(l))
    return out


def process_minimal_init(lines: list[str]) -> list[str]:
    if any("swapfile" in l for l in lines):
        return lines
    text = "".join(lines)
    if not text.endswith("\n"):
        text += "\n"
    return (text + MINIMAL_INIT_SNIPPET).splitlines(keepends=True)


def run(repo: str, apply: bool) -> None:
    changed = []
    targets = []
    for wf in sorted(glob.glob(os.path.join(repo, ".github", "workflows", "*.yml"))):
        targets.append((wf, "workflow"))
    for sh in ("scripts/test.sh", "scripts/ci.sh"):
        p = os.path.join(repo, sh)
        if os.path.exists(p):
            targets.append((p, "shell"))
    for mi in ("TESTS/minimal_init.lua", "scripts/minimal_init.lua"):
        p = os.path.join(repo, mi)
        if os.path.exists(p):
            targets.append((p, "minit"))
    for path, kind in targets:
        with open(path, encoding="utf-8", newline="") as f:
            original = f.read()
        nl = "\r\n" if "\r\n" in original else "\n"
        lines = original.replace("\r\n", "\n").splitlines(keepends=True)
        notes: list[str] = []
        if kind == "workflow":
            new, notes = process_workflow(list(lines), allow_artifact=os.path.basename(path) == "ci.yml")
        elif kind == "shell":
            new = process_shell(lines)
        else:
            new = process_minimal_init(lines)
        for n in notes:
            print(f"  NOTE {os.path.relpath(path, repo)}: {n}")
        if new != lines:
            changed.append(path)
            if apply:
                with open(path, "w", encoding="utf-8", newline="") as f:
                    f.write("".join(new).replace("\n", nl))
            else:
                sys.stdout.writelines(difflib.unified_diff(lines, new, path, path))
    print(f"== {os.path.basename(repo)}: {len(changed)} file(s) {'written' if apply else 'would change'}")


if __name__ == "__main__":
    mode = sys.argv[1]
    for r in sys.argv[2:]:
        run(r, apply=(mode == "--apply"))
