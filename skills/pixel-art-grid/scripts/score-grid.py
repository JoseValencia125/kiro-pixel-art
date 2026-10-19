#!/usr/bin/env python3
"""score-grid.py — Pixel Art Bench Lite quality score for a grid-JSON file.

Schema checked:  grid = HxW list of non-negative ints + palette covering max index.
                 (benchmark uses 0..9 / <=10 colors; larger palettes allowed)

Score (0..1):
    quality = (0.6*diversity + 0.3*density + 0.1*structure) * gate
    gate    = min(1, structure/0.6)   # noise (low structure) is suppressed
  where
    diversity = normalized Shannon entropy over non-background cell colors
                (rewards using several colors in balanced proportions, not just
                 "N distinct colors" — a single stray pixel no longer scores 1.0)
    density   = non-background cells / total cells, saturating near ~0.6 so a
                fully-filled canvas is not required
    structure = fraction of non-background cells that touch a same-color
                4-neighbour (rewards coherent shapes, punishes random noise)

Degenerate grids are flagged (and penalized) when:
    - everything is a single color (blank), or
    - non-background density is < 2%, or
    - structure < 0.5 (looks like noise), or
    - JSON/schema invalid.

Usage:
    python3 score-grid.py grid.json [--bg INDEX]     # default bg index = 0
    python3 score-grid.py grid.json --bg none        # no background (count all)
Exit code 0 if schema valid, 1 otherwise.
"""
import json
import math
import sys


def load(path):
    try:
        return json.load(open(path)), None
    except Exception as e:  # noqa: BLE001
        return None, f"INVALID JSON: {e}"


def check_schema(data):
    if not isinstance(data, dict):
        return None, None, "top-level must be an object"
    grid = data.get("grid")
    palette = data.get("palette", [])
    if not isinstance(grid, list) or not grid or not isinstance(grid[0], list):
        return None, None, "'grid' must be a non-empty list of lists"
    n_rows = len(grid)
    width = len(grid[0])
    for y, row in enumerate(grid):
        if not isinstance(row, list) or len(row) != width:
            return None, None, f"ragged grid at row {y} (expected width {width})"
        for x, c in enumerate(row):
            if not isinstance(c, int) or c < 0:
                return None, None, f"cell ({x},{y})={c!r} not a non-negative int"
    max_idx = max(c for row in grid for c in row)
    if len(palette) <= max_idx:
        return None, None, f"palette too short: max index {max_idx}, {len(palette)} entries"
    return grid, palette, None


def shannon_norm(counts):
    """Normalized Shannon entropy of a list of counts -> 0..1."""
    total = sum(counts)
    k = len(counts)
    if total == 0 or k <= 1:
        return 0.0
    h = 0.0
    for c in counts:
        if c > 0:
            p = c / total
            h -= p * math.log(p)
    return h / math.log(k)  # divide by max possible entropy (uniform over k)


def structure_score(grid, bg, width, height):
    """Shape coherence via connected components (4-connectivity, same color).

    Real art = few large regions; noise = many tiny regions. Score is high when
    the average region is large relative to the grid.
        score = 1 - (num_regions / num_non_bg_cells)
    A solid blob of N cells -> 1 region -> score ~1.
    Pure noise where every cell is its own region -> score ~0.
    """
    seen = [[False] * width for _ in range(height)]
    non_bg = 0
    regions = 0
    for sy in range(height):
        for sx in range(width):
            v = grid[sy][sx]
            if v == bg:
                continue
            non_bg += 1
            if seen[sy][sx]:
                continue
            # flood fill this region
            regions += 1
            stack = [(sx, sy)]
            seen[sy][sx] = True
            while stack:
                x, y = stack.pop()
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if (0 <= nx < width and 0 <= ny < height
                            and not seen[ny][nx] and grid[ny][nx] == v):
                        seen[ny][nx] = True
                        stack.append((nx, ny))
    if non_bg == 0:
        return 0.0
    return max(0.0, 1.0 - regions / non_bg)


def main(argv):
    path = None
    bg = 0
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--bg":
            i += 1
            bg = None if argv[i] == "none" else int(argv[i])
        elif path is None:
            path = a
        i += 1
    if not path:
        print(__doc__)
        return 2

    data, err = load(path)
    if err:
        print(err)
        print("SCHEMA: FAIL")
        return 1
    grid, palette, serr = check_schema(data)
    if serr:
        print(f"SCHEMA: FAIL — {serr}")
        return 1
    print("SCHEMA: OK")

    height = len(grid)
    width = len(grid[0])
    total = width * height

    # color counts (excluding background)
    counts = {}
    for row in grid:
        for c in row:
            if bg is not None and c == bg:
                continue
            counts[c] = counts.get(c, 0) + 1

    non_bg = sum(counts.values())
    distinct = len(counts)
    diversity = shannon_norm(list(counts.values()))
    density_raw = non_bg / total
    density = min(1.0, density_raw / 0.6)  # saturate ~60% fill
    structure = structure_score(grid, bg, width, height)

    # Base quality from diversity + density + structure, then gate by structural
    # coherence so high-entropy noise cannot outscore coherent art.
    base = 0.6 * diversity + 0.3 * density + 0.1 * structure
    coherence_gate = min(1.0, structure / 0.6)   # 1.0 once structure >= 0.6
    quality = base * coherence_gate

    # degenerate detection
    flags = []
    if distinct == 0:
        flags.append("blank (single color / all background)")
    if density_raw < 0.02:
        flags.append(f"too sparse (density {density_raw:.3f} < 0.02)")
    if structure < 0.5 and non_bg > 0:
        flags.append(f"looks like noise (structure {structure:.2f} < 0.50)")
    if distinct == 1 and density_raw > 0.9:
        flags.append("solid fill (one color everywhere)")

    print(f"size      = {width}x{height}  (bg index = {bg})")
    print(f"colors    = {distinct} distinct non-bg, {len(palette)} in palette")
    print(f"density   = {density:.3f}  (raw {density_raw:.3f}, {non_bg}/{total} cells)")
    print(f"diversity = {diversity:.3f}  (normalized color entropy)")
    print(f"structure = {structure:.3f}  (coherent shape vs noise)")
    print(f"QUALITY   = {quality:.3f}  (0.6*div + 0.3*dens + 0.1*struct)")
    if flags:
        print("DEGENERATE: " + "; ".join(flags))
    else:
        print("DEGENERATE: no")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
