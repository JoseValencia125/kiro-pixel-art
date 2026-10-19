---
name: pixel-art-animation-rules
description: Actionable pixel-art ANIMATION rulebook (MUST / SHOULD / NEVER + review checklist) for planning and building sprite animation — timing & spacing, easing, walk & run cycles, jumps, melee attacks, secondary motion, sub-pixel and modular animation, top-down. Use whenever animating a sprite, building a walk/run/attack/idle cycle, setting frame timing/FPS, or reviewing why motion "looks floaty / slides / reads as a slideshow". Complements pixel-art-animator (the Aseprite how-to) and pixel-art-rules (still-image rules).
---

# Pixel Art Animation Rulebook

Concrete rules for making sprite motion read as *weight and intent*, not a
slideshow of good poses. **MUST** = do it / non-negotiable. **SHOULD** = strong
default, break only with a reason. **NEVER** = reliably wrong. Read the relevant
section, then run the **review checklist**.

Governing idea: a sprite has only **4–12 drawings**, so *when* each shows and
*how far apart* they sit matters more than any single frame. Design the key
poses and the beat first; fill and polish second.

---

## 1. Planning (before any frame)

- **MUST** decide the animation's purpose, frame count and loop type (loop /
  ping-pong / one-shot) before drawing.
- **MUST** block the **key poses** first (extremes), review them as a thumbnail
  strip, then add breakdowns and in-betweens.
- **MUST** test **spacing with a plain dot** (or a single box) travelling the path
  before committing pixels — spacing is the rarer skill.
- **SHOULD** keep the frame count to the minimum that reads (idle 2–4, walk 4–8,
  run 6–8, attack 3–6); more frames never fix a bad key pose.
- **NEVER** start by drawing frame 1 then "the next one" linearly — that bakes in
  even spacing and a limp.

## 2. Timing & spacing

