#!/usr/bin/env bash
# Prints the npm dist-tag for publishing VERSION, given the version `latest` points at now:
#   a prerelease                  next
#   a stable newer than latest    latest
#   a stable older than latest    release-X.Y (a backport never takes latest)
# There is no default: without a stable `latest` to compare with it fails, so a failed registry read cannot move latest.
#
# Usage: npm-dist-tag.sh VERSION LATEST
set -euo pipefail

version="${1:?usage: npm-dist-tag.sh VERSION LATEST}"
latest="${2:-}"
stable='^[0-9]+\.[0-9]+\.[0-9]+$'

[[ "$latest" =~ $stable ]] || { echo "npm's latest is '$latest', not a stable version" >&2; exit 1; }
if [[ "$version" == *-* ]]; then
  echo next
elif [[ ! "$version" =~ $stable ]]; then
  echo "'$version' is not a version" >&2
  exit 1
elif [ "$(printf '%s\n%s\n' "$latest" "$version" | sort -V | tail -1)" = "$version" ]; then
  echo latest
else
  major_minor="${version%.*}"
  # npm refuses a dist-tag that parses as a semver range, so a bare 1.2 or v1.2 would not do.
  echo "release-$major_minor"
fi
