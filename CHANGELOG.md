# Changelog

Notable changes to the WP Security Audit skill. Versions track the GitHub releases.

## [Unreleased]

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
