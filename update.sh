#!/usr/bin/env -S nix shell nixpkgs#jq -c bash

set -euo pipefail

regex="^[a-zA-Z0-9.-]+$"
info="info.json"

if [ ! -f "$info" ] || ! jq -e . "$info" > /dev/null 2>&1; then
  echo '{"version": "0.0.0", "hash": "", "url": ""}' > "$info"
fi

oldversion=$(jq -rc '.version' "$info")

url="https://api.github.com/repos/zen-browser/desktop/releases?per_page=1"
version="$(curl -s "$url" | jq -rc '.[0].tag_name')"

echo "Fetched version: $version"

if [[ "$version" == "twilight" || "$version" == "$oldversion" ]]; then
  echo "Version is twilight, verifying hash..."
  sharedUrl="https://github.com/zen-browser/desktop/releases/download"
  downloadUrl="${sharedUrl}/${version}/zen.linux-x86_64.tar.bz2"

  echo "Prefetching file..."
  nix store prefetch-file "$downloadUrl" --log-format raw --json | jq -rc '.hash' >/tmp/newHash

  newHash=$(</tmp/newHash)
  oldHash=$(jq -rc '.hash' "$info")

  if [[ "$newHash" != "$oldHash" ]]; then
    echo "Hash changed, updating info.json..."
    echo "{\"version\":\"$version\",\"hash\":\"$newHash\",\"url\":\"$downloadUrl\"}" > "$info"
    echo "Zen updated to version $version with new hash."
  else
    echo "Hash is unchanged, no update needed."
  fi
  exit 0
fi

if [[ "$oldversion" != "$version" && "$version" =~ $regex ]]; then
  echo "Found new version $version"
  sharedUrl="https://github.com/zen-browser/desktop/releases/download"
  downloadUrl="${sharedUrl}/${version}/zen.linux-x86_64.tar.bz2"

  echo "Prefetching file..."
  nix store prefetch-file "$downloadUrl" --log-format raw --json | jq -rc '.hash' >/tmp/newHash

  newHash=$(</tmp/newHash)

  echo "{\"version\":\"$version\",\"hash\":\"$newHash\",\"url\":\"$downloadUrl\"}" > "$info"

  echo "Zen updated to version $version"
else
  echo "Zen is up to date"
fi
