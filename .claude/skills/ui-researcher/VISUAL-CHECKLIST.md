# Visual design checklist for QuetzaLib

Covers aesthetic/visual quality — the flow/behavior heuristics live in
`ux-researcher/HEURISTICS.md` instead. Use this as a scoring rubric during
Step 4 of the `ui-researcher` skill; not every item applies to every
finding, skip what doesn't.

## Aesthetic and minimalist design (Nielsen heuristic 8)

- Is there visual information on screen the current task doesn't need? Does
  the library list/shelf give equal visual weight to every book regardless
  of state (has cover vs. no cover, has reading status vs. none)?
- Does whitespace/density feel intentional in list/grid views, or does
  content feel cramped when a book has a long title/many authors, or sparse
  for a book with minimal metadata?
- Icon-to-label ratio — do the list/shelf-view toggle, scan-to-search, and
  filter icons clearly reinforce their function, or add noise without a
  label to anchor them?

## Material 3 color-role usage and contrast

`lib/theme.dart` builds one `ColorScheme.fromSeed`. For any finding
involving color:

- Check the widget actually reads a `ColorScheme` role
  (`Theme.of(context).colorScheme.primary`/`surface`/`onSurface`/etc.)
  rather than a hardcoded `Color(0x...)` — a hardcoded color can't adapt if
  the seed color or a future dark theme changes it, and is itself a
  code-quality finding worth naming alongside the visual one.
- Reading-status chips (`status_chip.dart`) and category badges are the
  most likely place for a semantic color (not just a decorative one) — check
  contrast of text-on-chip specifically, not just against the screen
  background.
- `AppBarTheme` sets `backgroundColor: colorScheme.surface` with
  `elevation: 0` — check that this doesn't visually flatten the app bar
  against content directly beneath it (no elevation shadow to separate
  them) on screens with a solid-color body immediately below.

## Typography and spacing rhythm

- Do headings/body/meta text follow `TextTheme`'s scale consistently across
  screens, or does one screen invent its own `TextStyle` inline where a
  `Theme.of(context).textTheme.*` role would do?
- `inputDecorationTheme` sets a flat `OutlineInputBorder()` globally — check
  that form-heavy screens (book editor, category manager, cover preset
  rename) render consistent field spacing/padding rather than each screen
  wrapping fields differently.
- Long Thai strings in fixed-width contexts (list tiles, chips, buttons) —
  do they wrap/truncate gracefully, or clip/overflow?

## Icon and component consistency

- Buttons: is the visual hierarchy (which button draws the eye — e.g. in
  the book detail screen's actions, or the cover preset editor's
  scan/replace/delete row) matching the intended hierarchy (primary action
  should read as primary)?
- Do shared patterns — list tile, empty state (icon + message + primary
  action), confirm dialog, cover/page capture flow — render with consistent
  visual rhythm across the screens that use them, or has one screen's
  version drifted (different icon size, spacing, or button placement) even
  though it's nominally the same pattern?

## Shelf/spine visual presentation (QuetzaLib-specific)

This is the app's most visually distinctive surface — worth its own
checklist section:

- Spine tiles (`book_shelf_tile.dart`) with a scanned spine image vs. the
  text-info-tile fallback for books with no cover yet — do they sit
  together in the shelf grid without looking like two different apps?
- Cover-preset slot editing (front/spine/back) — does the visual treatment
  make clear which slot is used *where* (front → shelf-view cover mode,
  spine → shelf-view spine mode)?
- Aspect-ratio handling for photographed covers/spines/pages — cropped
  consistently, or does a portrait photo distort into a fixed tile shape?

## Motion and feedback

- Transitions between library list ↔ shelf view, and list tile ↔ detail
  screen — consistent duration/feel, or does one navigation path feel
  noticeably snappier or laggier?
- Toast/snackbar feedback (save confirmations, delete confirmations) —
  visually consistent placement and duration regardless of which screen
  triggered it?

## Comparison-app visual cheat sheet

| Visual question in QuetzaLib | Look at how... |
|---|---|
| Shelf grid readability (spine/cover mix, missing-cover fallback) | Libib / Delicious Library's shelf visualization |
| Empty-state visual treatment (no books yet, no covers yet) | Goodreads' empty shelf/list states — icon + short copy + single clear CTA |
| Status-chip/badge color and contrast | Any app using a small set of semantic status colors against varying backgrounds (reading/finished/dropped/paused) |
| Dense list-view hierarchy for a large catalog | LibraryThing's list view — how it stays scannable at high density |
| Material 3 color-role correctness | Material Design 3's own color-system guidelines — objective baseline, not opinion |
