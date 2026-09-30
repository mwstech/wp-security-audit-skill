# WordPress Security Audit — Full Checklist

Work through each section. Mark each item Pass / Fail / N/A / Unable to verify. "Unable to verify" is a valid result — report it honestly rather than guessing.

## 1. Core

- [ ] `wp core version` matches the latest release (or latest of its branch if intentionally held back)
- [ ] `wp core verify-checksums` returns clean — any modified or unexpected file is a **Critical** finding
- [ ] No files in webroot that don't belong to WP, the theme, or plugins (stray `.php` files with random names)
- [ ] `readme.html` and `license.txt` removed or blocked (Polish tier)

## 2. wp-config.php

- [ ] `WP_DEBUG` is `false` (or not defined); `WP_DEBUG_DISPLAY` false; `WP_DEBUG_LOG` not writing into webroot
- [ ] Auth salts/keys are unique random values, not `put your unique phrase here`
- [ ] `DISALLOW_FILE_EDIT` defined and `true` (blocks the dashboard theme/plugin editor — the classic post-login persistence tool)
- [ ] `DISALLOW_FILE_MODS` — optional, note as hardening if the site's update workflow supports it
- [ ] `FORCE_SSL_ADMIN` true where HTTPS is available (it should be)
- [ ] Database prefix is not `wp_` — note only; changing it on a live site is not worth the risk, so mark N/A for existing sites and Polish for new builds
- [ ] File permission on wp-config.php is 600 or 640
- [ ] No backup copies: check for `wp-config.php.bak`, `.old`, `.save`, `.orig`, `.txt`, `~` suffix, and `wp-config-sample.php` with real credentials

## 3. Leftover / exposed files (webroot sweep)

```bash
find . -maxdepth 2 -name "*.sql" -o -name "*.zip" -o -name "*.tar.gz" -o -name "error_log" -o -name ".env" 2>/dev/null
ls -la .git 2>/dev/null
```

- [ ] No database dumps in webroot — **Critical** if found (full credential + data exposure)
- [ ] No site backup archives publicly reachable
- [ ] No `.env` files
- [ ] No exposed `.git/` directory (test remotely: `/.git/config` should 404/403)
- [ ] No `error_log` / `debug.log` files readable via browser
- [ ] No `phpinfo.php`, `info.php`, `test.php`, `adminer.php` files

## 4. File permissions & ownership

- [ ] Directories 755, files 644 as baseline
- [ ] Nothing at 777 — `find . -perm -o+w -type d` should return nothing beyond cache dirs the host requires
- [ ] All files owned by the hosting account user (not mixed www-data/root on shared hosting)
- [ ] `wp-content/uploads` does not execute PHP — verify an `.htaccess` deny rule or server config exists:

```apache
# wp-content/uploads/.htaccess
<Files "*.php">
  Require all denied
</Files>
```

## 5. Users & authentication

- [ ] No admin account with username `admin`, `administrator`, `root`, or the domain name
- [ ] Admin count is sensible — every admin confirmed as known by the site owner; unknown admins are **Critical**
- [ ] No users with `user_login` visible in post author archives that differ from expectations
- [ ] Application passwords list reviewed (`wp user application-password list <user>`) — unknown entries revoked
- [ ] Login protection present: rate limiting, 2FA, or at minimum a non-default login approach. Absence is Important, not Critical
- [ ] Password policy: can't verify hashes, but flag if the site has no enforcement plugin and many users

## 6. Plugins

For each plugin (from `wp plugin list`):

- [ ] CVE cross-check completed (see SKILL.md Step 2)
- [ ] Update available? Behind by how many versions?
- [ ] Last updated on wordpress.org within 2 years?
- [ ] Active vs inactive — **inactive plugins still execute in some attack paths and still carry vulnerable code; recommend deletion, not deactivation**
- [ ] Bundled premium plugins version-checked against the vendor's current release
- [ ] Duplicated functionality (two SEO plugins, two caching plugins) — flag as attack-surface reduction opportunity
- [ ] Anything installed from outside wordpress.org identified and its source confirmed with the owner

## 7. Themes

