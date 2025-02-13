#!/usr/bin/env nix-shell
#!nix-shell --pure -i bash -p curl -p cacert -p jq -p nix
# shellcheck shell=bash
set -euo pipefail

if [[ ${1:-} = '-h' || ${1:-} = '--help' ]]; then
    echo "Usage: $(basename "$0") [-h] [repository] [reference]"
    echo
    echo "Update linux-t2 patches from a GitHub repostiory containing patches."
    echo "Produces a patches.json file."
    echo
    echo "arguments:"
    echo "  repository: github repostiory to fetch from [default='t2linux/linux-t2-patches']"
    echo "   reference: git reference [default=latest commit from the default branch]"
    exit 0
fi

REPO="${1:-t2linux/linux-t2-patches}"
REF="${2:-}"
TMPFILE=$(mktemp /tmp/tmp.XXXXXXX.json)

if [[ -z "${REF}" ]]; then
    BRANCH=$(curl --silent "https://api.github.com/repos/${REPO}" | jq -r '.default_branch')
    REF=$(curl --silent "https://api.github.com/repos/${REPO}/branches/${BRANCH}" | jq -r '.commit.sha')
fi

echo "Repo: ${REPO}"
echo "Reference: ${REF}"

for url in $(curl --silent "https://api.github.com/repos/${REPO}/contents?ref=${REF}" |
    jq 'map(select(.name | test("^\\d{4}-.*\\.patch"))) | .[].download_url' |
    xargs); do
    HASH=$(nix-prefetch-url --type sha256 "${url}" | xargs nix-hash --to-sri --type sha256)
    echo "{\"name\": \"$(basename "${url}")\", \"url\": \"${url}\", \"hash\": \"${HASH}\"}" >>"$TMPFILE"
done

jq -s '.' "$TMPFILE" >patches.json
rm -fr "$TMPFILE"
