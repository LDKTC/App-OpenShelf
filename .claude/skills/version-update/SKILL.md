---
name: version-update
description: Bump pubspec.yaml's "version" field (X.Y.Z+B — semver plus an Android build number) following this repo's own convention, verified against git history rather than guessed. Use when asked to "bump the version", "update the version", "prepare a release build", or right before build-release-git cuts a tag.
---

# version-update — bump pubspec.yaml's version field

`pubspec.yaml`'s `version: X.Y.Z+B` line is the single source of truth —
`X.Y.Z` is standard semver (Flutter/Dart convention, not DraconDex's
`x.y.z-n` scheme), `B` is the Android `versionCode` (must strictly increase
on every build that ships, per Play/Android install rules — even though this
app isn't distributed through the Play Store, `B` still backs the in-app
updater's "is this newer" check in `update_service.dart`, so it must go up
every release regardless of whether `X.Y.Z` changes).

There is no marker file and no `Plan.md`/`procress.md` workflow in this
repo (unlike DraconDex) — state is read fresh from `pubspec.yaml` and git
history every run.

## Run

1. **Read the current version** from `pubspec.yaml`'s `version:` line. If it
   doesn't parse as `X.Y.Z+B`, stop and ask the user what it should be.

2. **Find the anchor commit** — the last commit that changed the version
   line, so you know what's new since the last bump:

   ```bash
   git log -G'^version:' -- pubspec.yaml -1 --format=%H
   ```

   (This repo's own history shows this pattern: bump commits are their own
   commit, message `Bump version to X.Y.Z+B for release`, usually right
   before/after a merge — e.g. `06d34d3 Bump version to 1.1.1+4 for
   release`.)

3. **Gather the real diff since that anchor**: `git log --oneline
   <anchor>..HEAD`, `git diff <anchor>..HEAD -- lib android pubspec.yaml`,
   plus uncommitted work (`git status --porcelain`, `git diff`, `git diff
   --staged`). Read the actual diff, not just commit subjects.

4. **Classify the semver segment** using standard semver judgment (this repo
   doesn't use DraconDex's elaborate module-vs-fix/500-line test — keep it
   simple):

   | Diff since anchor | Bump |
   |---|---|
   | Breaking change to the local DB schema with no migration, or a UI/navigation overhaul | **Major** — `X` |
   | A new feature/screen/capability (new scan mode, new metadata provider, new screen) | **Minor** — `Y` |
   | Bug fix, small tweak, dependency bump, doc/CI change, refactor with no user-visible change | **Patch** — `Z` — default when unsure |

   Reset lower segments to `0` when bumping a higher one (`1.1.1` → `1.2.0`,
   not `1.2.1`).

5. **Always increment `B`** (the `+build` number) by exactly 1 from the
   current value, regardless of which semver segment moved — it's a flat
   counter, never reset. This is what `update_service.dart` and Android's
   install logic actually compare.

6. **Write it** by hand-editing the `version:` line in `pubspec.yaml` (Dart
   has no `npm version`-style CLI for this — there's nothing else to update;
   unlike DraconDex's `package-lock.json`, there's no mirrored version field
   elsewhere in this repo to keep in sync).

7. **Report**: old → new version, one-line rationale for the segment chosen,
   and remind the user this is a version bump only — it does not commit,
   build, or tag. If they want a release cut afterward, that's
   `.claude/skills/build-release-git/SKILL.md`.

## Commit convention (for whoever commits this)

This repo's own history commits the bump as its own commit, separate from
the feature work, with message `Bump version to X.Y.Z+B for release` (see
`06d34d3`, `0932ae8`, `595fc32`). This skill does not commit — suggest that
message, matching this repo's own style, for the user or a follow-up step to
use.

## Gotchas

- `git log -- pubspec.yaml` can overcount if unrelated dependency bumps also
  touch the file — pickaxe the version line itself (`-G'^version:'`) to find
  real version-bump commits, not just any pubspec.yaml touch.
- `B` (the build number) must **never** go backward and must increase on
  every release build, even a patch-only release — this is what lets
  `update_service.dart`'s GitHub-release version check and Android's package
  installer both agree "this is newer."
- There is no `-N` in-progress suffix convention here (unlike DraconDex) —
  don't invent one. If a release is still being prepared across several
  commits, just don't bump again until it's ready; there's nothing mid-flight
  to track in the version string itself.
- Malformed/unparseable current version, or nothing changed since the anchor:
  stop and say so — don't guess, don't bump on an empty diff.
- This is bump-only. Committing, tagging, and triggering the release build
  are `build-release-git`'s job, not this skill's.
