#!/usr/bin/env python3
"""run-bench.py — run the Pixel Art Bench Lite loop over grid-JSON solutions.

The agent (or a model) produces one grid-JSON file per benchmark prompt, named
by its id (mario.json, rainbow.json, sun.json, saturn.json, maze.json,
mona_lisa.json, hope.json) inside a solutions directory. This runner then, for
each prompt:

    1. validates + scores the grid-JSON   (score-grid.py)
    2. renders it to a PNG                 (render-grid.lua, via Aseprite)
    3. records quality + degenerate flags

and prints a per-prompt table plus an aggregate score.

Usage:
    python3 run-bench.py SOLUTIONS_DIR [--out OUT_DIR] [--scale N] [--bg IDX]

Env:
    ASEPRITE   path to the Aseprite binary (required for rendering; if unset or
               not found, rendering is skipped and only scoring runs)

Exit code 0 if every present solution has a valid schema, 1 otherwise.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCORE = os.path.join(HERE, "score-grid.py")
RENDER = os.path.join(HERE, "render-grid.lua")
PROMPTS_FILE = os.path.join(HERE, "bench-prompts.json")


def load_prompt_ids():
    data = json.load(open(PROMPTS_FILE))
    return [p["id"] for p in data["prompts"]]


def find_aseprite():
    env = os.environ.get("ASEPRITE")
    if env and os.path.exists(env) and os.access(env, os.X_OK):
        return env
    for p in (
        "/Applications/Aseprite.app/Contents/MacOS/aseprite",
        os.path.expanduser("~/Applications/Aseprite.app/Contents/MacOS/aseprite"),
    ):
        if os.path.exists(p) and os.access(p, os.X_OK):
            return p
    return shutil.which("aseprite")


def score_one(path, bg):
    cmd = [sys.executable, SCORE, path]
    if bg is not None:
        cmd += ["--bg", str(bg)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    quality = None
    degen = "n/a"
    schema_ok = "SCHEMA: OK" in r.stdout
    for line in r.stdout.splitlines():
        if line.startswith("QUALITY"):
            try:
                quality = float(line.split("=")[1].split()[0])
            except Exception:  # noqa: BLE001
                pass
        if line.startswith("DEGENERATE:"):
            degen = line.split(":", 1)[1].strip()
    return schema_ok, quality, degen, r.stdout


def render_one(aseprite, src, out_png, scale, bg):
    env = dict(os.environ)
    env["GRID_JSON"] = src
    env["GRID_OUT"] = out_png
    env["GRID_SCALE"] = str(scale)
    env["GRID_BG"] = "none" if bg is None else str(bg)
    env["GRID_PREVIEW"] = "0"
    r = subprocess.run(
        [aseprite, "-b", "--script", RENDER],
        capture_output=True, text=True, env=env,
    )
    return r.returncode == 0 and "OK wrote" in r.stdout, r.stdout + r.stderr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("solutions_dir")
    ap.add_argument("--out", default=None, help="output dir for rendered PNGs")
    ap.add_argument("--scale", type=int, default=16)
    ap.add_argument("--bg", default="0", help="background index or 'none'")
    args = ap.parse_args()

    bg = None if args.bg == "none" else int(args.bg)
    ids = load_prompt_ids()
    aseprite = find_aseprite()
    out_dir = args.out or os.path.join(args.solutions_dir, "rendered")
    if aseprite:
        os.makedirs(out_dir, exist_ok=True)

    print(f"Pixel Art Bench Lite — {len(ids)} prompts")
    print(f"solutions: {args.solutions_dir}")
    print(f"aseprite : {aseprite or 'NOT FOUND (scoring only)'}")
    print("-" * 64)
    print(f"{'id':<12} {'quality':>8}  {'rendered':>8}  flags")
    print("-" * 64)

    qualities = []
    all_valid = True
    present = 0
    for pid in ids:
        src = os.path.join(args.solutions_dir, f"{pid}.json")
        if not os.path.exists(src):
            print(f"{pid:<12} {'MISSING':>8}")
            continue
        present += 1
        schema_ok, quality, degen, _ = score_one(src, bg)
        if not schema_ok:
            all_valid = False
            print(f"{pid:<12} {'INVALID':>8}  {'-':>8}  schema error")
            continue
        rendered = "-"
        if aseprite:
            ok, log = render_one(aseprite, src, os.path.join(out_dir, f"{pid}.png"),
                                 args.scale, bg)
            rendered = "yes" if ok else "FAIL"
        qualities.append(quality if quality is not None else 0.0)
        flag = "" if degen == "no" else degen
        print(f"{pid:<12} {quality:>8.3f}  {rendered:>8}  {flag}")

    print("-" * 64)
    if qualities:
        agg = sum(qualities) / len(qualities)
        print(f"{'AGGREGATE':<12} {agg:>8.3f}  (mean quality over {len(qualities)} solved / {len(ids)} prompts)")
    else:
        print("No scorable solutions found.")
    if aseprite and qualities:
        print(f"Rendered PNGs in: {out_dir}")
    return 0 if all_valid else 1


if __name__ == "__main__":
    sys.exit(main())
