# Usability checklist for QuetzaLib

Adapted from Nielsen's usability heuristics (the flow/behavior-relevant
ones — aesthetic/visual heuristics live in `ui-researcher/VISUAL-CHECKLIST.md`
instead). Use this as a scoring rubric during Step 4 of the `ux-researcher`
skill — not every item applies to every flow, skip what doesn't.

## 1. Visibility of system status
- Does a metadata lookup in progress (scan → API call → result) show a
  loading state, or does the UI look frozen while `book_metadata_service.dart`
  tries providers in order?
- Does the in-app updater's download/install (`update_service.dart`) show
  real progress, or just a spinner with no sense of how long it'll take?
- Does OCR processing (photograph → recognize → review dialog) show that
  it's working, especially over a slow Cloud Vision API call vs. the fast
  on-device path?

## 2. Match between system and the real world
- Do labels match how a reader actually talks about their collection ("my
  library," "shelf," "reading status") rather than generic database terms
  ("record," "entry," "item")?
- Reading-status stamps (`reading`/`finished`/`dropped`/`paused`) — are the
  labels and icons self-explanatory, or do they need a legend?

## 3. User control and freedom
- Is there an obvious cancel/back at every step of a multi-step flow (cover
  scan wizard, OCR review dialog, manual add form)?
- Can a mis-scanned/misidentified book be corrected without deleting and
  re-adding it from scratch?

## 5. Error prevention
- Destructive actions — removing a book, deleting a cover preset, deleting a
  saved page/stamp — is the confirm specific ("remove 'Title' from your
  library?") or generic ("are you sure?")? Generic confirms get reflexively
  clicked through.
- Scan-to-fill never writes to a field without the user reviewing/approving
  the recognized text first (by design, per the README) — verify any new
  scan-adjacent feature keeps that same "always confirm before writing"
  contract rather than quietly regressing it.

## 6. Recognition rather than recall
- Can a user find a book they already added by scanning it again
  ("search-by-scan," per the README) instead of having to recall its title
  and type it into search?
- Are recently-added books or the active shelf view surfaced without extra
  navigation?

## 7. Flexibility and efficiency of use
- Power-user paths: text-entry ISBN add (vs. scanning) for a barcode that
  won't scan, bulk category assignment if it exists. Do they exist for
  repeated/awkward-camera situations, or is scanning the *only* path?
- Manual add/edit exists for books with no barcode or no metadata match —
  is it discoverable from the point a scan/lookup fails, or buried
  somewhere a frustrated user won't find it?

## 9. Help users recognize, diagnose, and recover from errors
- If a metadata lookup finds nothing (all three providers exhausted), does
  the UI say so and offer manual add, or just show a dead end?
- The signature-conflict install failure (see `c32b8f0` in git history) is a
  real precedent: does the app explain *what to do* ("uninstall the old
  build first") rather than surfacing a raw system error?

## 10. Help and documentation
- Is Cloud Vision OCR setup (Settings → paste an API key) discoverable and
  explained in-context, or does a user need to already know it exists
  (currently documented only in the README, per the "OCR text scanning"
  section) to get accurate Thai recognition?

## QuetzaLib-specific angles

- **Discoverability of secondary flows**: cover/page scanning, OCR
  scan-to-fill, and the in-app updater are all real, working features
  reachable from specific screens (book detail, book editor, Settings) but
  not from the main library/scan loop. Is that discoverable to a user who
  doesn't already know it exists?
- **Cognitive load of the multi-source lookup**: three providers tried in
  order, each with different data completeness (RanobeDB is "best-effort,"
  per the README). A user shouldn't need to know *which* provider answered
  to trust the result — check whether the source is shown usefully
  (`sourceLabel`) without requiring the user to understand the fallback
  chain to make sense of gaps in the data.
- **Camera-dependent flows on real hardware**: scanning (barcode, cover,
  page, OCR) is the app's core interaction and can't be meaningfully judged
  from code alone — flag when a finding genuinely needs a real device/camera
  to verify rather than asserting it from the widget tree.

## Comparison-app cheat sheet (workflow, not visuals)

| Pattern in QuetzaLib | Look at how... |
|---|---|
| Scan-to-add core loop | Libib / Delicious Library — barcode-scan-to-catalog UX specifically, the closest direct competitor |
| Multi-source metadata fallback, "best-effort" results | LibraryThing's multi-source lookup + manual-correction UX |
| Reading-status stamp timeline (vs. one status field) | The StoryGraph's status/mood timeline — closest analog to a history instead of a single field |
| Shelf browsing (spine/cover visual view) | Goodreads' shelf view, physical-bookshelf-style cataloging apps |
| Cover preset editing (front/spine/back slots) | Any app letting a user attach multiple photos to one catalog item — which slot leads visually, how partial completion is shown |
