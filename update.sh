#!/usr/bin/env -S nix shell nixpkgs#jq -c bash

set -euo pipefail

regex="^[a-zA-Z0-9.-]+$"
info="info.json"

if [ ! -f "$info" ] || ! jq -e . "$info" > /dev/null 2>&1; then
  echo '{"version": "0.0.0", "generic": {"hash": "", "url": ""}, "specific": {"hash": "", "url": ""}}' > "$info"
fi

oldversion=$(jq -rc '.version' "$info")

url="https://api.github.com/repos/zen-browser/desktop/releases?per_page=1"
version="$(curl -s "$url" | jq -rc '.[0].tag_name')"

echo "Fetched version: $version"

if [[ "$version" == "twilight" || "$version" == "$oldversion" ]]; then
  echo "Version is twilight, verifying hashes..."
  sharedUrl="https://github.com/zen-browser/desktop/releases/download"
  genericUrl="${sharedUrl}/${version}/zen.linux-generic.tar.bz2"
  specificUrl="${sharedUrl}/${version}/zen.linux-specific.tar.bz2"

  echo "Prefetching files for twilight..."
  nix store prefetch-file "$genericUrl" --log-format raw --json | jq -rc '.hash' >/tmp/genericHash &
  nix store prefetch-file "$specificUrl" --log-format raw --json | jq -rc '.hash' >/tmp/specificHash &
  wait

  genericHash=$(</tmp/genericHash)
  specificHash=$(</tmp/specificHash)

  oldGenericHash=$(jq -rc '.generic.hash' "$info")
  oldSpecificHash=$(jq -rc '.specific.hash' "$info")

  if [[ "$genericHash" != "$oldGenericHash" || "$specificHash" != "$oldSpecificHash" ]]; then
    echo "Hashes changed for twilight, updating info.json..."
    echo "{\"version\":\"$version\",\"generic\":{\"hash\":\"$genericHash\",\"url\":\"$genericUrl\"},\"specific\":{\"hash\":\"$specificHash\",\"url\":\"$specificUrl\"}}" > "$info"
    echo "Zen updated to version $version with new hashes."
  else
    echo "Hashes for twilight are unchanged, no update needed."
  fi
  exit 0
fi

if [[ "$oldversion" != "$version" && "$version" =~ $regex ]]; then
  echo "Found new version $version"
  sharedUrl="https://github.com/zen-browser/desktop/releases/download"
  genericUrl="${sharedUrl}/${version}/zen.linux-generic.tar.bz2"
  specificUrl="${sharedUrl}/${version}/zen.linux-specific.tar.bz2"

  echo "Prefetching files..."
  nix store prefetch-file "$genericUrl" --log-format raw --json | jq -rc '.hash' >/tmp/genericHash &
  nix store prefetch-file "$specificUrl" --log-format raw --json | jq -rc '.hash' >/tmp/specificHash &
  wait

  genericHash=$(</tmp/genericHash)
  specificHash=$(</tmp/specificHash)

  echo "{\"version\":\"$version\",\"generic\":{\"hash\":\"$genericHash\",\"url\":\"$genericUrl\"},\"specific\":{\"hash\":\"$specificHash\",\"url\":\"$specificUrl\"}}" > "$info"

  echo "Zen updated to version $version"
else
  echo "Zen is up to date"
fi