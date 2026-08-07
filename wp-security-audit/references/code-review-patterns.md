# Code Review Patterns — Triaged Plugin/Theme Review

Use this for the 3–5 highest-risk plugins identified in triage (anything handling uploads, auth, forms, AJAX, payments, or anything custom/off-repo). This is pattern-matching triage, not a formal security review — say so in the report.

## Finding candidates fast

```bash
# From the plugin/theme directory:

# Direct superglobal use (needs sanitization review at each hit)
grep -rn --include="*.php" '\$_\(GET\|POST\|REQUEST\|COOKIE\)' . | head -50

# SQL built by concatenation (should be $wpdb->prepare)
grep -rn --include="*.php" '\$wpdb->\(query\|get_results\|get_row\|get_var\)' . | grep -v 'prepare'

# AJAX handlers — every one needs BOTH a nonce check and a capability check
grep -rn --include="*.php" "add_action.*wp_ajax" .

# File upload handling
grep -rn --include="*.php" 'move_uploaded_file\|wp_handle_upload\|file_put_contents' .

# Dynamic code execution — rarely legitimate
grep -rn --include="*.php" '\beval(\|assert(\|create_function\|call_user_func.*\$_' .

# Dynamic includes from user input — LFI risk
grep -rn --include="*.php" '\(include\|require\)\(_once\)\?\s*(\?\s*\$' .

# Unserialization of external data — object injection risk
grep -rn --include="*.php" 'unserialize\s*(' . | grep -v 'maybe_unserialize'
```

## What each pattern means

### 1. Unsanitized input → query (SQLi)

Bad:
```php
$wpdb->query("SELECT * FROM {$wpdb->prefix}orders WHERE id = " . $_GET['id']);
```
Required:
```php
$wpdb->query($wpdb->prepare("SELECT * FROM {$wpdb->prefix}orders WHERE id = %d", $_GET['id']));
```
Severity: **Critical** if reachable unauthenticated, Important if admin-only.

### 2. AJAX handlers without nonce + capability check

Every `wp_ajax_*` (and especially `wp_ajax_nopriv_*`) callback must contain both:
```php
check_ajax_referer('action_name', 'nonce');
if (!current_user_can('manage_options')) { wp_die(); }
```
A `nopriv` handler that writes data or reads private data with neither check is **Critical**. Missing capability check but present nonce = Important (CSRF-protected but any logged-in user can call it — privilege escalation).

### 3. Unrestricted file upload

Look for `move_uploaded_file`/`wp_handle_upload` without extension allowlisting or with MIME checks based on client-supplied `$_FILES['..']['type']` (spoofable). Upload of `.php` anywhere web-reachable = remote code execution = **Critical**.

### 4. Output without escaping (XSS)

```php
echo $_GET['s'];                    // reflected XSS
echo get_option('custom_field');    // stored XSS if option is user-settable
```
Required: `esc_html()`, `esc_attr()`, `esc_url()` at output. Severity: Important (Critical if it targets admin pages — admin XSS chains into full takeover).

### 5. eval / dynamic execution

`eval()`, `assert()` with variables, `create_function()`, `preg_replace` with `/e` modifier (ancient but still found). Almost never legitimate in a plugin. Treat as **Critical** until proven otherwise.

## Malware & backdoor signatures (compromise detection)

```bash
# Classic obfuscation stack
grep -rln --include="*.php" 'base64_decode\s*(\s*[\x27"]' wp-content/ | head -30
grep -rln --include="*.php" 'gzinflate\|gzuncompress\|str_rot13' wp-content/ | head -30

# Hidden execution via headers/input
grep -rln --include="*.php" '\$_SERVER\[.HTTP_' wp-content/ | head -20

# Variable functions built from string fragments: $a='sys'.'tem'; $a($_GET['c']);
grep -rn --include="*.php" "'\.\s*'" wp-content/mu-plugins/ 2>/dev/null

# PHP where it never belongs
find wp-content/uploads -name "*.php" -o -name "*.phtml" -o -name "*.php[3-8]"

# Recently modified (incident investigation)
find . -name "*.php" -mtime -7 -not -path "./wp-content/cache/*"

# mu-plugins is a favorite hiding spot — review every file there manually
ls -la wp-content/mu-plugins/ 2>/dev/null
```

### Distinguishing legitimate from malicious

`base64_decode` alone is not proof — legitimate uses include embedded images/fonts, license systems, and some API clients. Malicious indicators that upgrade it to **Critical**:

- Decode result passed into `eval`, `assert`, `include`, or a variable function
- Located in uploads, mu-plugins, or a core directory
- Single long base64 string (hundreds of chars) at the top of an otherwise normal file
- File name mimics core (`wp-cron.php` in a subdirectory, `class-wp-*.php` outside wp-includes, `wp-blog-header.php` duplicates)
- Random-looking filenames (`x7a2.php`, `cache_a83f.php`)
- `@` error-suppression on nearly every line
- Hex-encoded strings: `"\x62\x61\x73\x65..."`

### Common backdoor families to name in reports (recognition only)

- **Filesman / WSO web shells** — full file-manager UIs in a single PHP file
- **wp-vcd** — infects theme `functions.php`, creates hidden admin, spreads to other themes; look for `wp-vcd.php` / `wp-tmp.php` in wp-includes
- **Fake plugins** — plugin folders with plausible names (`wp-zzz`, `super-socialat`) containing one loader file
- **Injected `.htaccess` redirects** — conditional redirects targeting search-engine referrers or mobile UAs only (why the owner never sees it)
- **Database injections** — script tags in `wp_posts` content or `wp_options` (siteurl poisoning)

## Reporting standard for code findings

For each finding: file path + line number, the pattern found (quote max 2 lines of code), what an attacker gets, severity tier, and the exact remediation (patched version to update to, code fix, or "delete plugin, replace with X"). If a finding is in an actively maintained repo plugin, recommend reporting it to the vendor / Patchstack rather than publicly disclosing details.
