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

# --- Stage 3: marketplace-side onboarding ---

marketplace_pr_exists() {
  local repo="$1"
  [ -n "$(gh pr list --repo "$ORG/marketplace" --head "onboard/$repo" --state all --json number --jq '.[0].number' 2>/dev/null)" ]
}

build_plugin_entry() {
  local repo="$1" sha="$2"
  local plugin_json name description author repository

  plugin_json=$(gh api "/repos/$ORG/$repo/contents/.claude-plugin/plugin.json" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null) || return 1
  name=$(echo "$plugin_json" | jq -r '.name') || return 1
  description=$(echo "$plugin_json" | jq -r '.description') || return 1
  author=$(echo "$plugin_json" | jq -c '.author') || return 1
  repository=$(echo "$plugin_json" | jq -r '.repository') || return 1

  jq -nc \
    --arg name "$name" \
    --arg description "$description" \
    --argjson author "$author" \
    --arg category "uncategorized" \
    --arg url "https://github.com/$ORG/$repo.git" \
    --arg sha "$sha" \
    --arg homepage "$repository" \
    '{name: $name, description: $description, author: $author, category: $category,
      source: {source: "url", url: $url, sha: $sha}, homepage: $homepage}'
}

add_repo_to_update_pins() {
  local repo="$1"
  sed -i.bak -E "s/(REPOS=\([^)]*)\)/\1 \"${repo}\")/" "$UPDATE_PINS_YML"
  rm -f "${UPDATE_PINS_YML}.bak"
}

apply_marketplace_edits() {
  local repo="$1" sha="$2"
  local entry
  entry=$(build_plugin_entry "$repo" "$sha") || return 1

  if ! jq --argjson entry "$entry" '.plugins += [$entry]' "$MARKETPLACE_JSON" > tmp.json; then
    rm -f tmp.json
    return 1
  fi
  if [ ! -s tmp.json ]; then
    rm -f tmp.json
    return 1
  fi

  mv tmp.json "$MARKETPLACE_JSON"
  add_repo_to_update_pins "$repo"
}

open_marketplace_pr() {
  local repo="$1"
  if marketplace_pr_exists "$repo"; then
    log "Marketplace PR for $repo already exists (open/merged/closed) — skipping"
    return
  fi

  local resolved
  resolved=$(resolve_latest_release_sha "$repo")
  if [ -z "$resolved" ]; then
    log "$repo has no release yet — skipping marketplace PR for now"
    return
  fi
  local tag sha branch
  tag=$(echo "$resolved" | cut -d' ' -f1)
  sha=$(echo "$resolved" | cut -d' ' -f2)
  branch="onboard/$repo"

  git checkout main
  if ! git pull; then
    log "WARNING: git pull failed while onboarding $repo — skipping this repo for this run"
    git checkout main
    return
  fi
  git checkout -b "$branch"

  if ! apply_marketplace_edits "$repo" "$sha"; then
    log "WARNING: failed to build plugin entry for $repo — skipping this repo and returning to main"
    git checkout main
    git branch -D "$branch"
    return
  fi

  git add "$MARKETPLACE_JSON" "$UPDATE_PINS_YML"
  git commit -m "feat: onboard $repo into marketplace"

  if [ "$DRY_RUN" = "true" ]; then
    log "DRY RUN: would push $branch and open a PR onboarding $repo (tag $tag, sha $sha)"
  else
    if ! git push -u origin "$branch"; then
      log "WARNING: git push failed for $repo's onboarding branch — commit exists locally but was not pushed; check manually"
      git checkout main
      return
    fi
    if ! gh pr create --repo "$ORG/marketplace" --base main --head "$branch" \
        --title "feat: onboard $repo into marketplace" \
        --body "$(cat <<EOF
Adds \`$repo\` to the marketplace, pinned to \`$tag\` (\`$sha\`), and adds it to \`update-pins.yml\`'s REPOS array.

- [ ] Confirm \`category\` is correct (written as \`"uncategorized"\` placeholder)
EOF
)"; then
      log "WARNING: pushed $branch for $repo but PR creation failed — check manually"
      git checkout main
      return
    fi
  fi

  git checkout main
}

# --- Stage 4: individual-repo CI PR ---

notify_step_block() {
  cat <<'EOF'

      # Push-notify the marketplace to re-pin this plugin's SHA immediately.
      # The marketplace's nightly poll remains the self-healing backstop.
      - name: Notify marketplace to update pins
        if: steps.version.outputs.released == 'true'
        run: gh workflow run update-pins.yml --repo jacquardlabs/marketplace
        env:
          GH_TOKEN: ${{ secrets.RELEASE_TOKEN }}
EOF
}

append_notify_step() {
  local content="$1"
  printf '%s\n' "$content"
  notify_step_block
}

ci_pr_exists() {
  local repo="$1"
  [ -n "$(gh pr list --repo "$ORG/$repo" --head "ci/notify-marketplace" --state all --json number --jq '.[0].number' 2>/dev/null)" ]
}

open_ci_pr() {
  local repo="$1"
  if ci_pr_exists "$repo"; then
    log "CI PR for $repo already exists (open/merged/closed) — skipping"
    return
  fi

  local branch="ci/notify-marketplace"
  local file_path=".github/workflows/release.yml"
  local file_data current_content file_sha new_content main_sha

  if ! file_data=$(gh api "/repos/$ORG/$repo/contents/$file_path" 2>/dev/null); then
    log "WARNING: could not fetch $file_path for $repo — skipping CI PR"
    return
  fi
  if ! current_content=$(echo "$file_data" | jq -r '.content' | base64 -d 2>/dev/null); then
    log "WARNING: could not decode $file_path content for $repo — skipping CI PR"
    return
  fi
  if ! file_sha=$(echo "$file_data" | jq -r '.sha'); then
    log "WARNING: could not read file sha for $repo — skipping CI PR"
    return
  fi
  new_content=$(append_notify_step "$current_content")

  if ! main_sha=$(gh api "/repos/$ORG/$repo/git/refs/heads/main" --jq '.object.sha' 2>/dev/null); then
    log "WARNING: could not resolve main SHA for $repo — skipping CI PR"
    return
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log "DRY RUN: would create branch $branch on $repo from $main_sha and update $file_path"
    log "DRY RUN: would open a CI PR on $repo adding the notify step"
    return
  fi

  if ! gh api -X POST "/repos/$ORG/$repo/git/refs" \
      -f "ref=refs/heads/$branch" -f "sha=$main_sha" >/dev/null; then
    log "WARNING: could not create branch $branch on $repo — skipping CI PR"
    return
  fi

  local encoded
  encoded=$(printf '%s' "$new_content" | base64 | tr -d '\n')

  if ! gh api -X PUT "/repos/$ORG/$repo/contents/$file_path" \
      -f "message=ci: push-notify marketplace on release" \
      -f "content=$encoded" \
      -f "sha=$file_sha" \
      -f "branch=$branch" >/dev/null; then
    log "WARNING: could not update $file_path on $repo's $branch — branch created but file update failed, PR not opened; check manually"
    return
  fi

  if ! gh pr create --repo "$ORG/$repo" --base main --head "$branch" \
      --title "ci: push-notify marketplace on release" \
      --body "$(cat <<'EOF'
Adds the marketplace push-notify step to this repo's release.yml.

Before merging:
- [ ] Confirm `RELEASE_TOKEN` secret is set on this repo
- [ ] Confirm the `main-branch-protection` ruleset is applied to this repo
EOF
)"; then
    log "WARNING: branch/file updated on $repo but PR creation failed — check manually"
    return
  fi
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
