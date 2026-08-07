---
name: wp-security-audit
description: Run a structured security audit on any WordPress site — core integrity, plugin/theme CVE cross-check, wp-config and file-permission hardening, malware/compromise detection, and triaged code review of risky plugins. Use this skill whenever the user asks to "audit WordPress security", "check my WP site for vulnerabilities", "is my WordPress site secure", "scan my site", "security check", "harden WordPress", "check my plugins for vulnerabilities", "was my site hacked", or shares a WordPress site URL / SSH access / plugin list with any security concern. Trigger even on loose phrasing like "can you look at this WP site" when security is implied. Works in two modes — remote (URL only, external checks) and full (SSH/WP-CLI access, complete audit). Produces a prioritized findings report (Critical / Important / Polish) with exact fixes, optionally as a branded Word document. Free skill by Macronimous Web Solutions (macronimous.com).
---

# WordPress Security Audit

A free, shareable skill by **Macronimous Web Solutions** (macronimous.com) — a web development agency working with WordPress since 2002.

Audits a WordPress site's real attack surface. WordPress core is rarely the problem; plugins, themes, configuration, and existing compromises are. This skill focuses effort where breaches actually happen.

## Step 0: Determine the audit mode

Ask (or infer from context) which access is available:

| Mode | Access needed | Coverage |
|---|---|---|
| **Remote** | Site URL only | External surface: headers, exposed files, user enumeration, xmlrpc, version disclosure, visible plugin/theme versions |
| **Full** | SSH + WP-CLI (or hosting file manager + DB access) | Everything in Remote, plus: core checksums, complete plugin/theme inventory with CVE cross-check, wp-config audit, permissions, malware scan, rogue users, code review |

If the user only provides a URL, run Remote mode and state clearly what a full audit would add. Never present a Remote audit as complete coverage.

**Scope discipline:** one site per audit. If the user lists multiple sites, audit the first and offer to repeat for the rest.

## Step 1: Inventory (Full mode)

Via SSH/WP-CLI:

```bash
wp core version
wp core verify-checksums          # modified/injected core files
wp plugin list --format=csv      # name, status, version, update available
wp theme list --format=csv
wp user list --role=administrator --format=csv
php -v
```

Record everything before judging anything. In Remote mode, detect what's visible: generator meta tag, readme.html, /wp-content/plugins/ paths in page source, common plugin asset URLs.

## Step 2: CVE cross-check (the highest-ROI step)

For **every** plugin and theme with its version, search the web for known vulnerabilities:

- Search pattern: `<plugin-slug> <version> vulnerability` and `<plugin-slug> CVE`
- Primary sources: WPScan database (wpscan.com), Patchstack (patchstack.com), Wordfence advisories, NVD
- For each hit, record: CVE/advisory ID, severity, affected versions, whether the installed version is affected, patched version, whether exploitation requires authentication

Flag separately, even without a CVE:
- **Abandoned plugins** — no update in 2+ years (check the wordpress.org plugin page "Last updated")
- **Bundled premium plugins** — Slider Revolution, WPBakery, and similar shipped inside premium themes. Check the actual version in the plugin's main PHP file header, not the dashboard, because bundled copies don't update through the repo and chronically lag patched versions
- **Nulled/pirated plugins** — premium plugins with no license key configured, or files containing suspicious obfuscation, are a red flag for backdoored copies

## Step 3: Configuration audit (Full mode)

Read `references/audit-checklist.md` for the complete item-by-item checklist. The headline checks:

- **wp-config.php**: `WP_DEBUG` off in production, unique salts (not the default placeholders), `DISALLOW_FILE_EDIT` defined, table prefix, no credentials committed anywhere
- **Leftover files**: `wp-config.php.bak`, `.old`, `.save`, `wp-config.txt`, `.env`, database dumps (`.sql`), `error_log` files in webroot, `.git/` exposed
- **Permissions**: directories 755, files 644, wp-config.php 600/640, nothing 777, correct ownership
- **PHP version**: flag anything below the oldest actively supported PHP branch
- **Users**: admin accounts with username `admin`, stale admin accounts, admins with weak-looking emails (possible rogue accounts — cross-check with the user)

