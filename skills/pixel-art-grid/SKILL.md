---
name: pixel-art-grid
description: Generate pixel art as structured grid-JSON (a 24x24 grid of integers 0-9 plus a color palette) and render it to a real Aseprite sprite. Use when the user wants a sprite "from a grid", "as JSON", "structured output", mentions a NxN / 24x24 grid of numbers, a palette of indexed colors, or wants to run the Pixel Art Bench Lite prompts (Mario, rainbow, sun, Saturn, maze, Mona Lisa, hope). Also use to evaluate or improve grid pixel art for diversity and density.
---

# Pixel Art from a Grid (structured JSON)

This skill teaches the agent to produce pixel art in the **Pixel Art Bench Lite**
structured-output format and render it to a real sprite with Aseprite. It is
based on the dataset
[`AINovice2005/pixel-art-bench-lite`](https://huggingface.co/datasets/AINovice2005/pixel-art-bench-lite)
(Apache-2.0).

## The format

```json
{
  "grid": [[0,1,1, ...], [ ... ], ...],   // H rows × W columns of integer indices
  "palette": ["transparent", "yellow", "orange"]
}
```

- Each cell holds an integer index. Integer `i` selects `palette[i+1]`
  (index 0 → first palette entry).
- **Convention**: index `0` is the background. If its palette name is
  `transparent` / `none` / `bg`, those cells are left transparent when rendered.
- Palette entries may be color names (`"black"`, `"yellow"`, `"sky blue"`) or
  hex (`"#ff8000"`).

### Size and color limits

- **Size is free**: the grid can be any `H × W` (square or rectangular). The
  renderer and scorer infer the size from the grid itself.
  - The **benchmark** (Pixel Art Bench Lite) fixes **24×24** for its 7 prompts,
    but that's a benchmark convention, not a tool limit. Use 16×16, 32×32,
    64×48, etc. for your own work.
- **Colors**:
  - The **benchmark format** uses single digits `0..9`, i.e. **up to 10 colors**.
    Stay within `0..9` if you want outputs that are byte-compatible with the
    dataset.
  - These tools also accept **larger integer indices** (`0..N`) so you can use
    **palettes bigger than 10 colors** (e.g. 16/32-color sprites). Any index is
    valid as long as the `palette` array covers it. In the ASCII preview, indices
    `10..35` show as `a..z` and anything higher as `+` (cosmetic only).

Rule of thumb: small benchmark-style icons → 24×24 with ≤10 colors; richer
sprites → larger grid with a bigger palette.

## How to generate a good grid

Follow the quality signal (see the scorer below):
**Quality ≈ 0.6 × diversity + 0.3 × density + 0.1 × structure**, gated down for noise.

- **Diversity**: use several distinct palette colors (not just 2). Add shading
  (a darker + lighter variant of the main color) and an outline color.
- **Density**: fill a meaningful portion of the grid with non-background cells;
  don't leave the subject tiny in a sea of background.
- **Structure**: build coherent shapes (connected regions), not scattered pixels.
- Keep the subject **centered** and **readable** as a silhouette.
- Always return **valid JSON**: every row the same width, every cell a
  non-negative integer, and a `palette` long enough to cover the largest index.

Workflow:

1. Pick a palette (index 0 = background). Example for the sun:
   `["transparent","#ffd800","#ff8000","#c85a00"]`.
2. Build the `grid` row by row. Use a center/offset formula for round subjects,
   or an explicit template for characters.
3. Self-check: row count == N, each row length == N, max cell index < len(palette).
4. Render and verify (steps below), then refine for diversity/density.

## Rendering to a real sprite

The renderer `scripts/render-grid.lua` **validates** the JSON (schema, ragged
rows, out-of-range cells, palette coverage) and then draws the sprite. On a
validation problem it prints a line starting with `ERROR:` and writes nothing,
so you get actionable feedback to fix the grid. This Aseprite build does not
reliably pass `--script-param`, so options come from environment variables:

```bash
ASEPRITE="/Applications/Aseprite.app/Contents/MacOS/aseprite"   # or your path
GRID_JSON=subject.json GRID_OUT=subject.png GRID_SCALE=16 \
  "$ASEPRITE" -b --script scripts/render-grid.lua
```

- `GRID_JSON`   — input JSON file (required)
- `GRID_OUT`    — output `.png` (or `.aseprite`); default `grid.png`
- `GRID_SCALE`  — integer upscale (default 16; 24×24 grid → 384×384 at 16×)
- `GRID_BG`     — background index to treat as transparent (default `0`;
                  `none` renders every cell)
- `GRID_PREVIEW`— `1` (default) prints an **ASCII preview** of the result after
                  rendering, so you can self-verify the shape in text without a
                  vision model (background cells show as `.`, others as their digit)

After rendering, read the ASCII preview (and/or open the PNG with the `read`
tool) and adjust the grid if the shape, colors, or density are off. Re-render
until it matches.

### Supported palette colors

The renderer understands `#rrggbb` / `#rgb` hex and ~60 named colors (black,
white, grays, red/crimson/maroon, orange/amber, yellow/gold, several greens,
blues/navy/sky, cyan/teal/turquoise, purple/violet/indigo/magenta, pink/lavender,
brown/tan/beige, skin/peach/cream, …). Unknown names fall back to a stable hash
color and print a `WARN:` line so you can pick a real one.

## Benchmark prompts (test subjects)

The dataset ships 7 prompts; use them as ready-made tests
(`scripts/bench-prompts.json`):

| id | subject | category |
| --- | --- | --- |
| mario | Mario from Super Mario Bros | character |
| rainbow | a rainbow | nature |
| sun | the sun | nature |
| saturn | the planet Saturn with its rings | space |
| maze | a maze | abstract |
| mona_lisa | the Mona Lisa | art |
| hope | hope | abstract |

Each benchmark prompt is literally:

> Draw pixel art on a 24x24 grid. Return a JSON object with:
> - "grid": 24x24 list of integers (0–9)
> - "palette": list of colors used
> Subject: &lt;subject&gt;

## Self-scoring helper

`scripts/score-grid.py` validates a grid-JSON and computes a quality score that
mirrors the benchmark, so you can iterate toward a better result:

```bash
python3 scripts/score-grid.py subject.json            # bg index 0 (default)
python3 scripts/score-grid.py subject.json --bg none  # count every cell
```

It reports:

- **diversity** — normalized Shannon entropy over non-background colors (rewards
  several colors in balanced proportions, not just "N distinct").
- **density** — non-background fill, saturating near ~60% (don't need a full canvas).
- **structure** — shape coherence via connected components (few large regions →
  high; scattered single pixels → low).
- **QUALITY** = `(0.6·diversity + 0.3·density + 0.1·structure) · gate`, where the
  gate suppresses high-entropy **noise** (low structure).
- **DEGENERATE** flags: blank, too sparse, looks-like-noise, or solid fill.

Aim for QUALITY ≳ 0.6 with `DEGENERATE: no`.

## Running the whole benchmark

`scripts/run-bench.py` runs the full loop. Put one grid-JSON per prompt in a
directory, named by id (`mario.json`, `rainbow.json`, `sun.json`, `saturn.json`,
`maze.json`, `mona_lisa.json`, `hope.json`), then:

```bash
export ASEPRITE="/Applications/Aseprite.app/Contents/MacOS/aseprite"
python3 scripts/run-bench.py ./solutions --scale 16
```

It scores and renders each solution, writes PNGs to `solutions/rendered/`, marks
`MISSING` / `INVALID` prompts, and prints an **aggregate** mean-quality score.
Rendering is skipped gracefully if Aseprite isn't found (scoring still runs).

## Relationship to the other skills

- For art-quality rules (silhouette, clusters, shading, AA, palette, anti-AI-tells)
  consult the `pixel-art-rules` rulebook and run its validation checklist.

- Once rendered, hand off to `pixel-art-professional` for dithering/shading, or
  to `pixel-art-exporter` for PNG/GIF/spritesheet output.
- For free-form (non-grid) drawing with the Aseprite MCP tools, use
  `pixel-art-creator` instead.
