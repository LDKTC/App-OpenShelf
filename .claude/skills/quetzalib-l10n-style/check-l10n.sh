#!/usr/bin/env bash
# check-l10n.sh — verify en/th key parity in lib/l10n/app_localizations.dart,
# and flag likely-hardcoded user-facing strings in screens/widgets that
# bypass AppLocalizations.
#
# Usage:
#   .claude/skills/quetzalib-l10n-style/check-l10n.sh
#
# Exit code is always 0 — every finding here is a warning/signal for a human
# or agent to judge, not a hard wiring failure (missing th keys degrade
# gracefully to the English value by design, per app_localizations.dart's
# own doc comment).
set -e
cd "$(git rev-parse --show-toplevel)"

L10N_FILE="lib/l10n/app_localizations.dart"

if [ ! -f "$L10N_FILE" ]; then
  echo "!! $L10N_FILE not found — nothing to check."
  exit 0
fi

extract_keys() {
  # $1 = block variable name, e.g. _en or _th
  sed -n "/^const $1 = /,/^};/p" "$L10N_FILE" \
    | grep -oE "^[[:space:]]*'[a-zA-Z0-9_]+':" \
    | grep -oE "'[a-zA-Z0-9_]+'" \
    | tr -d "'" \
    | sort -u
}

echo "=== en/th key parity ($L10N_FILE) ==="
EN_KEYS="$(extract_keys _en)"
TH_KEYS="$(extract_keys _th)"

EN_COUNT=$(echo "$EN_KEYS" | grep -c . || true)
TH_COUNT=$(echo "$TH_KEYS" | grep -c . || true)
echo "en: $EN_COUNT keys, th: $TH_COUNT keys"

MISSING_TH=$(comm -23 <(echo "$EN_KEYS") <(echo "$TH_KEYS"))
MISSING_EN=$(comm -13 <(echo "$EN_KEYS") <(echo "$TH_KEYS"))

if [ -n "$MISSING_TH" ]; then
  echo
  echo "WARNING: keys in _en missing from _th (falls back to English at runtime):"
  echo "$MISSING_TH" | sed 's/^/  - /'
fi

if [ -n "$MISSING_EN" ]; then
  echo
  echo "WARNING: keys in _th with no _en counterpart (orphaned / typo?):"
  echo "$MISSING_EN" | sed 's/^/  - /'
fi

if [ -z "$MISSING_TH" ] && [ -z "$MISSING_EN" ]; then
  echo "OK: en/th key sets match exactly."
fi

echo
echo "=== Likely-hardcoded literal UI strings (heuristic, review each) ==="
echo "Text(...)/Text.rich/AppBar title/label/hint literals with a capital letter"
echo "and a space — real prose, not an icon name or format string:"
grep -rnE "Text\('[A-Z][a-zA-Z0-9 ,.'!?-]+ [a-zA-Z0-9 ,.'!?-]+'\)" \
  lib/screens lib/widgets 2>/dev/null | grep -v "AppLocalizations" || echo "  (none found)"

echo
echo "Note: this is a heuristic grep, not a parser — expect some false"
echo "positives (debug/log strings, non-UI text) and don't treat every hit"
echo "as a bug. Cross-check against lib/l10n/app_localizations.dart before"
echo "flagging something as a real missing-translation issue."
