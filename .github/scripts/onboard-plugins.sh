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

# --- Stage 2: classification ---

classify_release_yml_content() {
  local content="$1"
  if [ -z "$content" ]; then
    echo "missing"
    return
  fi
  if ! grep -q "Publish GitHub release" <<<"$content"; then
    echo "unrecognized"
    return
  fi
  if grep -q "update-pins.yml" <<<"$content"; then
    echo "compliant"
  else
    echo "needs_notify"
  fi
}

fetch_release_yml_content() {
  local repo="$1"
  gh api "/repos/$ORG/$repo/contents/.github/workflows/release.yml" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true
}

classify_release_yml() {
  local repo="$1"
  classify_release_yml_content "$(fetch_release_yml_content "$repo")"
}

resolve_latest_release_sha() {
  local repo="$1"
  local release tag ref_data type raw_sha sha

  release=$(gh api "/repos/$ORG/$repo/releases/latest" 2>/dev/null) || return 0
  tag=$(echo "$release" | jq -r '.tag_name // empty') || return 0
  [ -z "$tag" ] && return 0

  ref_data=$(gh api "/repos/$ORG/$repo/git/refs/tags/$tag" 2>/dev/null) || return 0
  type=$(echo "$ref_data" | jq -r '.object.type') || return 0
  raw_sha=$(echo "$ref_data" | jq -r '.object.sha') || return 0

  if [ "$type" = "tag" ]; then
    sha=$(gh api "/repos/$ORG/$repo/git/tags/$raw_sha" 2>/dev/null | jq -r '.object.sha') || return 0
  else
    sha="$raw_sha"
  fi
  echo "$tag $sha"
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
