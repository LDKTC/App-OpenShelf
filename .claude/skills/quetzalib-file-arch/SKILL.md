---
name: quetzalib-file-arch
description: Decide whether a QuetzaLib file should be split, and keep lib/ tidy — line-count bands as a signal, responsibility as the rule. Use before adding a lot of code to an already-large file, when a file passes ~400-500 lines, when reorganizing lib/, or when asked to แยกไฟล์ / check if a file is too big.
---

# QuetzaLib file architecture

There is no automated checker script for this yet (unlike DraconDex's
`check-arch.mjs`) — this repo is small enough (largest non-generated file is
`database_service.dart` at 443 lines; see `wc -l lib/**/*.dart`) that a
manual judgment call is sufficient today. Re-evaluate whether a script earns
its keep once the codebase grows past what a quick `wc -l` scan covers.

Dart/Flutter's import-based module system means DraconDex's hardest
concerns — global-scope cross-`<script>`-tag ordering, TDZ hazards, lazy
`<script>` injection races — **don't apply here**. Splitting a `.dart` file
is just: create the new file, move code, add `import`/`export` statements,
done. No load-order proof required.

## When to split

Same priority order as DraconDex's `Plan.md` guidance, since the underlying
judgment call is language-agnostic:

1. **One file, one main job.**
2. **If the part can be named as its own class/widget/service, split it.**
3. **If you keep scrolling to find things, it's too big.**
4. **If the code is reusable elsewhere (another screen, another service),
   split it out.**
5. **Line count is a signal, not a rule** — bands recalibrated to this
   repo's actual scale (DraconDex's 500/1000/2000/4000 bands assume a much
   larger app):

   | lines | what it means |
   |---|---|
   | 0–250 | normal |
   | 250–450 | check whether it has more than one job |
   | 450–700 | start considering a split |
   | 700+ | re-evaluate — this is doing too much for this codebase's scale |

   Exempt: `lib/l10n/app_localizations.dart` (698 lines as of writing) — a
   data file (translation table + typed getters), same rationale as
   DraconDex's i18n/DDL exemptions. Splitting it into per-screen locale
   files would fragment the single "does en/th have every key" check in
   `quetzalib-l10n-style`; keep it one file unless that check is updated to
   span multiple files too.

   A 400-line file that does exactly one job (e.g. `database_service.dart`'s
   schema + CRUD) is fine; a 150-line file mixing two unrelated
   responsibilities is not.

## Where things live

```
lib/main.dart                        entry point, MaterialApp setup
lib/theme.dart                       ThemeData
lib/l10n/                            hand-written AppLocalizations (en/th)
lib/models/                          plain data classes — Book, BookCategory,
                                      ReadingStamp, BookCoverPreset, BookPage,
                                      BookMetadata, AppUpdateInfo
lib/services/                        one file per concern — database, ISBN
                                      utils, settings, metadata orchestration,
                                      lookup resolution, document scanning,
                                      OCR, image storage, in-app updater
lib/services/metadata_providers/     one file per external API (Google Books,
                                      Open Library, RanobeDB)
lib/state/library_provider.dart      the single ChangeNotifier wrapping DB access
lib/screens/                         one file per screen
lib/widgets/                         shared UI pieces reused across screens
test/                                mirrors lib/'s shape (test/services/,
                                      test/services/metadata_providers/)
```

A concern that outgrows one file becomes a **folder** the way
`metadata_providers/` already is (one file per provider, a shared interface
if/when one exists) — not `foo_bar_baz.dart` siblings dumped flat into
`services/`.

## How to split safely (this codebase, specifically)

1. **Move the code, then fix imports.** Cut the class/function(s) into the
   new file, add the needed `import 'package:quetzalib/...';` lines in both
   the new file and any file that used to get the symbol transitively
   through the old one, and `export` from the old file only if something
   external still expects to find the symbol there.
2. **Watch for a class that's also a `ChangeNotifier`/`Provider` consumer**
   (`library_provider.dart` is the only one today) — splitting logic out of
   it means the split-out code either takes the provider as a constructor
   arg or becomes a pure function with no state, not a second notifier
   competing for the same `Consumer`/`context.watch` call sites.
3. **`test/` mirrors `lib/`'s directory shape** — when you split
   `lib/services/x.dart` into `lib/services/x.dart` +
   `lib/services/x_helpers.dart`, check whether `test/services/x_test.dart`
   should split the same way, or whether the existing test file can just
   keep testing the public behavior regardless of the internal split (often
   the better choice — tests should track behavior, not file boundaries).

## After a split

1. `flutter analyze` → zero issues (this repo's own bar, per the README).
2. `flutter test` → still green.
3. `bash .claude/skills/quetzalib-l10n-style/check-l10n.sh` if the split
   touched any screen/widget with user-facing strings.
4. Update `docs/FILES.md` if `write-docs` has been run on this repo (see
   `.claude/skills/write-docs/SKILL.md`), and the "Project layout" block in
   `README.md` if the split changes the shape described there.
