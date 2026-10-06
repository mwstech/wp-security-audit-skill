# WP Security Audit

A Claude plugin that audits a live WordPress site for security problems: plugins and themes with published vulnerabilities, weak configuration, loose file permissions, and signs the site has already been broken into. It works from outside WordPress on purpose. A security plugin runs inside the same PHP an attacker controls after a break-in, so a hacked site can hand it clean results. This skill checks the site over plain HTTP and, if you give it SSH, at the shell, where WordPress can't interfere.

You get a report sorted into Critical, Important, and Polish, with the exact command or setting that fixes each finding. It also lists what passed, because a report that's all failures is just fear-selling.

Built by Macronimous Web Solutions, who've maintained WordPress sites for clients since 2002. MIT licensed.

## Two modes

**Remote** needs only the site's URL. It checks what anyone on the internet can already see: exposed files, version disclosure, username leaks, xmlrpc.php, security headers, and the plugin and theme names in the page source. Versions read this way are treated as leads, and the report says so.

**Full** needs SSH access with WP-CLI, using credentials you provide. On top of the Remote checks, it verifies WordPress core files against the official checksums, lists every plugin and theme with its real installed version, reviews wp-config.php and file permissions, looks for malware and admin accounts nobody created on purpose, and reads the code of the riskiest plugins. If you ask (and your host keeps enough history), it can also read the web server's access logs to work out when a break-in started.

The skill asks which access you have and tells you which mode it ran. A Remote-only audit is never presented as complete.

## Read-only

It doesn't change anything on your site. No exploit attempts, no brute-force logins, no payloads, no file edits, no deletions. Fixes go into the report for you to apply yourself (or to hand to Claude Code in the same conversation, if you'd rather it did the typing).

Before it runs a single check, it asks you to confirm you own the site or are authorized to audit it. If you say no, it stops there.

## What it contacts, and what it sends

| Service | Mode | What it sends |
|---|---|---|
| Your website | Remote and Full | Ordinary HTTP requests to public URLs on your site, such as the home page, `readme.html`, `xmlrpc.php`, `/wp-json/wp/v2/users`, and `/?author=1`. |
| Your server, over SSH | Full | Read-only commands, run with the SSH credentials you supply: `wp core version`, `wp core verify-checksums`, `wp plugin list`, `wp theme list`, `wp user list`, `wp option get`, a `wp db query` limited to SELECT, `php -v`, `find`, `grep`, `crontab -l`, and, only if you opt in to the log check, `zcat`, `zgrep`, and `awk` over the access logs. |
| api.wordpress.org | Full | Sent by WP-CLI from your server, not by Claude: your WordPress version and locale (to download the official core checksums), and your installed plugin and theme slugs with their versions (WP-CLI's standard update check). |
| Claude's web search, reading WPScan, Patchstack, Wordfence advisories, the NVD, and wordpress.org plugin pages | Remote and Full | Search queries built from plugin or theme names and version numbers, for example `contact-form-7 5.3.1 vulnerability`. The skill's search pattern doesn't include your site's address. |

That's the complete list as of version 1.2.0. If a later version contacts anything new, it gets added to this table.

## Privacy

The skill runs inside your own Claude account. What it reads, including command output and anything you paste (SSH credentials included), stays in that conversation and is handled under your agreement with Anthropic. Macronimous receives no data: no telemetry, no analytics, no call home, and no copy of your report. The only trace of us is the credit line and logo in the generated report, and both ship inside the plugin.

One thing worth knowing if you use the log check: access logs contain visitors' IP addresses, which count as personal data under GDPR and similar laws. The report masks them by default. That masking covers the report only. The full addresses are still read during the analysis, so treat the conversation accordingly.

## What it can't do

It can't find zero-days. It matches your versions against published advisories, so a flaw nobody has disclosed yet is invisible to it (as it is to every version-based scanner, including the paid ones). Matching by version also means a vendor's back-ported patch can show up as a false positive. It isn't a penetration test. And a clean access-log check only covers the days your host kept, which on shared hosting is often one to three.

## Install

As a plugin, install it from Claude's plugin directory. As a standalone skill, download `wp-security-audit.zip` from the [Releases page](https://github.com/mwstech/wp-security-audit-skill/releases), then upload it in Claude under Settings > Capabilities > Skills > Upload skill, or unzip it into `~/.claude/skills/`. Skills need a paid Claude plan, and Full mode needs Claude Code (in the browser it can run the Remote checks only).

The step-by-step walkthrough for first-time users is in [skills/wp-security-audit/README.md](skills/wp-security-audit/README.md).
