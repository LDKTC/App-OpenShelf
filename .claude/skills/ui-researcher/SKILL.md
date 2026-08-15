---
name: ui-researcher
description: Research and improve QuetzaLib's visual design — Material 3 color/contrast, typography, spacing, icon consistency, shelf/spine visual presentation, component polish. Combines targeted external visual-design research (competitor apps like Goodreads, Libib, LibraryThing) with a real-app or code-level audit. Use when asked to make the app look better, review contrast/accessibility, polish a new component's visuals, or evaluate whether a screen looks consistent/modern. For flow/usability/information-architecture questions use ux-researcher instead.
---

# UI Researcher

Goal: make QuetzaLib *look* good — visual hierarchy, color/contrast,
typography, spacing, icon and component consistency, aesthetic polish
(especially the shelf view, since spine/cover imagery is the app's most
visually distinctive surface). This is about **how the app looks**, not how
it behaves.

- For **task flow / usability / information architecture** use the
  `ux-researcher` skill instead.
- For **string/localization wiring** that's
  `.claude/skills/quetzalib-l10n-style/` — not this skill's job.

For a quick, targeted question ("does the shelf-view spine tile look right
with a missing cover image?") run this skill inline. For a bigger job — a
full visual audit across many screens — delegate to the `ui-researcher`
agent instead (see bottom of this file).

## Step 1 — Scope the request

- **(a) Audit** — find visual inconsistencies/polish issues in an existing
  screen or component.
- **(b) Pre-build research** — a new component/screen doesn't exist yet;
  research what it should look like before code gets written.
- **(c) Theme/contrast pass** — check contrast/legibility of the current
  theme. Note: unlike DraconDex's 30+ CSS theme families, QuetzaLib
  currently defines **exactly one** `ThemeData` (`lib/theme.dart`,
  `ColorScheme.fromSeed` off a single purple seed color, Material 3,
  `useMaterial3: true`) with no `darkTheme`/`themeMode` wired in `main.dart`
  — so there's no multi-theme sweep to run today. If a finding suggests the
  app should support dark mode, say so explicitly as a **scope
  recommendation** (a real gap: Android users increasingly expect
  system-dark-mode support) rather than silently assuming it exists.

## Step 2 — External research (targeted, not a mood board dump)

Use WebSearch/WebFetch scoped to the *specific* visual question — not
generic "modern UI trends" reading. Relevant comparisons for a
Material-3-based personal library/cataloging app:

| App | Relevant for |
|---|---|
| **Goodreads** | shelf/cover-grid visual density, status-badge visual treatment |
| **Libib / Delicious Library** | physical-shelf visual metaphor (spine/cover imagery as the primary visual language) — the closest direct competitor |
| **LibraryThing** | dense list-view visual hierarchy for a large personal catalog |
| **Material Design 3 guidelines** | objective backing for a color-role/contrast/typography finding, since this app already commits to M3 — check findings against the actual M3 spec, not generic "modern UI" opinion |
| **WCAG contrast guidelines** | objective backing for a contrast finding, not just "looks low-contrast to me" |

Cite *why* a finding is relevant to the QuetzaLib component in question —
don't link-dump.

## Step 3 — Audit the real app

Prefer a live run when the environment allows it — see
`.claude/skills/run-quetzalib/SKILL.md` for what's actually possible
(Flutter/Android SDK availability varies by session; `adb exec-out
screencap -p` on a connected device/emulator is the way to get a real
screenshot). **Read screenshots before writing anything about what they
show** — don't infer visual quality from widget code alone.

When a live run isn't possible, read the actual screen/widget code
(`lib/screens/*.dart`, `lib/widgets/*.dart`) and reason about the rendered
result from the `ColorScheme` roles and `TextTheme` actually used — cite
which `Theme.of(context).colorScheme.*` role a widget reads, not just that
"it looks purple."

Audit with real Thai strings too (`lib/l10n/app_localizations.dart`) — Thai
text runs longer/shorter than English in places and can reveal
overflow/clipping English-only testing wouldn't catch.

## Step 4 — Evaluate against the checklist

See [VISUAL-CHECKLIST.md](VISUAL-CHECKLIST.md) for the full checklist:
aesthetic/minimalist design (Nielsen heuristic 8), Material 3 color-role
usage and contrast, typography/spacing rhythm, icon consistency, shelf/spine
visual presentation specifically, and component consistency across screens
that share a pattern (list tiles, empty states, confirm dialogs).

## Step 5 — Report findings

Prioritized list, most severe first. Per finding:

- **Severity** — blocker (illegible/inaccessible) / major (visually
  inconsistent or jarring) / minor (polish) / nice-to-have
- **What** — the concrete screen/component, with a screenshot reference if
  one was taken
- **Why it hurts** — which visual principle or M3 guideline it violates,
  contrast ratio if measurable, or what a comparison app does visually that
  reads better and why that matters here
- **Fix** — a concrete recommendation naming the actual widget/file and
  `ColorScheme`/`TextTheme` role to change (e.g. "`book_shelf_tile.dart`'s
  fallback info-tile uses `bodyMedium` for the title where the spine/cover
  tiles next to it use `titleSmall` — inconsistent hierarchy across the same
  grid"), not just "make it prettier"
- **Effort** — rough: color/token-value tweak vs. new visual pattern vs.
  structural rework

## Running as an agent

For a full visual audit or heavy competitor-visual research, spawn the
`ui-researcher` agent (`.claude/agents/ui-researcher.md`) via the Agent tool
instead of doing it inline. Brief it with: the specific screen/component in
scope, and whether you want external visual research, a live/code audit, or
both.

## Gotchas

- **Don't invent multi-theme findings.** There is exactly one `ThemeData`
  today — a "this looks bad in dark mode" finding isn't valid unless dark
  mode actually exists; the valid finding is "dark mode doesn't exist yet,"
  which is a scope note, not a contrast bug.
- **Default locale follows the device, and Thai is fully supported** — check
  real Thai strings for overflow, not lorem-ipsum-length English ones.
- Check `docs/SYSTEMS.md`/`docs/CHANGELOG.md` (if `write-docs` has been run
  on this repo) before reporting a visual issue as newly discovered.
