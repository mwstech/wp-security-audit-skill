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
| **Remote** | Site URL only | External surface: headers, exposed files, user enumeration, xmlrpc, version disclosure — plus a CVE cross-check against plugin/theme slugs harvested from page source, with versions treated as unconfirmed leads |
| **Full** | SSH + WP-CLI (or hosting file manager + DB access) | Everything in Remote, plus: core checksums, authoritative plugin/theme inventory (so CVE matches are confirmed, not suspected), wp-config audit, permissions, malware scan, rogue users, code review |

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

Record everything before judging anything.

In Remote mode there's no WP-CLI, so the inventory comes from what the site exposes — generator meta tag, readme.html, and the asset paths in page source. Step 2 covers how to harvest and qualify that inventory.

## Step 2: CVE cross-check (both modes — the highest-ROI step)

**Both modes run this step.** In Full mode the inventory comes from `wp plugin list` and versions are authoritative. In Remote mode, build the inventory from what the site exposes:

- Harvest plugin slugs from page source — `wp-content/plugins/<slug>/` appears in every enqueued stylesheet and script URL
- Harvest theme slugs the same way from `wp-content/themes/<slug>/`
- Take version hints from `ver=` query strings on those enqueued assets

Treat every `ver=` value as **a lead to verify, not a confirmed version.** WordPress appends the version registered with the asset, which is often the plugin's version but can be the asset's own version, the WordPress core version, or a value the developer hardcoded years ago. Cross-check a suspected vulnerable version against a second signal before reporting it — a changelog date, a readme.txt at `wp-content/plugins/<slug>/readme.txt` if readable, or a fingerprint unique to the affected release. When no second signal is available, report it as *suspected version, unconfirmed* and say so in the finding.

For **every** plugin and theme with its version, search the web for known vulnerabilities:

- Search pattern: `<plugin-slug> <version> vulnerability` and `<plugin-slug> CVE`
- Primary sources: WPScan database (wpscan.com), Patchstack (patchstack.com), Wordfence advisories, NVD
- For each hit, record: CVE/advisory ID, severity, affected versions, whether the installed version is affected, patched version, whether exploitation requires authentication

Flag separately, even without a CVE:
- **Abandoned plugins** — no update in 2+ years (check the wordpress.org plugin page "Last updated")
- **Bundled premium plugins** — Slider Revolution, WPBakery, and similar shipped inside premium themes. *(Full mode only:* check the actual version in the plugin's main PHP file header, not the dashboard, because bundled copies don't update through the repo and chronically lag patched versions. That file isn't readable in Remote mode — the most you can do remotely is note the plugin's presence from its asset paths and flag it as needing version confirmation.*)*
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

When recommending removal of a rogue user, always include `--reassign`: `wp user delete <id> --reassign=<legitimate-admin-id>`. Without it, WP-CLI deletes any content the account authored along with the account — unlikely to matter for a backdoor user, but the report's fix commands must be safe to paste verbatim.

Obfuscation patterns and how to distinguish legitimate uses (some plugins legitimately use base64 for assets) are detailed in `references/code-review-patterns.md`.

If any check here turns up a compromise indicator — a rogue admin, PHP in uploads, a modified core file, an injected `.htaccess` — offer the Access Log Sweep below to date it. Logs can tell the owner *when* it started and what else the source touched. Offer; don't run it unprompted.

## Access Log Sweep / Incident Timeline (Full mode · opt-in)

Web server access logs are the fourth leg of the audit, alongside the filesystem (checksums), the database (direct queries), and the external surface (HTTP checks). They are the only leg that can **date** a breach rather than merely detect it: nginx and Apache write these logs, not PHP, so they sit outside the runtime a compromise controls. In earlier testing, a rogue-admin account was dated from database fields — a log line would have caught it the week it happened.

