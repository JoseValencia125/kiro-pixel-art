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
  "grid": [[0,1,1, ...], [ ... ], ...],   // NxN list of integers 0-9 (default 24x24)
  "palette": ["transparent", "yellow", "orange"]
}
```

- Each cell holds an integer `0..9`. Integer `i` selects `palette[i+1]`
  (index 0 → first palette entry).
- **Convention**: index `0` is the background. If its palette name is
  `transparent` / `none` / `bg`, those cells are left transparent when rendered.
- Palette entries may be color names (`"black"`, `"yellow"`, `"sky blue"`) or
  hex (`"#ff8000"`).

## How to generate a good grid

Follow the benchmark's quality signal: **Quality = 0.7 × diversity + 0.3 × density**.

- **Diversity**: use several distinct palette colors (not just 2). Add shading
  (a darker + lighter variant of the main color) and an outline color.
- **Density**: fill a meaningful portion of the grid with non-background cells;
  don't leave the subject tiny in a sea of background.
- Keep the subject **centered** and **readable** as a silhouette.
- Always return **valid JSON**: exactly N rows of N integers, every integer in
  `0..9`, and a `palette` long enough to cover the largest index used.

Workflow:

1. Pick a palette (index 0 = background). Example for the sun:
   `["transparent","#ffd800","#ff8000","#c85a00"]`.
2. Build the `grid` row by row. Use a center/offset formula for round subjects,
   or an explicit template for characters.
3. Self-check: row count == N, each row length == N, max cell index < len(palette).
4. Render and verify (steps below), then refine for diversity/density.

## Rendering to a real sprite

The renderer `scripts/render-grid.lua` parses the JSON and draws the sprite.
This Aseprite build does not reliably pass `--script-param`, so paths are passed
via environment variables:

```bash
ASEPRITE="/Applications/Aseprite.app/Contents/MacOS/aseprite"   # or your path
GRID_JSON=subject.json GRID_OUT=subject.png GRID_SCALE=16 \
  "$ASEPRITE" -b --script scripts/render-grid.lua
```

- `GRID_JSON` — input JSON file
- `GRID_OUT`  — output `.png` (or `.aseprite`)
- `GRID_SCALE`— integer upscale (default 16; 24×24 grid → 384×384 at 16×)

After rendering, verify the result with the `read` tool (Image mode) and adjust
the grid if the shape, colors, or density are off. Re-render until it matches.

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

`scripts/score-grid.py` computes a rough quality score for a grid-JSON file
(JSON validity, color diversity, non-background density) mirroring the benchmark,
so the agent can iterate toward a better result:

```bash
python3 scripts/score-grid.py subject.json
```

## Relationship to the other skills

- Once rendered, hand off to `pixel-art-professional` for dithering/shading, or
  to `pixel-art-exporter` for PNG/GIF/spritesheet output.
- For free-form (non-grid) drawing with the Aseprite MCP tools, use
  `pixel-art-creator` instead.
