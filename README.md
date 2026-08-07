# WP Security Audit — Free Claude Skill by Macronimous

A Claude Skill that runs a structured security audit on any WordPress site: plugin/theme CVE cross-checking, wp-config and permission hardening, malware detection, and triaged code review — with a prioritized Critical/Important/Polish findings report.

## Install

**Claude.ai / Claude Desktop:** Settings → Capabilities → Skills → upload this folder (or the .zip).

**Claude Code:** copy the `wp-security-audit/` folder into `.claude/skills/` in your project, or `~/.claude/skills/` for all projects.

## Use

Just ask naturally:
- "Audit the security of mysite.com" (remote mode — URL only)
- "Run a WordPress security audit" from a Claude Code session with SSH access to the site (full mode)
- "Check these plugins for vulnerabilities" + a plugin list

Full mode (SSH + WP-CLI) gives complete coverage. Remote mode covers the externally visible surface only.

## What it checks

Core integrity, plugin & theme CVEs (via WPScan/Patchstack/Wordfence advisories), abandoned & bundled plugins, wp-config hardening, file permissions, exposed backups/dumps, rogue admin users, malware signatures, risky code patterns in high-risk plugins, and external surface (xmlrpc, user enumeration, headers).

Read-only. No exploit attempts, no brute force.

---

Free to use and share. Built by [Macronimous Web Solutions](https://www.macronimous.com) — WordPress and web development since 2002. Need the findings fixed? info@macronimous.com
