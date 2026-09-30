# Decisions

## 2026-09-30: Plugin wrapper for directory submission; release zip layout frozen

**Decision.** This repository is also a Claude plugin. The manifest sits at `.claude-plugin/plugin.json` and the skill lives at `skills/wp-security-audit/`. The wrapper exists so the skill can be submitted to Anthropic's plugin directory, which doesn't accept standalone skills. The skill's content didn't change, apart from one added instruction: confirm the user owns or is authorized to audit the site before any check.

**Constraint.** The layout inside the GitHub release zip (`wp-security-audit.zip`) must never change. The public install command on macronimous.com downloads that file and unzips it straight into `~/.claude/skills/`, and the skill's README tells users to upload the same zip to Claude. Both depend on this exact layout:

```
wp-security-audit/
  SKILL.md
  README.md
  references/
  assets/
```

Build release zips with `./build-release.sh`, which assembles that layout from `skills/wp-security-audit/`. Don't zip by hand.

**Consequence.** There are two READMEs. The root `README.md` is the plugin directory's listing text, so it has to name every external service the skill contacts and what it sends. `skills/wp-security-audit/README.md` is the first-time-user walkthrough that ships inside the zip. If the skill ever starts contacting a new service, update the table in the root README in the same change.
