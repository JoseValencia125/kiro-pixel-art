---
name: pixel-art-rules
description: Actionable pixel-art rulebook (MUST / SHOULD / AVOID + validation checklist) for generating and reviewing sprites. Use whenever drawing, shading, outlining, anti-aliasing, dithering, building a palette, animating, or reviewing pixel art, or when the user asks why a sprite "looks off", "looks AI-generated", "looks blurry/noisy", or wants it to look professional/clean. Complements pixel-art-creator (drawing), pixel-art-professional (dithering/shading) and pixel-art-grid (grid-JSON).
---

# Pixel Art Rulebook

Concrete, checkable rules for producing clean pixel art and for avoiding the
tells of machine-generated art. Each rule is **MUST** (do it / never break it),
**SHOULD** (strong default, break only with a reason) or **AVOID** (common
failure). Read the relevant section before drawing, then run the **Validation
checklist** before calling a sprite done.

Core idea: **pixel art is an image where every pixel is a deliberate decision.**
A 32×32 canvas is not a low-resolution render. The viewer reads *shapes of
colour*, not individual pixels — so design shapes, keep them clean, and justify
every stray pixel.

---

## 1. Fundamentals

- **MUST** decide canvas size, palette, light direction and view **before**
  drawing a single pixel. Most "AI tells" come from skipping this.
- **MUST** draw natively at the target resolution. Never draw big and downscale
  — naive downscaling produces mush, lost features and extra colours ("mixels").
- **MUST** keep the canvas small on purpose: more pixels never fix a shape
  problem; they only hide it.
- **SHOULD** work in the order that catches mistakes while they are cheap:
  silhouette → flat colours → shading → outline → AA → review.
- **SHOULD** check the sprite at **1× (actual size)** constantly, not just
  zoomed in. If it only reads at 800%, it is not finished.
- **AVOID** treating the grid as a painting surface: soft blocks of uneven size
  are the #1 generated-art tell.

## 2. Palette & colour

- **MUST** use a limited palette; pick the count before drawing. Typical budgets:
  2 (1-bit), 4 (Game Boy), 8–16 (NES/retro), 16 (PICO-8), 32+ only when the size
  justifies it.
- **MUST** build colour **ramps** (dark→light series for one material), not a
  pile of unrelated colours.
- **MUST** hue-shift along a ramp: shadows shift toward a cool/complementary hue
  (blue/purple), highlights toward a warm/light hue (yellow/orange). A ramp that
  only changes brightness is a tell.
- **SHOULD** rotate hue by roughly 10–40° across a ramp; keep saturation highest
  in the mid-tones, lower it slightly at the extremes.
- **SHOULD** reuse colours across materials (shared ramps) to keep the palette
  small and cohesive.
- **SHOULD** vary saturation and value, not just one; ensure strong **value**
  contrast between the main masses (squint — they must separate in greyscale).
- **AVOID** pure black (`#000000`) outlines and pure white highlights; use a very
  dark hued colour and a tinted white instead.
- **AVOID** hundreds of near-identical colours; if two swatches are almost equal,
  merge them.
- **AVOID** a rainbow of hues where three would do; a harmonious palette shares a
  temperature or a tinting colour.

## 3. Silhouette & form

- **MUST** make the subject readable as a **solid black silhouette** first. If
  you can't tell what it is from the silhouette, shading won't save it.
- **MUST** keep the subject centred and large enough to fill a meaningful part of
  the canvas (good density), not tiny in a sea of background.
- **SHOULD** give distinctive, varied shapes to different parts (big/small,
  round/angular) so they read at a glance; exaggerate the defining feature.
- **SHOULD** design one or two strong, recognisable elements rather than piling
  on detail.
- **AVOID** symmetrical, tangent or evenly-spaced shapes that merge into one blob.

## 4. Outlines & edges

- **SHOULD** pick one outline policy and hold it: full dark outline, **selective**
  outline (outline only where forms overlap or face away from light), or no
  outline.
- **SHOULD** colour the outline relative to its fill (a darker, hued version),
  not flat black, unless the style is deliberately graphic.
- **SHOULD** vary outline weight with light: thinner/ lighter toward the light,
  thicker/darker in shadow.
- **MUST** keep the outline exactly **1 px** at small sizes; a 2 px outline eats
  the sprite.
- **AVOID** outlining interior detail that the eye already separates by value
  (inline noise).

## 5. Lines & curves

- **MUST** keep a line's runs consistent: a staircase should step in an even
  rhythm (e.g. 2,2,2 or 3,3,3). One run longer/shorter than its neighbours shows
  at 1× as a **jaggy**.
- **MUST** avoid a 2×2 lump or a 2 px-wide segment on a 1 px line — it reads as a
  blob.
