# Jacquard Labs Marketplace

Jacquard Labs skill plugins for [Claude Code](https://claude.ai/code): quality gates and build execution, markdown review, study tools, voice workflows, and README styling.

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
| [viva](https://github.com/jacquardlabs/viva) | Section-by-section markdown review: Claude presents, you drill every section, Claude defends and revises until it all holds up. | `/plugin install viva@jacquardlabs-marketplace` |
| [study-skills](https://github.com/jacquardlabs/study-skills) | Study workflow, 8 composable skills: flashcard decks, paper reader, concept checks, connection mapper, practice quizzes, and more. | `/plugin install study-skills@jacquardlabs-marketplace` |
| [voice-suite](https://github.com/jacquardlabs/voice-suite) | Voice workflows: 7 skills that mine your writing for a voice profile, then generate docs, emails, chat messages, and rewrites in your voice. | `/plugin install voice-suite@jacquardlabs-marketplace` |
| [dustjacket](https://github.com/jacquardlabs/dustjacket) | Restyle, generate, and drift-check READMEs in their repo type's house style and a chosen voice — without fabricating anything. | `/plugin install dustjacket@jacquardlabs-marketplace` |

Each plugin points to its source repo at a pinned release SHA. Install through this marketplace — the source repos hold plugins, not catalogs, so `/plugin marketplace add jacquardlabs/<repo>` has nothing to read and fails with "Marketplace file not found."

## How plugins get listed

- **Nightly pin updates.** `.github/workflows/update-pins.yml` runs on a schedule (02:00 UTC) and pushes any new release SHA for each listed plugin straight to `main`, bypassing the PR-required ruleset via an org-admin token.
- **Manual onboarding.** Plugins are added by editing `.claude-plugin/marketplace.json` with a source repo URL and pinned SHA, then opening a PR.
- **Automated onboarding.** `.github/workflows/onboard-plugins.yml` (manually dispatched, dry-run by default) scans jacquardlabs repos for a `.claude-plugin/plugin.json` not yet listed here, and opens a PR per unlisted repo with a release — adding it to both `marketplace.json` and `update-pins.yml`'s `REPOS` array. See `.github/scripts/onboard-plugins.sh` for the full discovery and PR logic.

## Contributing

> TODO: no CONTRIBUTING.md found. If there's a preferred process beyond "open a PR against `.claude-plugin/marketplace.json`," document it here.

## License

> TODO: no LICENSE file found in the repo root. Add one and state it here.
