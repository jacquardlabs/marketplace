# Jacquard Labs Marketplace

Skill plugins for [Claude Code](https://claude.ai/code) from [Jacquard Labs](https://github.com/jacquardlabs).

## Add this marketplace

```bash
/plugin marketplace add jacquardlabs/marketplace
```

Then browse available plugins with `/plugin discover` or install directly:

```bash
/plugin install gg@jacquardlabs-marketplace
/plugin install studious@jacquardlabs-marketplace
/plugin install viva@jacquardlabs-marketplace
/plugin install study-skills@jacquardlabs-marketplace
/plugin install voice-suite@jacquardlabs-marketplace
/plugin install dustjacket@jacquardlabs-marketplace
```

---

## Plugins

### gg

Goals, guidelines, and gates: inner-loop verification for Claude Code. Contracts at every handoff: spec → decompose → build → gates → evidence.

```bash
/plugin install gg@jacquardlabs-marketplace
```

→ [jacquardlabs/gg](https://github.com/jacquardlabs/gg)

---

### studious

A product-judgment workflow: quality gates, periodic health reviews, and pre-merge audits that examine each piece of work — whether to build it, whether the design serves users, and whether the result holds up.

```bash
/plugin install studious@jacquardlabs-marketplace
```

→ [jacquardlabs/studious](https://github.com/jacquardlabs/studious)

---

### viva

Section-by-section markdown review: Claude presents, you drill every section, Claude defends and revises until it all holds up.

```bash
/plugin install viva@jacquardlabs-marketplace
```

→ [jacquardlabs/viva](https://github.com/jacquardlabs/viva)

---

### study-skills

Study workflow, 8 composable skills: flashcard decks, paper reader, concept checks, connection mapper, practice quizzes, and more.

```bash
/plugin install study-skills@jacquardlabs-marketplace
```

→ [jacquardlabs/study-skills](https://github.com/jacquardlabs/study-skills)

---

### voice-suite

Voice workflows: 7 skills that mine your writing for a voice profile, then generate docs, emails, chat messages, and rewrites in your voice.

```bash
/plugin install voice-suite@jacquardlabs-marketplace
```

→ [jacquardlabs/voice-suite](https://github.com/jacquardlabs/voice-suite)

---

### dustjacket

Restyle, generate, and drift-check READMEs in their repo type's house style and a chosen voice — without fabricating anything.

```bash
/plugin install dustjacket@jacquardlabs-marketplace
```

→ [jacquardlabs/dustjacket](https://github.com/jacquardlabs/dustjacket)

---

## How it works

Each plugin points to its source repo at a pinned release SHA. A nightly GitHub Actions workflow updates pins automatically when new releases are published.

To install a plugin directly from its source repo:

```bash
/plugin marketplace add jacquardlabs/gg
/plugin install gg@gg
```
