"""Build one lua-language-server config per workspace, as close to the editor
as the CLI gets.

The editor path is: lsp.nvim hands lua_ls a settings table (its library part
comes from lsp/servers/lua_ls/build_library.lua), and a .luarc.json in the
workspace root then overrides every key it names -- workspace.library included,
and wholesale, not merged. That order is what this reproduces: the dumped
injection first, the repo's own .luarc.json on top.

Usage:
    python mkcfg.py --index <index.tsv> --library <cache dir> --out <cfg dir>
"""

import argparse
import json
import os
import re
import sys

LINE_COMMENT = re.compile(r"^\s*//.*$", re.M)
TRAILING_COMMA = re.compile(r",(\s*[}\]])")


def load_jsonc(path):
    """Read a .luarc.json. They are JSONC in practice: comments, trailing commas."""
    try:
        with open(path, encoding="utf-8-sig") as fh:
            text = fh.read()
        text = LINE_COMMENT.sub("", text)
        text = TRAILING_COMMA.sub(r"\1", text)
        return json.loads(text)
    except FileNotFoundError:
        return {}
    except Exception as exc:  # noqa: BLE001 - a broken luarc must be visible, not fatal
        print("PARSE-FAIL %s: %s" % (path, exc), file=sys.stderr)
        return {}


def deep(base, over):
    out = dict(base)
    for key, value in over.items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep(out[key], value)
        else:
            out[key] = value
    return out


def nest(cfg):
    """LuaLS accepts dotted keys ("runtime.version"); normalise them to nested."""
    out = {}
    for key, value in cfg.items():
        value = nest(value) if isinstance(value, dict) else value
        target, leaf = out, key
        if "." in key:
            parts = key.split(".")
            for part in parts[:-1]:
                target = target.setdefault(part, {})
            leaf = parts[-1]
        if isinstance(value, dict) and isinstance(target.get(leaf), dict):
            target[leaf] = deep(target[leaf], value)
        else:
            target[leaf] = value
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True, help="TSV: name<TAB>root per line")
    ap.add_argument("--library", required=True, help="dump_library.lua output dir")
    ap.add_argument("--out", required=True, help="where to write the configs")
    args = ap.parse_args()

    meta = load_jsonc(os.path.join(args.library, "_meta.json"))
    vimruntime = meta.get("vimruntime", "")
    ignore_dirs = meta.get("ignore_dirs") or []

    os.makedirs(args.out, exist_ok=True)
    made = 0

    with open(args.index, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            name, root = line.split("\t")

            dumped = load_jsonc(os.path.join(args.library, name + ".json"))
            injected_library = dumped.get("library")
            if injected_library is None:
                print("NO LIBRARY DUMP for %s -- run the dump first" % name, file=sys.stderr)
                return 1

            # The library and ignoreDir halves of the injection are dumped from
            # a running nvim; these are the remaining defaults lsp.nvim sets.
            # Repos overwhelmingly override those in their own .luarc.json.
            injected = {
                "runtime": {"version": "LuaJIT"},
                "workspace": {
                    "library": list(injected_library),
                    "ignoreDir": list(ignore_dirs),
                    "checkThirdParty": False,
                },
                "diagnostics": {"globals": ["vim"]},
            }
            merged = deep(injected, nest(load_jsonc(os.path.join(root, ".luarc.json"))))

            # $VIMRUNTIME is a client-side variable that lsp.nvim expands before
            # the settings reach lua_ls. The CLI does not know it, and without
            # the expansion every `vim.*` reads as undefined-global.
            library = merged.get("workspace", {}).get("library")
            if isinstance(library, list) and vimruntime:
                merged["workspace"]["library"] = [
                    entry.replace("$VIMRUNTIME", vimruntime) for entry in library
                ]

            with open(os.path.join(args.out, name + ".json"), "w", encoding="utf-8") as out:
                json.dump(merged, out, indent=2)
            made += 1

    print("%d configs -> %s" % (made, args.out))
    return 0


sys.exit(main())