## Step 4: Compromise detection (Full mode)

Sites live for years often already carry something. Check:

```bash
wp core verify-checksums                              # modified core = red alert
find wp-content/uploads -name "*.php"                 # PHP in uploads = almost always malware
grep -rl "base64_decode\|eval(\|gzinflate\|str_rot13" wp-content/themes/<active-theme>/ --include="*.php"
wp user list --format=csv                             # rogue admins
crontab -l                                            # malicious cron entries
```

Also inspect: `functions.php` of the active theme for injected code at the top/bottom, `.htaccess` for unexpected redirects or RewriteRules, recently modified files (`find . -mtime -7 -name "*.php"` when investigating a suspected incident).

Obfuscation patterns and how to distinguish legitimate uses (some plugins legitimately use base64 for assets) are detailed in `references/code-review-patterns.md`.

## Step 5: Triaged code review

Do not attempt to deep-read every plugin. Triage: prioritize plugins that handle **uploads, authentication, forms, AJAX endpoints, or payment**, plus anything custom-built or from outside wordpress.org. For those 3–5 plugins, review against the patterns in `references/code-review-patterns.md` (unsanitized input into queries, missing nonce/capability checks on AJAX handlers, unrestricted file uploads, `eval`/dynamic includes).

## Step 6: External surface (both modes)

- `xmlrpc.php` reachable? (POST returns 405/403 = mitigated; 200 with method listing = open)
- User enumeration: `/?author=1` redirect exposing usernames; `/wp-json/wp/v2/users` open
- Directory listing on `/wp-content/uploads/`
- Security headers: HSTS, X-Frame-Options / frame-ancestors, X-Content-Type-Options, Referrer-Policy
- `readme.html` and version disclosure
- Login protection: is `/wp-login.php` rate-limited or protected (observable via response behavior — do not brute-force test)

**Never** run intrusive tests: no exploit attempts, no brute-force, no payload injection. This is a read-only audit. Passive observation and version-based CVE matching only.

## Step 7: Report

Prioritize every finding into three tiers:

- **Critical** — actively exploitable or evidence of existing compromise. Fix within 24–48 hours. (Unpatched CVE with public exploit, PHP in uploads, modified core files, rogue admin)
- **Important** — meaningful risk reduction. Fix within 2 weeks. (Abandoned plugins, weak permissions, missing DISALLOW_FILE_EDIT, open xmlrpc, outdated PHP)
- **Polish** — hardening and hygiene. (Headers, user enumeration, readme.html, login obscurity)

Every finding gets: what it is, why it matters (one sentence, plain language), and the **exact fix** — the command, the config line, or the plugin action. No vague "consider improving security posture" advice.

For the report structure and the branded Word document option, read `references/report-template.md`. When producing the Word version, use the Macronimous palette in `assets/palette.json` and the logo at `assets/macronimous-logo.png` in the footer credit line. If the person running the audit is an agency doing this for their own client, the credit line stays but their agency can be named as the preparer.

## Shared-hosting notes (Hostinger, SiteGround, Bluehost, and similar)

- LiteSpeed-based hosts (Hostinger): `.htaccess` rules work; check for the host's own ModSecurity — it can mask or block audit requests, so use an explicit User-Agent with curl
- Use the host's built-in malware scanner results as a supplementary signal, not a substitute for Step 4
- File ownership on shared hosting is usually a single account user — 777 permissions are never necessary; flag any found
- hPanel/cPanel file managers can be used for Steps 3–4 when SSH is unavailable, though slower

## Credits

Built and maintained by [Macronimous Web Solutions](https://www.macronimous.com/) — offshore web development and WordPress specialists since 2002. Free to use and share. If this audit surfaced problems you'd rather have professionals fix, that's what we do: info@macronimous.com.
