---
name: quetzalib-l10n-style
description: Check en/th localization key parity and flag likely-hardcoded UI strings when adding or changing user-facing text in QuetzaLib. Use when adding a new string, screen, or dialog, when reviewing a diff that touches lib/screens or lib/widgets, or when asked to ตรวจสอบ/check the translations.
---

# QuetzaLib localization & string-wiring consistency

QuetzaLib hand-writes its own `AppLocalizations` class
(`lib/l10n/app_localizations.dart`) instead of using Flutter's `gen-l10n` +
`.arb` pipeline (there's no Flutter SDK in the environment this project was
scaffolded in, so `flutter gen-l10n` couldn't be run — see the doc comment at
the top of that file). Two plain `const` maps, `_en` and `_th`, back typed
getters like `AppLocalizations.of(context).save`.

**A missing key doesn't crash** — `_t()` falls back to the English value
(`_values[key] ?? _en[key] ?? key`), so an incomplete Thai translation
degrades gracefully instead of breaking the screen. That means key-parity
gaps are a **quality issue** (Thai users silently see English), not a wiring
error — this differs from DraconDex's `check.mjs`, where a missing i18n key
is a hard failure.

## Check (agent path)

```bash
bash .claude/skills/quetzalib-l10n-style/check-l10n.sh
```

Prints, and always exits 0 (every finding is a judgment call, not a hard
failure):

1. **en/th key parity** — any key present in `_en` but missing from `_th`
   (falls back to English at runtime — the thing to actually fix), and any
   key in `_th` with no `_en` counterpart (usually a typo/rename that left
   an orphan behind — also worth cleaning up).
2. **Likely-hardcoded literal UI strings** — a heuristic grep over
   `lib/screens` and `lib/widgets` for `Text('...')` calls with real prose
   (capitalized, multi-word) that don't already reference
   `AppLocalizations`. This is a grep, not a parser: expect some false
   positives (log/debug strings, non-UI text) and verify each hit by hand
   rather than treating every line as a bug.

## Adding a new user-facing string — the actual workflow

1. Add the key to **both** `_en` and `_th` blocks in
   `lib/l10n/app_localizations.dart`, same key name, real Thai for the `_th`
   value — don't leave it English "for now," since nothing will ever remind
   you to come back (no CI check enforces this).
2. Add a typed getter (or method, for strings with `{placeholder}`
   interpolation — see `documentScanFailed(String error)` for the pattern)
   in the matching section of the class, grouped by screen the way the
   existing getters already are (Common / Home / Library screen / …).
3. Call it as `AppLocalizations.of(context).yourGetter` at the call site —
   never a raw string literal for anything a user reads.
4. Run `check-l10n.sh` — it should report `OK: en/th key sets match exactly`
   and not newly flag your call site as hardcoded.

## Gotchas

- The two maps must use **identical key names** — a typo in one but not the
  other (`bookRemvoedMessage` vs `bookRemovedMessage`) silently produces one
  orphaned key and one English-fallback key, and nothing errors. This is
  exactly what the parity check catches.
- Placeholder interpolation is a plain string `replaceAll('{param}', value)`
  in `_p()` — the placeholder name in the map's string (e.g. `{error}`,
  `{title}`, `{field}`) must match the key passed in the getter's
  `_p('key', {'error': error})` call exactly, in both locales.
- `appTitle` (`'QuetzaLib'`) is intentionally identical in both locales —
  don't "fix" that thinking it's an untranslated string; it's a brand name.
- The hardcoded-string heuristic will miss strings built by concatenation or
  passed through a variable before reaching `Text(...)` — it only catches
  literal `Text('...')` calls. Read the actual screen when reviewing a new
  feature, don't rely on the grep alone.
- `supportedLocales` in `AppLocalizations` currently lists only `en` and
  `th` — adding a third locale means adding a new `const _xx = <String,
  String>{...}` map with every key from `_en`, adding it to
  `supportedLocales`, and updating `check-l10n.sh`'s `extract_keys` calls
  (currently hardcoded to `_en`/`_th`) to also check the new block.
