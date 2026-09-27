#!/usr/bin/env bash
#
# Release a new version of pdf_extractor.
#
#   scripts/release.sh <major|minor|patch|X.Y.Z>
#
# Bumps the version in mix.exs and README.md, moves the [Unreleased] changelog
# entries under the new version, commits, tags, pushes (which triggers the
# GitHub release workflow) and publishes to Hex.

set -euo pipefail

cd "$(dirname "$0")/.."

REPO_URL="https://github.com/nelsonmestevao/pdf_extractor"
MAIN_BRANCH="main"

die() {
  echo "error: $*" >&2
  exit 1
}

confirm() {
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

[[ $# -eq 1 ]] || die "usage: $0 <major|minor|patch|X.Y.Z>"

current=$(sed -n 's/^  @version "\(.*\)"$/\1/p' mix.exs)
[[ -n "$current" ]] || die "could not find @version in mix.exs"

IFS=. read -r major minor patch <<<"$current"
case "$1" in
  major) new="$((major + 1)).0.0" ;;
  minor) new="$major.$((minor + 1)).0" ;;
  patch) new="$major.$minor.$((patch + 1))" ;;
  *) new="$1" ;;
esac

[[ "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version: $new"
[[ "$new" != "$current" ]] || die "version $new is already the current version"

# Preconditions

[[ "$(git branch --show-current)" == "$MAIN_BRANCH" ]] || die "not on $MAIN_BRANCH"
[[ -z "$(git status --porcelain)" ]] || die "working tree is not clean"

git fetch --quiet --tags origin "$MAIN_BRANCH"
[[ "$(git rev-parse HEAD)" == "$(git rev-parse "origin/$MAIN_BRANCH")" ]] ||
  die "$MAIN_BRANCH is not in sync with origin/$MAIN_BRANCH"

git rev-parse --quiet --verify "refs/tags/v$new" >/dev/null && die "tag v$new already exists"

unreleased=$(awk '/^## \[Unreleased\]/ { found = 1; next } found && /^## \[/ { exit } found && NF' CHANGELOG.md)
[[ -n "$unreleased" ]] || die "no entries under [Unreleased] in CHANGELOG.md"

echo "==> Releasing $current -> $new"
echo
echo "$unreleased"
echo

# Checks

echo "==> Running checks"
mix format --check-formatted
mix test --warnings-as-errors

# Bump version

echo "==> Bumping version"
today=$(date +%Y-%m-%d)

perl -pi -e "s/^  \@version \"\Q$current\E\"$/  \@version \"$new\"/" mix.exs
perl -pi -e "s/\{:pdf_extractor, \"~> \Q$current\E\"\}/{:pdf_extractor, \"~> $new\"}/" README.md
perl -pi -e "
  s/^## \[Unreleased\]\n/## [Unreleased]\n\n## [$new] - $today\n/;
  s{^\[Unreleased\]: .*\n}{[Unreleased]: $REPO_URL/compare/v$new...HEAD\n[$new]: $REPO_URL/compare/v$current...v$new\n};
" CHANGELOG.md

mix test test/readme_test.exs

git --no-pager diff

confirm "Commit, tag, push and publish v$new?" || {
  git checkout -- mix.exs README.md CHANGELOG.md
  die "aborted, changes reverted"
}

# Release

git commit --quiet -am "Release $new"
git tag -a "v$new" -m "Version $new"
git push --atomic origin "$MAIN_BRANCH" "v$new"

mix hex.publish

echo "==> Released v$new"