- **SHOULD** build curves from decreasing/increasing run lengths (e.g. 4,3,2,1),
  never random.
- **SHOULD** fix all jaggies **before** anti-aliasing. AA on a lumpy curve just
  makes a smooth-looking lump.
- **AVOID** "doubles" (isolated single-pixel direction changes) in a straight run.

## 6. Clusters & noise

(A **cluster** = touching pixels of one colour; orthogonal contact joins them,
diagonal contact is weak.)

- **MUST** design with **few, large, clean clusters**, not scattered pixels.
  Squint: a few big masses of light and dark must survive.
- **MUST** remove **orphan pixels** (a lone pixel touching no same-colour pixel,
  not AA or part of a curve). Delete it, merge it, or grow it to a 2–3 px shape.
- **SHOULD** allow at most **one** intentional orphan per object (a specular
  highlight, an eye on a tiny sprite, a spark, an AA pixel) — never random speckle
  and never near the face.
- **MUST** define the big light and shadow planes first, then the second-largest
  shapes. Spotty isolated patches inside a lit plane are the beginner error.
- **SHOULD** use ≤ 3 tones per material at 16–32 px; each tone forms a few
  connected clusters, not confetti.
- **AVOID** banding: two colour boundaries that run the same length and end on the
  same row/column so the grid shows. Cure by staggering the breaks by 1 px
  (brick-like), or crossing the step in 1–2 px.
- **AVOID** the "super pixel": every stripe ending exactly where the staircase
  steps, giving a diagonal the resolution of one fat pixel.
- **AVOID** unintentional 2×2 squares where two same-colour regions meet; stagger
  the colour change.
- **AVOID** noise: random/filter dither, leftover sketch pixels, texture with no
  repeat. Remove detail before adding; fewer colours with cleaner shapes first.

## 7. Shading & light

- **MUST** choose **one** light direction and model every form to it; state it
  explicitly.
- **MUST** end a shadow abruptly at a **terminator** (the line where the form
  turns away from light), not by blending inward.
- **AVOID** **pillow shading**: rings of shade that follow the outline inward and
  ignore the light. This is the single most recognisable amateur/AI tell.
- **SHOULD** group values by plane: one value cluster per plane-facing direction;
  straight-edged clusters for flat planes, curved for round forms. Don't cut a
  sphere with a straight terminator or a box with a curved one.
- **SHOULD** add a highlight cluster and (optionally) a subtle reflected/ambient
  light in the deepest shadow — but keep highlights rare and small.
- **AVOID** gradients from even concentric rings (reads as flat plastic); use a
  lit cluster + an abrupt shadow cluster instead.

## 8. Anti-aliasing (AA)

- **MUST** fix jaggies first (see §5), then decide **whether** to AA at all.
- **MUST NOT** AA sprites ≤ 12 px, 1-bit/4-colour palettes, straight 1:1
  diagonals, or straight lines.
- **SHOULD** AA soft/round styles ≥ 24 px, faces/eyes, and junctions of two
  high-contrast colours.
- **MUST** AA only steps of 3+ px at 16 px (2 px steps only from ~32 px).
- **MUST** keep the AA strip to **≤ 2/3** of the step: one shade covers ~1/3, two
  shades up to ~2/3; **never ≥ 3/4** (reads as a second line / banding).
  Lengths: step 2→1 px; 3→1; 4→1 or 1+1; 6→2 or 2+2; 9→3 or 3+3.
- **MUST** place AA in the **inner corner** of the step, extended along the longer
  run; the shade next to the outline is the darker one.
- **MUST** pick the in-between colour with a value **and** hue *between* the two
  neighbours. A halftone darker/lighter than both neighbours reads as glow/shadow.
- **MUST NOT** AA the **outside** of an outline on an unknown background — it bakes
  in one background and shows as a halo elsewhere. Internal AA is safe anywhere.
- **SHOULD** budget shades by size: 0–1 at 16 px, 1–2 at 32 px, up to 3 at 64 px+.
- **AVOID** filter AA: bilinear/bicubic resize, non-90° rotation and soft brushes
  add dozens of near-colours and mush. Use nearest-neighbour integer scaling only.

## 9. Dithering & texture

- **SHOULD** use dithering to fake a missing colour (mix two you have) or a
  gradient under a tight palette — intentionally, with a consistent pattern.
- **SHOULD** prefer ordered patterns (checkerboard, 50%/25%) with a clear repeat;
  keep cluster size consistent within an object.
- **MUST** keep dithering stable across animation frames (it flickers otherwise).
- **AVOID** random/noise dither and the smooth-gradient tool — both read as grain
  or plastic at small sizes.
- **SHOULD** treat texture as **repeat + rest**: a few glyphs re-stamped, dense
  areas balanced against empty ones (empty reads as implied texture).
- **AVOID** dithering on sprites ≤ 16 px or on tiny features.

