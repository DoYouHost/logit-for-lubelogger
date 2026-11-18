#!/usr/bin/env bash
# Runs test/contract against a real LubeLogger container for every server
# version x locale pair, then prints one result line per pair.
#
# usage: tool/contract.sh [--versions "v1.6.9 v1.7.0"] [--locales "- en-US de-DE pl-PL"]
#
# A locale of "-" is the server default (no LUBELOGGER_LOCALE_OVERRIDE).
set -uo pipefail

versions="v1.6.9 v1.7.0 v1.7.4 latest"
locales="- en-US de-DE pl-PL"
while [ $# -gt 0 ]; do
  case "$1" in
    --versions) versions="$2"; shift 2 ;;
    --locales) locales="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

image=ghcr.io/hargata/lubelogger
cd "$(dirname "$0")/.."
names=()
trap 'for n in "${names[@]}"; do docker rm -f "$n" >/dev/null 2>&1; done' EXIT

# A memory cap where a systemd user session exists (a developer machine); a CI
# runner has none and is a throwaway VM anyway.
limit=()
if systemd-run --user --scope -q true >/dev/null 2>&1; then
  limit=(systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=0 -p RuntimeMaxSec=600)
fi

failed=0
for version in $versions; do
  docker pull -q "$image:$version" >/dev/null || { echo "FAIL  $version  (pull failed)"; failed=1; continue; }
  for locale in $locales; do
    label=$([ "$locale" = "-" ] && echo default || echo "$locale")
    name="lube-contract-${version//./_}-$label"
    names+=("$name")
    env_args=()
    [ "$locale" = "-" ] || env_args=(-e "LUBELOGGER_LOCALE_OVERRIDE=$locale")

    docker rm -f "$name" >/dev/null 2>&1
    if ! docker run -d --rm --name "$name" -p 127.0.0.1::8080 "${env_args[@]}" \
        "$image:$version" >/dev/null; then
      echo "FAIL  $version  $label  (container did not start)"; failed=1; continue
    fi
    port=$(docker port "$name" 8080/tcp | head -1 | sed 's/.*://')
    url="http://127.0.0.1:$port"
    ready=0
    for _ in $(seq 1 60); do
      curl -fs "$url/api/version" >/dev/null 2>&1 && { ready=1; break; }
      sleep 1
    done
    if [ $ready = 0 ]; then
      echo "FAIL  $version  $label  (server never answered)"; failed=1
      docker rm -f "$name" >/dev/null 2>&1; continue
    fi

    out=$(LUBELOGGER_URL="$url" LUBELOGGER_VERSION="$version" \
      LUBELOGGER_LOCALE=$([ "$locale" = "-" ] && echo "" || echo "$locale") \
      "${limit[@]}" flutter test test/contract --reporter=expanded 2>&1)
    status=$?
    summary=$(printf '%s\n' "$out" | grep -E '^[0-9:]+ \+[0-9]' | tail -1)
    if [ $status = 0 ]; then echo "PASS  $version  $label  $summary"
    else
      echo "FAIL  $version  $label  $summary"
      printf '%s\n' "$out" | grep -E '\[E\]|Expected|Actual' | head -12 | sed 's/^/        /'
      failed=1
    fi
    docker rm -f "$name" >/dev/null 2>&1
  done
done
exit $failed