**Do not overstate immutability.** "Malware can't alter what was already logged" holds on shared hosting, where the site's account user can't write to `/var/log/nginx/`. It does NOT hold if an attacker has root on a VPS, and cPanel-style `~/access-logs/` sits closer to the account. Logs are harder to tamper with than the filesystem, not impossible — say exactly that in the report. Overclaiming here repeats the sin the skill criticizes plugins for.

**Full mode only.** Remote mode can't read logs — note it in the report the same way as other Full-only checks.

**This is an incident-timeline tool, not a routine step.** It is opt-in, and it pivots from a known indicator wherever possible. Do not run it in every audit.

### When to offer it
1. The user asks directly — "check my logs", "when was I hacked", "can you tell when this started".
2. The audit found a compromise indicator (rogue admin, PHP in uploads, modified core file, injected `.htaccess`). Offer, don't run: *"I found an admin account created outside your normal process. Your logs could tell you when it was created and what else that IP touched — if retention goes back far enough. Want me to look?"* Wait for a yes.
3. The user suspects a hack or reports the site behaving oddly.

### The briefing (present this, then stop and wait)
Before reading a single log line, lay out the trade in plain language:
- **What it can find** — *when* a break-in happened (not just that it did), requests to files that shouldn't exist, backdoor check-in patterns.
- **What it costs** — the slowest part of the audit; a busy site means large logs.
- **Shared-hosting caution** — heavy log scanning burns CPU and can trip per-account resource limits on budget hosts (Hostinger, SiteGround), which can throttle or suspend the site. Keep commands conservative, one file at a time.
- **What it probably won't find** — most shared hosts keep only 1–3 days of raw logs. If the suspected break-in was months ago, the answer isn't there. Say this up front; for many users it makes the wait not worth it.
- **Privacy** — logs contain visitor IP addresses, which are personal data under GDPR and similar laws. Offer masking (default on) for report output. Be honest about what masking does: full IPs are still read into the session to do the correlation; only the report output is masked. Don't call this anonymization.

Then offer three choices: **run it**, **skip it**, or **check retention first**. The retention check is one cheap command (below) that returns how many days of logs exist — often enough to decide. If retention is 2 days and the suspected compromise is older, stop there and save an hour.

### Pre-flight (before any analysis)
1. **Locate the logs.** Paths vary by host — see the table in `references/audit-checklist.md` §12.
2. **Measure retention and volume.** Oldest and newest entry, total size across rotated files. Report as *"log coverage: N days."*
3. **Detect the log format.** Combined vs common vs custom — verify field positions against a real sample line. Never assume column order.
4. **Check whether the logged IPs are real — decide this from the log, not from DNS.** A site can sit behind Cloudflare/Sucuri and *still* log real client IPs, because the host restores them (`mod_remoteip`, `CF-Connecting-IP`, `X-Forwarded-For`). So don't reason "the site has a CDN, therefore skip IP checks." Look at the actual field-1 IPs: if they're dominated by CDN ranges (Cloudflare `104.16/12`, `172.64/13`, `162.158/15`, `173.245.48/20`, and similar), the real client is hidden — run **file-path checks only**, and never report a CDN edge IP as an attacker. If they're diverse real addresses, the per-IP checks are valid even though a CDN is in front. PHP responses are never cached, so the file-path checks stay valid either way.
5. **If no logs are readable, that is itself a finding** — *"no outside-the-runtime request history available"* — with the per-host enable instructions in §12. Tier: **Polish**.

Retention / volume check (cheap — run this first if the user picks "check retention"):
```bash
LOG=/path/to/access.log          # set from the §12 table
zcat -f "$LOG"* | head -1         # oldest line (includes rotated .gz siblings)
zcat -f "$LOG" | tail -1          # newest line
du -ch "$LOG"* | tail -1          # total size across rotations
```

### Primary mode — pivot from a known indicator
Given a filename, path, timestamp, or IP from an existing finding, reconstruct the session:
- Every request to that file — timestamps, methods, response codes, source
- **First and last occurrence** — this is the breach date
- What else the same source touched in the same window
- Whether it's still being hit