## 10. Readability & scale

- **MUST** test the sprite at the size it will actually be seen; detail the scale
  can't hold becomes blobs.
- **SHOULD** budget detail to size: 8 px = silhouette + 2–3 colours; 16 px = 3
  tones/material, maybe an eye; 32 px = tones + outline + a highlight; 64 px = add
  texture as repeats on clean planes.
- **SHOULD** keep strong value contrast on the focal element; push background /
  distant parts back with **lower contrast and less detail**, not blur.
- **AVOID** equal importance everywhere (same cluster size, contrast and texture
  across the whole image) — it yields correct pixels and no picture.

## 11. Animation

- **MUST** keep the cluster structure stable frame-to-frame; hair/cape that
  re-forms its clusters every frame flickers.
- **MUST NOT** add orphan pixels that exist on only one frame.
- **SHOULD** use held extremes and eased spacing, not equal durations (a
  metronome reads as a slideshow of poses).
- **SHOULD** give idles small, lagging, feet-planted motion that loops seamlessly
  and never changes the character's size.
- **SHOULD** give walks a pass pose, runs an airborne frame, attacks a wind-up +
  a fast smear + a landing hold.
- **SHOULD** animate secondary parts (hair, cape, tail) to start later, travel
  further at the free end, overshoot and settle.

## 12. Tells of generated / AI pixel art (hunt and fix these)

- **AVOID** soft blocks of **uneven** size (true pixel art has one consistent
  grid cell).
- **AVOID** hundreds of near-identical colours (quantise to a real palette).
- **AVOID** speckle used as texture (merge into 2–3 px shapes).
- **AVOID** shading that follows the outline inward (pillow shading → use a light
  direction and a terminator).
- **AVOID** the same density/contrast everywhere (establish a focal point and
  quiet zones).
- **AVOID** ramps that only darken, one saturation for every swatch, pure-black
  outlines (fix hue travel and value structure).
- **AVOID** mush/lost features/extra colours from downscaling (redraw at target
  size instead).

---

## Validation checklist (run before "done")

Mechanical / by eye, at **1× on dark, light and mid-grey backgrounds**:

1. **Silhouette** reads as solid black; subject centred, good density.
2. **Palette**: limited, ramps hue-shifted, no pure black/white, no
   near-duplicate colours.
3. **Clusters**: few large clean clusters; ≤ 3 tones per material; no orphan
   except one allowed highlight/eye/spark/AA per object.
4. **Lines**: even run rhythm, no jaggies, no 2×2 on a 1 px line.
5. **Banding**: no two boundaries running the same length on the same row/column;
   no super-pixel; no 2×2 squares at colour joins.
6. **Shading**: one stated light direction; terminators, not rings; no pillow
   shading.
7. **AA**: only on steps ≥ 3 px (≥ 2 at 32+), strips ≤ 2/3 of the step, inner
   corner only, no exterior halo, no semi-transparent pixels, no AA on 1:1 lines.
8. **Dithering**: intentional, consistent, stable across frames; no noise dither.
9. **Readability** at target size; focal contrast high, background pushed back by
   contrast not blur.
10. **Animation**: stable clusters across frames; no single-frame orphans; motion
    reads as weight, not a metronome.
11. **No AI tells**: consistent grid cell, real palette, clean shapes, one light.

If using `pixel-art-grid`, the `score-grid.py` helper flags the mechanical half
(density, diversity, structure, degenerate grids); this checklist covers the rest.

---

## Sources

Synthesised from established pixel-art teaching, which these rules paraphrase
(no text copied):

- **Pixeli — Pixel Art Knowledge Base / Rulebook** (clusters & noise,
  anti-aliasing, and the per-size budgets): https://pixeli.pebbly.space/knowledge
- **Pixel Logic** (Michael Azzi) — anti-aliasing step/strip ratios, banding,
  line weight, shapes-as-mosaic.
- **Pedro Medeiros / Saint11 — Pixel Art Tutorials**:
  https://saint11.art/blog/pixel-art-tutorials/
- **Daniel Silber — Pixel Art for Game Developers** (banding, super pixel, pillow
  shading, scatter tiles).
- **SLYNYRD — Pixelblog**: https://www.slynyrd.com/pixelblog-catalogue
- **Lospec — Pixel Art Tutorials** (incl. palette creation by RHL Pixels):
  https://lospec.com/pixel-art-tutorials
- **Derek Yu — Pixel Art Tutorial**: https://www.derekyu.com/extras.html
- **Pixel Joint — The Pixel Art Tutorial**:
  https://pixeljoint.com/forum/forum_posts.asp?TID=11299
- **Helm — Pixelation tutorials**: https://lospec.com/pixel-art-tutorials/author/helm

These are credited in the repository `NOTICE`.
