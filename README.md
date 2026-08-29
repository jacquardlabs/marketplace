# Jacquard Labs Marketplace

Jacquard Labs skill plugins for [Claude Code](https://claude.ai/code): a delivery discipline, independent judges, aggressive simplification, markdown review, and voice workflows.

[![Update plugin SHA pins](https://github.com/jacquardlabs/marketplace/actions/workflows/update-pins.yml/badge.svg)](https://github.com/jacquardlabs/marketplace/actions/workflows/update-pins.yml)

## Install

```bash
/plugin marketplace add jacquardlabs/marketplace
```

Then browse available plugins with `/plugin discover`, or install one directly with the commands below.

## Plugins

| Plugin | What it does | Install |
|---|---|---|
| [studious](https://github.com/jacquardlabs/studious) | A delivery discipline: quality gates, periodic health reviews, and pre-merge audits that examine each piece of work — whether to build it, whether the design serves users, and whether the result holds up — plus the build loop that turns an approved design into a verified implementation (`/design`, `/plan`, `/build`, `/finish`, and a coach for stuck loops). | `/plugin install studious@jacquardlabs-marketplace` |
| [gauntlet](https://github.com/jacquardlabs/gauntlet) | Independent judges for pre-delivery artifacts: run a changeset or PR through eleven lanes — security, code, tests, architecture, infra, operability, dependencies, accessibility, frontend, UX, docs — each grading against a standard it owns and returning findings with anchors and grounds. It never approves, never fixes, never decides what ships. | `/plugin install gauntlet@jacquardlabs-marketplace` |
| [exorcist](https://github.com/jacquardlabs/exorcist) | Aggressive simplification for LLM-generated code: a standing ward imported via CLAUDE.md, `/exorcist:exorcise` to audit a changeset against its stated intent and revert what does not belong, and `/exorcist:seance` to survey a whole repository — pattern contention, dead code, duplicated helpers, wrapper strata — into a register you approve before anything is applied. Scored in concepts removed, never lines. | `/plugin install exorcist@jacquardlabs-marketplace` |
| [viva](https://github.com/jacquardlabs/viva) | Section-by-section markdown review: Claude presents, you drill every section, Claude defends and revises until it all holds up. | `/plugin install viva@jacquardlabs-marketplace` |
| [voice-suite](https://github.com/jacquardlabs/voice-suite) | Voice workflows: 7 skills that mine your writing for a voice profile, then generate docs, emails, chat messages, and rewrites in your voice. | `/plugin install voice-suite@jacquardlabs-marketplace` |

Each plugin points to its source repo at a pinned release SHA. Install through this marketplace — the source repos hold plugins, not catalogs, so `/plugin marketplace add jacquardlabs/<repo>` has nothing to read and fails with "Marketplace file not found."

## How plugins get listed

- **Nightly pin updates.** `.github/workflows/update-pins.yml` runs on a schedule (02:00 UTC) and pushes any new release SHA for each listed plugin straight to `main`, bypassing the PR-required ruleset via an org-admin token.
- **Manual onboarding, deliberately.** Plugins are added by hand: edit `.claude-plugin/marketplace.json` with a source repo URL and pinned SHA, add the repo to `update-pins.yml`'s `REPOS` array, update the table above, and open a PR. There is no automated discovery — this shelf is curated, and adding to it is a decision, not a default.

## Contributing

> TODO: no CONTRIBUTING.md found. If there's a preferred process beyond "open a PR against `.claude-plugin/marketplace.json`," document it here.

## License

> TODO: no LICENSE file found in the repo root. Add one and state it here.
