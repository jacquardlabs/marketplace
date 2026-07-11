#!/usr/bin/env bash
set -euo pipefail

ORG="jacquardlabs"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"
UPDATE_PINS_YML=".github/workflows/update-pins.yml"
DRY_RUN="${DRY_RUN:-true}"

log() { echo "[onboard-plugins] $*"; }

# --- Stage 1: discovery ---

discover_plugin_repos() {
  # Fetch repo list once and check for truncation
  local repo_list
  repo_list=$(gh repo list "$ORG" --limit 200 --json name,isArchived,isFork)

  # Warn if we hit the 200-repo ceiling
  local repo_count
  repo_count=$(echo "$repo_list" | jq 'length')
  if [ "$repo_count" -ge 200 ]; then
    log "Warning: discovered repo list may be truncated (reached limit of 200 repos)"
  fi

  # Filter and check for plugin.json in each candidate repo
  echo "$repo_list" \
    | jq -r '.[] | select(.isArchived==false and .isFork==false and .name!="marketplace") | .name' \
    | while read -r repo; do
        # Capture stderr to distinguish 404 (expected) from other errors
        local error_output
        if error_output=$(gh api "/repos/$ORG/$repo/contents/.claude-plugin/plugin.json" 2>&1); then
          echo "$repo"
        elif ! grep -q "404" <<<"$error_output"; then
          log "Warning: failed to check $repo for plugin.json: $error_output"
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