```bash
# pivot on a known backdoor filename — counts + a few sample lines only, never the raw log
zgrep -h "evil-backdoor.php" "$LOG"* | awk '{print $1}' | sort | uniq -c | sort -rn | head
zgrep -h "evil-backdoor.php" "$LOG"* | sort | head -3    # first hits (breach start)
zgrep -h "evil-backdoor.php" "$LOG"* | sort | tail -3    # last hits (still active?)
```
Fast, precise, bounded. This is the default whenever a compromise indicator exists.

### Secondary mode — broad sweep
Slower and noisier; use only when there's no single indicator to pivot from. Priority order:
1. **Requests to PHP files not in the inventory — gated on the response code, not the path.** Cross-reference requested `.php` paths against the plugin/theme/core inventory from Step 1. **The status code is the discriminator.** Every WordPress site is hit constantly by scanners probing for known backdoor filenames (`wp_filemanager.php`, `radio.php`, `*_hello_world.php`, and hundreds more); those requests return `403`/`404`/`406`/`410`/`429` because the file isn't there or the WAF blocked them, and they are **noise, not findings** — at most note "the host is blocking backdoor scans, working as intended." The real signal is a **2xx (or a 500, which can mean the code ran and errored) to a PHP file not in inventory** — that is a headline finding. Even the 2xx set false-positives without care, so **allowlist** legitimate files that live outside a naive inventory: drop-ins (`advanced-cache.php`, `object-cache.php`, `db.php`), `mu-plugins`, and cache-plugin generated PHP. Also flag a **2xx to a PHP file that no longer exists on disk** — a webshell since deleted or self-deleting, which a filesystem scan can't find.
2. **POSTs to PHP inside `wp-content/uploads/`.** Near-certain compromise.
3. **Session isolation** — one IP, one PHP file, no referrer, no other page views. Classic backdoor check-in. *(Requires real client IPs — skip if proxied.)*
4. **`wp-login.php` / `xmlrpc.php` volume per IP.** Report counts only; block nothing. *(Requires real client IPs — skip if proxied.)*
5. **User-agent anomalies on PHP hits** — empty, `curl`, or `python` user-agents POSTing to PHP.

### Design constraints (apply to everything above)
- **Read-only, always.** Parse and report. Never rotate, truncate, delete, or block.
- **Shell-side parsing only.** A busy site's access log is hundreds of MB. Do all filtering and aggregation in `awk`/`grep`/`sort | uniq -c` and return counts plus a handful of sample lines. **Never read raw log content into the session** — it destroys context and adds an hour to an already-slow audit. One file at a time, hard caps on output, no unbounded scans.
- **State the limits out loud.** Report *"log coverage: N days — findings below are bounded by this."* An empty sweep over 2 days proves almost nothing, and the report must say so.
- **A clean sweep is INCONCLUSIVE, never PASS.** Same overclaiming discipline as the rest of the skill.

Tiering:
- Confirmed webshell hit, or a 200 to a PHP file not in inventory → **Critical**
- Brute-force volume, or a session-isolation pattern → **Important**
- Thin or absent log retention → **Polish** (recommend enabling/extending)

## Step 5: Triaged code review (Full mode)

*Remote mode can't read plugin source; skip to Step 6.*

Do not attempt to deep-read every plugin. Triage: prioritize plugins that handle **uploads, authentication, forms, AJAX endpoints, or payment**, plus anything custom-built or from outside wordpress.org. For those 3–5 plugins, review against the patterns in `references/code-review-patterns.md` (unsanitized input into queries, missing nonce/capability checks on AJAX handlers, unrestricted file uploads, `eval`/dynamic includes).

**Spotting custom code:** a theme or plugin slug that matches nothing on wordpress.org — often a short internal name like `mysite`, `client-theme`, or an agency's initials — is custom-built. Custom code has never been reviewed by anyone outside the shop that wrote it and carries no CVE history to check, so absence of known vulnerabilities means nothing. Review it; don't skip it because the search came back empty.

## Step 6: External surface (both modes)

