#!/usr/bin/bash

set -e

function run() {
  secrets=("$GITHUB_TOKEN")

  print_cmd="$*"
  for secret in $secrets; do
    print_cmd="${print_cmd//$secret/[redacted]}"
  done

  printf "+ %s\n" "$print_cmd" >&2
  "$@"
}

function grab_vuetorrent_release() {
  release_info=$(mktemp)

  run curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/VueTorrent/VueTorrent/releases/latest > $release_info

  tag_name="$(jq -r .tag_name $release_info)"
  remote_digest="$(jq -r '.assets[] | select(.name == "vuetorrent.zip") | .digest' $release_info)"
  download_url="$(jq -r '.assets[] | select(.name == "vuetorrent.zip") | .browser_download_url' $release_info)"

  if [[ -e vuetorrent.zip ]]; then
    local_digest="sha256:$(sha256sum ./vuetorrent.zip | cut -d ' ' -f1)"
  fi

  if [[ ! -e vuetorrent.zip || "$local_digest" != "$remote_digest" ]]; then
    echo "VueTorrent missing or out of date, downloading..."
    rm -rf vuetorrent vuetorrent.zip
    run wget $download_url
    run unzip vuetorrent.zip
  fi
}

mkdir -p build
cd ./build

grab_vuetorrent_release

run docker compose pull
run docker compose restart
