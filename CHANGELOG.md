# Changelog

Notable changes to the WP Security Audit skill. Versions track the GitHub releases.

## [1.2.0] - 2026-10-06

### Added
- Packaged as a Claude plugin for submission to Anthropic's plugin directory. The manifest
  is at `.claude-plugin/plugin.json`; the skill moved to `skills/wp-security-audit/`. The
  release zip layout is unchanged, and `build-release.sh` now builds it reproducibly.
- The skill now asks the user to confirm they own the site or are authorized to audit it,
  and declines if they say no.
- Root `README.md` written as the directory listing: both modes, every external service
  the skill contacts and what it sends, and a Privacy section.

### Fixed
- The walkthrough's Claude Code install command now downloads the latest release
  instead of a link pinned to v1.0.

## [1.1] - 2026-08-14

### Added
- **Access Log Sweep / Incident Timeline** (Full mode, opt-in). Pivots from a known
  compromise indicator to date a breach from web-server access logs, plus a bounded
  broad sweep for webshell hits, POSTs to PHP under `uploads/`, session-isolation
  patterns, and login/xmlrpc volume. Includes an upfront briefing (cost, retention,
  privacy), proxy/CDN detection so origin logs aren't misread, host-path lookup and
  enable-logs guidance in `references/audit-checklist.md` §12, and report wording that
  keeps a clean sweep inconclusive rather than Pass. Credit: community feedback on the
  launch post.

## [1.0] - 2026-08-07

- Initial public release.