- **MUST** separate the two: **timing is *when*** a frame shows, **spacing is *how
  far*** things move between frames. Fix the beat ("impact lands on frame 4 of
  8") first, then choose per-frame offsets.
- **MUST** make per-frame offsets **sum to the total travel distance** of the move.
- **MUST** author on a **tick ladder**: pick one base tick and use multiples.
  Film rate ≈ ones 42 ms / twos 83 / threes 125 / fours 167; a 60 Hz game uses
  multiples of ~16.7 ms (33, 50, 67, 83, 100, 117, 133, 167). Default sprite
  base: **~100 ms**.
- **SHOULD** vary durations: **hold the extremes** a little longer and pass
  quickly through the middle, so the motion has accents.
- **NEVER** give every frame the same duration **and** even spacing — equal + even
  reads as a metronome slideshow.

## 3. Easing

- **MUST** ease most natural motion: cluster frames near the **slow** ends (ease
  in / ease out), spread them through the fast middle.
- **SHOULD** use slow-in/slow-out for anything that starts and stops (jumps,
  attacks, a head turn); near-linear only for constant machine motion or a steady
  walk cycle's horizontal travel.
- **SHOULD** express easing by **spacing** (pixel gaps), not only by frame
  duration — moving the pixels closer near the ends is the stronger cue.
- **NEVER** ease a looping cycle's forward travel so hard that the character
  appears to stop and restart each loop (unless that is the intent).

## 4. Walk cycle (side view)

- **MUST** build a step from **four poses: contact → down → pass → up**; two steps
  (near leg, then far leg) = one **8-frame** cycle. Draw the two **contacts** and
  the **pass** first.
- **MUST** make **contact the widest pose**: front heel down with the leg nearly
  straight, back toe still pushing, arms at their widest swing.
- **MUST** drop the body to its **lowest** on the *down* pose and lift to its
  **highest** on the *up/pass* — the vertical bob is what sells weight.
- **MUST** swing arms in **opposition** to the legs (left arm forward with right
  leg) and move hair/cloth a beat late.
- **SHOULD** match foot speed to the character's ground speed so planted feet
  don't **slide** ("skate").
- **NEVER** animate "legs apart, legs together" with no pass pose — it reads as
  sliding, and gives every character the same limp.

## 5. Run cycle (side view)

- **MUST** include an **airborne frame** (both feet off the ground) — this is what
  separates a run from a fast walk.
- **MUST** lean the torso forward, lengthen the stride, and raise the knees higher
  than a walk; arms pump harder and more bent.
- **SHOULD** use **6–8 frames** at a faster base tick (~60–80 ms) with a bigger
  vertical bob than a walk.
- **SHOULD** exaggerate the extremes (reach and tuck) more than anatomy strictly
  allows; a run is a stylised pose, not a photo.
- **NEVER** reuse the walk's vertical offsets for a run — the run bounces more and
  leaves the ground.

## 6. Melee attacks

- **MUST** keep the phase order: **anticipation → smear → hit (held) → follow-
  through → recover → overshoot.** Drop phases from the **front** first
  (anticipation); **NEVER drop the hit**.
- **MUST** send anticipation in the **opposite** direction to the strike (≥ 2–3 px
  at 32 px); the bigger the blow, the bigger the wind-up. Put the weapon "out in
  the clear," not hidden behind the head.
- **MUST** give the strike itself **one fast frame** (a smear/blur of the arc) and
  then a **hold** on the hit so the blow has weight.
- **SHOULD** make **player** attacks responsive: no wind-up, or one frame ≤ ~50 ms,
  so the first frame after the button is already the strike.
- **SHOULD** draw the weapon arc as a motion trail on the smear frame, fading over
  1–2 frames.
- **NEVER** swap straight from rest pose to hit pose with no smear and no hold —
  that is a pose swap, not an attack.

## 7. Jump, fall & land

- **MUST** build a jump as a **position curve + squash/stretch**: crouch
  (anticipation) → stretch up on launch → slow at the apex (held) → stretch down
  falling → squash on landing.
- **MUST** give distinct **rising** and **falling** poses so the player reads the
  direction of travel.
- **NEVER** float: a jump with no squash on take-off/landing and no apex hold has
  no weight.

## 8. Secondary motion

- **MUST** attach every loose part (hair, cape, scarf, tail, weapon tip) to the
  body: it **starts later**, **travels further at its free end**, **overshoots**
  when the body stops, and **settles**.
- **SHOULD** offset secondary motion by 1–2 frames behind the primary.
- **NEVER** move loose parts in lock-step with the body (reads as a cut-out) or at
  random (reads as broken).

## 9. Sub-pixel animation

- **MUST** fake sub-one-pixel motion by **moving tone**, not position: brighten the
  leading neighbour and darken the trailing one so the eye reads a shift smaller
  than a pixel.
- **SHOULD** use it to ease a 1 px move, keep an idle alive, or wobble a part
  without changing its silhouette.
- **NEVER** apply sub-pixel shimmer everywhere — it melts the sprite.

## 10. Modular animation

- **SHOULD** split a character onto named parts/layers (head, torso, arms, legs,
  weapon) and animate by **moving/rotating cels** where it saves redraws and keeps
  volume consistent.
- **SHOULD** keep a shared pivot and a shared foot row across frames so parts line
  up.
- **NEVER** let modular parts change **size or palette** between frames, and never
  let a mirrored sprite put the sword in the wrong hand.

## 11. Consistency & loops (pixel discipline in motion)

- **MUST** keep the **cluster structure stable** frame to frame; hair/cloth that
  re-forms its clusters every frame flickers.
- **MUST NOT** add an orphan/stray pixel that exists on only **one** frame.
- **MUST** make a looping cycle seamless: the last frame must lead naturally back
  into the first (dot-test the travel for an even loop).
- **NEVER** change the character's overall **height/size** across a cycle unless
  it's squash/stretch you intend.

## 12. Top-down animation

- **MUST** decide a **direction budget** up front (4 or 8 dirs) on one shared
  canvas and foot row.
- **SHOULD** reuse frames by mirroring left/right, but fix hand-held items so they
  don't swap sides.
- **NEVER** give the **back view a face**, and never let the sprite bob or resize
  when the player merely turns.

---

## Review checklist (run before "done")

Look at the **filmstrip** and the loop at 1×:

1. **Key poses** read as a thumbnail strip even without in-betweens.
2. **Beat** is deliberate (you can name which frame the accent/impact lands on).
3. **Spacing** sums to the travel; a dot-test loops evenly; no skating.
4. **Timing** on a tick ladder; extremes held, middles quick — not a metronome.
5. **Walk**: contact (widest) + pass present; vertical bob; arms in opposition.
6. **Run**: an airborne frame exists; forward lean; bigger bob than the walk.
7. **Attack**: anticipation opposite the strike; one smear frame; a hit hold.
8. **Secondary** parts lag, overshoot and settle; none move in lock-step.
9. **Consistency**: stable clusters; no single-frame strays; constant size/palette.
10. **Loop** is seamless; direction sets share canvas/foot row; no back-view face.

---

## Sources

Synthesised and paraphrased (no text copied) from:

- **Pedro Medeiros / Saint11** — Walk Cycle, Animation Planning, Animation Easing,
  1-Pixel (sub-pixel) Movement, Modular Animation, Slide/Roll/Dash:
  https://lospec.com/pixel-art-tutorials/author/pedro-medeiros
- **SLYNYRD / Pixelblog** — Intro to Animation, Melee Attacks, Motion Cycles,
  Human Walk Cycle: https://www.slynyrd.com/pixelblog-catalogue
- **Pixeli — Knowledge Base** — Timing & Spacing, Idle & Breathing, Walk & Run,
  Jump/Fall/Land, Attacks & Impacts, Sub-pixel, Top-down:
  https://pixeli.pebbly.space/knowledge
- **Lospec — Animation / Walk-cycle tutorials**:
  https://lospec.com/pixel-art-tutorials/tags/animation
- **Richard Williams, *The Animator's Survival Kit*** and the classic **12
  principles of animation** (anticipation, timing, spacing, slow-in/out, follow-
  through, exaggeration), as applied to pixel art by **Saultoons**:
  https://www.youtube.com/watch?v=vwk5UA927Ok

Credited in the repository `NOTICE`.
