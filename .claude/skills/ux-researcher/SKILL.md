---
name: ux-researcher
description: Research and improve QuetzaLib's usability — scan-to-add flow, library browsing/search, task flow, discoverability, cognitive load. Combines targeted external UX research (competitor apps like Goodreads, Libib, LibraryThing, The StoryGraph) with a real-app or code-level audit, scored against usability heuristics. Use when asked to improve UX, simplify a flow, make the app easier to use, evaluate a feature's usability before or after building it, or audit a screen's task flow. For visual/theming/aesthetic questions use ui-researcher instead.
---

# UX Researcher

Goal: make QuetzaLib easier and more pleasant to actually *use* — the
scan-to-add flow, library browsing/search/filter, cover/page capture,
scan-to-fill OCR review, reading-status stamps. This is about **how the app
behaves and how easy it is to accomplish a task**, not how it looks.

- For **visual design** (Material 3 color/contrast, typography, spacing,
  component polish) use the `ui-researcher` skill instead.
- For **localization wiring** (missing translation keys, hardcoded strings)
  that's `.claude/skills/quetzalib-l10n-style/` — mention it in passing if
  you notice one, don't re-solve it here.

For a quick, targeted question ("is the OCR review dialog's flow OK?", "how
should cover preset editing present its three slots?") run this skill
inline. For a bigger job — a full audit across several screens, or
research-heavy competitor comparison — delegate to the `ux-researcher` agent
instead (see bottom of this file) so screenshots/web research don't eat the
main conversation's context.

## Step 1 — Scope the request

- **(a) Audit** — find usability problems in an existing screen/flow.
- **(b) Pre-build research** — a new feature/pattern doesn't exist yet;
  research how it should work before code gets written.
- **(c) General pass** — no single target, look across the app for the
  highest-impact usability issues.

## Step 2 — External research (targeted, not a survey)

Use WebSearch/WebFetch scoped to the *specific* pattern in question — not a
generic "UX best practices" dump. QuetzaLib is a personal-library / book
cataloging tool, so the most relevant comparisons are:

| App | Relevant for |
|---|---|
| **Goodreads** | shelf organization, reading-status model (want-to-read/reading/read), search-while-adding flow |
| **Libib / Delicious Library** | barcode-scan-to-catalog flow specifically — the closest direct competitor to QuetzaLib's core loop |
| **LibraryThing** | manual metadata editing UX, cover management, multi-source lookup fallback presentation |
| **The StoryGraph** | reading-status timeline (mood/pace tags) — closest analog to QuetzaLib's multi-stamp reading-status history instead of a single status field |
| **Nielsen Norman Group** | heuristic backing for a specific claim, not general reading |

Cite *why* a finding is relevant to the QuetzaLib flow in question — don't
link-dump.

## Step 3 — Audit the real flow

Prefer a live audit when the environment allows it (see
`.claude/skills/run-quetzalib/SKILL.md` for what's actually runnable in this
session — Flutter/Android SDK availability varies by environment). Walk the
actual flow — empty state, populated state, error/edge-case state (no
network for metadata lookup, no barcode match, OCR returning no text).
**Read screenshots if you have them; don't guess what a flow does from the
code alone.**

When a live run isn't possible, read the actual screen code
(`lib/screens/*.dart`) and count real steps/taps/decisions — not the
apparent ones (a "scan" button might hide a confirm-then-review step, like
OCR scan-to-fill's mandatory review dialog before anything is written to a
field — see the README's "OCR text scanning" section for why that exists;
don't recommend removing that confirmation as a "simplification," it's a
deliberate safety/trust choice).

## Step 4 — Evaluate against the checklist

See [HEURISTICS.md](HEURISTICS.md) for the full checklist: visibility of
system status, match between the app and real-world book/reader vocabulary,
user control & error prevention (destructive actions — removing a book,
deleting a cover preset, deleting a saved page — must confirm specifically),
recognition over recall, efficiency for power users vs. friendliness for
new ones, minimalism/progressive disclosure, error recovery (network lookup
failure, no barcode match, install-signature-conflict on update), and
discoverability (cover/page scanning, OCR scan-to-fill, in-app updates are
all secondary flows off the main scan/library loop).

## Step 5 — Report findings

Prioritized list, most severe first. Per finding:

- **Severity** — blocker (can't complete the task) / major (confusing,
  error-prone) / minor (friction) / polish
- **What** — the concrete screen/flow, with a screenshot reference if one
  was taken
- **Why it hurts** — which heuristic it violates, or what a comparison app
  does differently/better and why that matters here
- **Fix** — a concrete recommendation pointing at the actual file/widget to
  change where possible (e.g. "`cover_presets_screen.dart`'s slot grid gives
  front/spine/back equal visual weight even though front is what appears on
  the shelf — lead with it"), not just "make it clearer"
- **Effort** — rough: copy/label tweak vs. new interaction pattern vs.
  structural rework

## Running as an agent

For research-heavy or multi-screen work, spawn the `ux-researcher` agent
(`.claude/agents/ux-researcher.md`) via the Agent tool instead of doing it
inline. Brief it with: the specific flow/feature in scope, anything already
tried or ruled out, and whether you want external research, a live/code
audit, or both — a fresh agent has none of this conversation's context.

## Gotchas

- QuetzaLib supports only `en`/`th` — don't assume English is the only
  audience; check how a flow reads with real Thai strings
  (`lib/l10n/app_localizations.dart`), not lorem-ipsum-length English.
- Metadata lookup has a deliberate provider fallback order (Google Books →
  Open Library → RanobeDB as a light-novel-specific last resort, per the
  README) — a "no result" state can mean all three failed; don't recommend
  simplifying this into "just show an error" without checking whether the
  UI already distinguishes "still trying the next source" from "exhausted
  all sources."
- The OCR scan-to-fill review dialog and the destructive-action confirms are
  intentional friction, not bugs — don't propose removing a confirmation
  step as a "simplification" unless the flow is genuinely non-destructive.
- Check `docs/SYSTEMS.md`/`docs/CHANGELOG.md` (if `write-docs` has been run
  on this repo) before reporting something as newly discovered.
