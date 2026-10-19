#!/usr/bin/env python3
"""score-grid.py — rough Pixel Art Bench Lite quality score for a grid-JSON file.

Mirrors the benchmark's signal:
  - JSON validity (schema: NxN ints 0..9 + palette)
  - Quality = 0.7 * diversity + 0.3 * density
      diversity = (# distinct non-background indices used) / (len(palette) - 1)
      density   = (# non-background cells) / (total cells)
Background is index 0 by convention.

Usage: python3 score-grid.py path/to/grid.json
"""
import json
import sys


def main(path: str) -> int:
    try:
        data = json.load(open(path))
    except Exception as e:  # noqa: BLE001
        print(f"INVALID JSON: {e}")
        return 1

    grid = data.get("grid")
    palette = data.get("palette", [])
    if not isinstance(grid, list) or not grid or not isinstance(grid[0], list):
        print("INVALID: 'grid' must be a non-empty list of lists")
        return 1

    n_rows = len(grid)
    row_lens = {len(r) for r in grid}
    square = len(row_lens) == 1 and row_lens.pop() == n_rows
    all_ints = all(
        isinstance(c, int) and 0 <= c <= 9 for row in grid for c in row
    )
    max_idx = max((c for row in grid for c in row), default=0)
    palette_ok = len(palette) > max_idx

    print(f"grid: {n_rows} rows, square={square}, ints_0_9={all_ints}")
    print(f"palette: {len(palette)} entries, max_index_used={max_idx}, covered={palette_ok}")

    if not (square and all_ints and palette_ok):
        print("SCHEMA: FAIL")
        return 1
    print("SCHEMA: OK")

    total = n_rows * n_rows
    non_bg_cells = sum(1 for row in grid for c in row if c != 0)
    distinct_non_bg = len({c for row in grid for c in row if c != 0})

    density = non_bg_cells / total
    denom = max(1, len(palette) - 1)
    diversity = distinct_non_bg / denom
    quality = 0.7 * diversity + 0.3 * density

    print(f"density   = {density:.3f}  ({non_bg_cells}/{total} cells)")
    print(f"diversity = {diversity:.3f} ({distinct_non_bg}/{denom} colors)")
    print(f"QUALITY   = {quality:.3f}  (0.7*diversity + 0.3*density)")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
