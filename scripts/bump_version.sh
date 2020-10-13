#!/bin/bash

# Add the version in CHANGELOG.md and mix.exs, add the changes in git (don't commit), then run this script

set -e
set -x

version=$1

if [ -z "$version" ]; then
  echo "Usage: bump_version.sh <VERSION>"
  exit 1
fi

git commit -m "Bump $version"
git push
git tag -a $version -m "$version"
git push -u origin $version
