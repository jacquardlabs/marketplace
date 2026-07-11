#!/usr/bin/env bash
set -euo pipefail

ORG="jacquardlabs"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"
UPDATE_PINS_YML=".github/workflows/update-pins.yml"
DRY_RUN="${DRY_RUN:-true}"

log() { echo "[onboard-plugins] $*"; }

# --- Stage 1: discovery ---

discover_plugin_repos() {
  gh repo list "$ORG" --limit 200 --json name,isArchived,isFork \
    | jq -r '.[] | select(.isArchived==false and .isFork==false and .name!="marketplace") | .name' \
    | while read -r repo; do
        if gh api "/repos/$ORG/$repo/contents/.claude-plugin/plugin.json" >/dev/null 2>&1; then
          echo "$repo"
        fi
      done
}

is_listed() {
  local repo="$1"
  jq -e --arg org "$ORG" --arg r "$repo" \
    'any(.plugins[]; .source.url | contains("/" + $org + "/" + $r + ".git"))' \
    "$MARKETPLACE_JSON" >/dev/null
}

filter_unlisted() {
  local repo
  while read -r repo; do
    [ -z "$repo" ] && continue
    if ! is_listed "$repo"; then
      echo "$repo"
    fi
  done
}

# --- main ---

main() {
  log "Discovering plugin repos in $ORG..."
  local candidates
  candidates=$(discover_plugin_repos | filter_unlisted)

  if [ -z "$candidates" ]; then
    log "No new plugin repos found. Nothing to do."
    return
  fi

  echo "$candidates"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  main "$@"
fi