- **`xmlrpc.php`** — a POST returning 405/403 means it's mitigated. A 200 is not automatically a finding; what matters is *which methods are exposed*. `system.listMethods` returning a method list is informational only. The risk sits in two specific methods: **`pingback.ping`**, which lets the site be used as a reflector in DDoS amplification and for port scanning behind firewalls, and **`system.multicall`**, which lets an attacker batch hundreds of login attempts into a single HTTP request and turns rate limiting on `/wp-login.php` into theater. Report accordingly: method disclosure alone is Polish; either of those two present is Important.
  **Fix guidance:** block or restrict at the edge (Cloudflare rule, host firewall, or server config) rather than telling the owner to "disable xmlrpc." Jetpack, the WordPress mobile app, and some publishing and remote-management integrations still depend on it — a blanket disable breaks working setups and gets reverted. If the site uses none of those, disabling is fine and simplest; establish that first.
- User enumeration: `/?author=1` redirect exposing usernames; `/wp-json/wp/v2/users` open
- Directory listing on `/wp-content/uploads/`
- **Security headers** — if the `cloudflare-security-headers` skill is available in this environment, defer to its verdict table rather than restating it here, so the two don't drift apart. Without it, the short version: HSTS, X-Frame-Options (or CSP `frame-ancestors`), X-Content-Type-Options, Referrer-Policy, and Permissions-Policy are worth setting on any site. A strict Content-Security-Policy is generally not worth the maintenance burden on a plugin-heavy marketing or content site — report its absence as Polish, never Critical.
- `readme.html` and version disclosure
- Login protection: is `/wp-login.php` rate-limited or protected (observable via response behavior — do not brute-force test)

**Never** run intrusive tests: no exploit attempts, no brute-force, no payload injection. This is a read-only audit. Passive observation and version-based CVE matching only.

## Step 7: Report (both modes)

Prioritize every finding into three tiers:

- **Critical** — actively exploitable or evidence of existing compromise. Fix within 24–48 hours. (Unpatched CVE with public exploit, PHP in uploads, modified core files, rogue admin)
- **Important** — meaningful risk reduction. Fix within 2 weeks. (Abandoned plugins, weak permissions, missing DISALLOW_FILE_EDIT, `pingback.ping` or `system.multicall` exposed on xmlrpc, outdated PHP)
- **Polish** — hardening and hygiene. (Missing headers, user enumeration, readme.html, xmlrpc method disclosure alone, login obscurity)

A Remote-mode CVE match built on an unconfirmed `ver=` string sits one tier below where it would land if confirmed, and the finding must say the version is unverified. Confirm before escalating.

Every finding gets: what it is, why it matters (one sentence, plain language), and the **exact fix** — the command, the config line, or the plugin action. No vague "consider improving security posture" advice.

Write the report in American English (neutralized, not neutralised), and address every recommendation to the site owner — even when the finding concerns custom code, say what the owner should do today, not what the developer should change in the next version.

For the report structure and the branded Word document option, read `references/report-template.md`. When producing the Word version, use the Macronimous palette in `assets/palette.json` and the logo at `assets/macronimous-logo.png` in the footer credit line. If the person running the audit is an agency doing this for their own client, the credit line stays but their agency can be named as the preparer.

## Shared-hosting notes (Hostinger, SiteGround, Bluehost, and similar)

- LiteSpeed-based hosts (Hostinger): `.htaccess` rules work; check for the host's own ModSecurity — it can mask or block audit requests, so use an explicit User-Agent with curl
- Use the host's built-in malware scanner results as a supplementary signal, not a substitute for Step 4
- File ownership on shared hosting is usually a single account user — 777 permissions are never necessary; flag any found
- hPanel/cPanel file managers can be used for Steps 3–4 when SSH is unavailable, though slower

## Credits

Built and maintained by [Macronimous Web Solutions](https://www.macronimous.com/) — offshore web development and WordPress specialists since 2002. Free to use and share. If this audit surfaced problems you'd rather have professionals fix, that's what we do: info@macronimous.com.