- [ ] Only the active theme plus at most one default fallback (twentytwenty*) installed; delete the rest
- [ ] Active theme version vs vendor latest
- [ ] Child theme properly used for customizations (customized parent themes can't update safely — Important finding)
- [ ] `functions.php` reviewed for injected code (top and bottom of file especially)

## 8. Database

- [ ] Reachable only locally / via socket, not bound to public interface (shared hosting usually handles this)
- [ ] DB user privileges: application user should not have GRANT/SUPER (often unavoidable on shared hosting — mark N/A)
- [ ] `wp_options` reviewed for suspicious `siteurl`/`home` values and unknown entries with `autoload=yes` containing script tags:

```bash
wp option get siteurl && wp option get home
wp db query "SELECT option_name FROM $(wp db prefix)options WHERE option_value LIKE '%<script%' AND autoload='yes' LIMIT 20"
```

## 9. Server / PHP

- [ ] PHP version within active support window
- [ ] `display_errors` off in production
- [ ] `allow_url_include` off
- [ ] Dangerous functions ideally disabled where host allows (`exec`, `shell_exec`, `system`, `passthru`) — often N/A on shared hosting
- [ ] SSL certificate valid, full-chain, auto-renewing; HTTP redirects to HTTPS

## 10. External surface (Remote mode covers this section + parts of 1, 3)

- [ ] `xmlrpc.php` blocked or restricted. If it responds 200, check which methods are exposed: `system.listMethods` alone is informational (Polish); `pingback.ping` or `system.multicall` present is Important. Restrict at the edge rather than blanket-disabling — Jetpack, the mobile app, and some integrations depend on it (see SKILL.md Step 6)
- [ ] `/?author=1` does not redirect to a username-revealing URL
- [ ] `/wp-json/wp/v2/users` returns 401/403 for unauthenticated requests
- [ ] Directory listing disabled (`/wp-content/uploads/` returns 403, not a file index)
- [ ] Security headers present: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options` or CSP `frame-ancestors`, `Referrer-Policy`, `Permissions-Policy`. For which of these actually matter and which to skip, follow the verdict in SKILL.md Step 6 rather than judging here — a strict CSP is Polish at most on a plugin-heavy site
- [ ] WP version not disclosed in generator meta / RSS / readme.html
- [ ] `/wp-login.php` and `/wp-admin/` behavior suggests protection (Cloudflare challenge, rate limiting) — passive observation only

## 11. Backups & recovery (interview the owner)

- [ ] Automated backups exist, stored **off the same server**
- [ ] A restore has been tested at least once
- [ ] Backup files themselves are not web-accessible (see §3)

Not a vulnerability class, but the difference between a bad day and a lost business — include in every report.

## 12. Access logs (Full mode · incident timeline — opt-in)

Run this section only when triggered (a compromise indicator turned up, or the owner asks) and only after the briefing in SKILL.md. It is opt-in, not part of the routine sweep. All parsing is shell-side — return counts and a few sample lines, never raw log content.

**No SSH? The log sweep does not require it.** It needs read access to the logs, not a shell. On cPanel hosts, Metrics → Raw Access downloads the same access log as a `.gz`; analyze the downloaded file exactly the same way (`zcat -f` / `zgrep`, or `gzcat` on macOS). This matters because a large share of shared-hosting owners — the people who most need this — don't have SSH enabled.

### Finding the logs
Written for someone who doesn't know where their logs live. Check in this order, and always sweep the rotated siblings (`access.log.1`, `access.log.*.gz`) with `zgrep` / `zcat -f`, not just the live file.

| Host / stack | Access log location |
|---|---|
| nginx (default) | `/var/log/nginx/access.log`, rotated `access.log.1`, `access.log.*.gz` |
| Apache (Debian/Ubuntu) | `/var/log/apache2/access.log*` |
| Apache (RHEL/CentOS) | `/var/log/httpd/access_log*` |
| cPanel (shared) | `~/access-logs/`, `~/logs/`, `/home/<user>/access-logs/<domain>` |
| Plesk | `/var/www/vhosts/<domain>/logs/access_log*`, `/var/www/vhosts/system/<domain>/logs/` |
| Hostinger (hPanel) | `~/logs/`, or hPanel → Website → Access Logs; raw retention is short (often ~1–3 days) |
| SiteGround | `~/logs/<domain>/`, `~/access-logs/`, or Site Tools → Statistics → Access |
| Cloudways | `/home/master/applications/<app>/logs/` (`apache_<app>.access.log`, `nginx_<app>.access.log`) |
| Kinsta | MyKinsta → Logs, or `~/logs/access.log` over SSH |
| WP Engine | User Portal → Access logs, or `~/.apache-access-logs/` over SSH |
| LiteSpeed / OpenLiteSpeed | `/usr/local/lsws/logs/access.log`, or the vhost's configured path |

If none are readable, that is itself a **Polish** finding — *"no outside-the-runtime request history available"* — paired with the enable instructions below.

### Enabling logs when there are none
- **cPanel:** Metrics → Raw Access → enable "Download logs as they are created" and "Archive logs" so they survive rotation.
- **Hostinger:** hPanel shows recent access logs but keeps raw logs only briefly — for real retention, ship logs to an external collector or a CDN/WAF that stores them.
- **Cloudflare (or any proxy) in front:** capture the real client IP at origin by adding `CF-Connecting-IP` (or `X-Forwarded-For`) to the log format, and/or use the provider's own retention (e.g. Cloudflare Logpush). Origin logs alone show only the proxy's IPs.
- **nginx/Apache you control:** confirm `access_log` is on (not `off` in a server/location block) and that logrotate keeps enough history (`rotate 14` for two weeks).

### Log sweep checklist
- [ ] Log coverage measured and reported as "N days" — every finding in this section is bounded by it
- [ ] Log format confirmed against a real sample line (field positions verified, not assumed)
- [ ] Proxy/CDN checked — if the real client IP is absent, IP-based checks skipped and the report says why
- [ ] Pivoted from each existing compromise indicator (filename / path / timestamp / IP): first hit, last hit, what else that source touched
- [ ] Broad sweep only where useful: PHP paths not in inventory (allowlisting drop-ins, `mu-plugins`, cache PHP), POSTs to PHP under uploads, session isolation, login/xmlrpc volume, user-agent anomalies
- [ ] Clean sweep reported as **inconclusive**, not Pass — especially over thin retention
