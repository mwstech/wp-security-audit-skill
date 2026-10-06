# WP Security Audit — a free Claude skill

Checks a WordPress site for security problems: plugins with known vulnerabilities, malware, weak settings, and signs the site has already been hacked. You get a list of what's wrong, sorted by urgency, with the exact fix for each item.

It's read-only. It looks, it doesn't touch. Safe to run on a live site.

Free, MIT licensed, built by [Macronimous](https://www.macronimous.com) — we've been doing WordPress since 2002.

---

## What you need before you start

**A paid Claude plan.** Skills don't work on the free tier. Pro, Max, Team, and Enterprise all work.

**Your WordPress site's address.** That alone is enough for a basic audit.

**SSH access — optional, but this is where the real value is.** SSH is a way to connect directly to the server your site sits on. Most hosts include it; many people have never turned it on. With it, the audit sees everything. Without it, the audit only sees what any visitor can see from outside.

How to find out if you have SSH:

| Host | Where to look |
|---|---|
| Hostinger | hPanel → Advanced → SSH Access |
| SiteGround | Site Tools → Devs → SSH Keys Manager |
| Bluehost | cPanel → Advanced → SSH Access |
| Cloudways | Server → Master Credentials |
| Kinsta / WP Engine | MyKinsta or User Portal → site → Info / SFTP & SSH |
| cPanel (generic) | Look for "SSH Access" or "Terminal" |

You're looking for four things: a **host** (like `123.45.67.89` or `ssh.yoursite.com`), a **port** (often 22 or 65002), a **username**, and either a password or an SSH key. Copy them somewhere; you'll paste them in later.

If your host doesn't offer SSH, that's fine — skip to the basic audit below. If you're not sure, ask your host's support "do I have SSH access, and what are my credentials?" They answer this constantly.

---

## Install it

Pick the version of Claude you use.

### If you use Claude in a browser or the desktop app (claude.ai)

1. Go to the [Releases page](https://github.com/mwstech/wp-security-audit-skill/releases) and download **`wp-security-audit.zip`**. Don't unzip it.
2. Open Claude → **Settings** → **Capabilities** → **Skills**
3. Click **Upload skill** and select the zip you just downloaded
4. It appears in your skills list. Done.

*This gives you the basic audit only.* Claude in a browser can't connect to your server, so it can only check what's visible from outside. That's genuinely useful — but it's not the full picture.

### If you use Claude Code (the terminal version)

This is the one that gives you the complete audit.

Open Terminal (Mac) or your command line (Windows/Linux) and paste these lines one at a time:

```bash
mkdir -p ~/.claude/skills
cd ~/.claude/skills
curl -L -o wp.zip https://github.com/mwstech/wp-security-audit-skill/releases/latest/download/wp-security-audit.zip
unzip wp.zip
rm wp.zip
```

Check it worked:

```bash
ls ~/.claude/skills/wp-security-audit
```

You should see `SKILL.md`, `README.md`, `references`, and `assets` listed. If you see "No such file or directory," something went wrong — see Troubleshooting below.

*Note: `~/.claude/skills` is a hidden folder. Your file browser won't show it by default, and that's normal. The commands above create and fill it without you needing to see it.*

---

## Use it

Just ask in plain English. You don't need to name the skill or use special wording.

Here's what a real exchange looks like, so you know what to expect back.

### "Is my site safe?" — the starting point

> **You:** Can you check example.com for WordPress security problems?

Claude runs the external checks and comes back with something like: *WordPress 6.4.2 (three versions behind). Found 11 plugins from your page source. Two look concerning — Slider Revolution appears to be 6.5.x, which has a published vulnerability, though I can only infer the version from asset URLs, so treat that as unconfirmed. Your site also leaks usernames through author archives. I can't see your files or database from here — if you have SSH access, I can check for the things that actually get sites hacked.*

Note what it did: it told you what it found, flagged what it *wasn't sure about*, and told you what it couldn't see. If a security tool ever sounds more certain than that, be suspicious.

### "Actually, here's my server" — the real audit

> **You:** I do have SSH. Here are my details: [paste from your host's control panel]

Now it checks your actual files: every plugin's true version against vulnerability databases, whether WordPress core files have been tampered with, your `wp-config.php` settings, file permissions, admin accounts, and whether malware is already sitting in your uploads folder. This takes fifteen minutes to an hour. Expect a full report at the end, sorted Critical / Important / Polish.

### "Something feels wrong" — the compromise check

> **You:** My site redirects to a spam page but only sometimes, and only for visitors from Google. I have SSH. Can you look?

That symptom is a known malware pattern, and the skill goes hunting: injected `.htaccess` rules, PHP files hidden in uploads, modified theme files, admin accounts you didn't create, poisoned database entries. It'll tell you what it found and — importantly — when the damage is bad enough that you should stop and call a professional rather than trying to clean it yourself.

### "Just check the plugins" — the quick pass

> **You:** I don't need a full audit. Just tell me which of my plugins have known vulnerabilities. Here's my plugin list: [paste from your WordPress dashboard]

Skips everything else and does the CVE cross-check. Fast, and it's the single highest-value check — outdated plugins are how most WordPress sites get compromised. Works with a copy-pasted plugin list; no server access needed.

### "Explain this to my client" — the agency use

> **You:** Run a full audit on clientsite.com, then write it up as a report I can send to a non-technical client. My agency name is [X].

You get the same findings written in plain language, with your agency named as the preparer. Useful for justifying a maintenance retainer, or for showing a prospect what they've been ignoring.

### "What do I fix first?" — after the report

> **You:** I can't do all of this. If I only have two hours this weekend, what should I do?

It'll rank by actual risk reduction per hour of work, not by tier label. Sometimes the fastest meaningful win is deleting three plugins nobody uses.

---

### Questions worth asking after any audit

- *"How did you determine that version? How confident are you?"* — makes it separate confirmed facts from inferences
- *"What could you NOT check, and what would it take to check it?"* — surfaces the gaps
- *"Is any of this evidence that I've already been hacked, or is it all preventive?"* — an important distinction the tiers alone don't make
- *"Which of these can I fix myself, and which need a developer?"*
- *"Show me the exact commands to fix the Critical items."*

### What it won't do

It won't fix anything — no files edited, no settings changed, no plugins updated. It reports; you decide and act. It also won't attack your site to prove a vulnerability is real, so some findings are "this version is known to be vulnerable" rather than "I got in."

**How long it takes:** a few minutes for the external check. Fifteen minutes to an hour for a full audit, depending on how many plugins the site has.

---

## What you get back

A list of findings in three groups:

- **Critical** — someone could break in right now, or already has. Deal with these within a day or two.
- **Important** — real risk, not on fire. Deal with these within a couple of weeks.
- **Polish** — worth tidying when you have time.

Each finding tells you what it is, why it matters in plain language, and exactly how to fix it — the command to run, the setting to change, or the plugin to update.

It also tells you what *passed*, and it tells you honestly what it couldn't check. If it ran the basic audit, it says so, and says what a full audit would have added.

---

## What it looks at

Plugins and themes checked against public vulnerability databases (WPScan, Patchstack, Wordfence). Plugins nobody has updated in years. Premium plugins bundled inside themes, which quietly fall behind. WordPress core files compared against the official originals to catch tampering. Configuration mistakes in `wp-config.php`. Backups and database dumps left where anyone can download them. File permissions. Admin accounts that shouldn't exist. Malware signatures — PHP files hidden in your uploads folder, poisoned redirects, known backdoors. And the externally visible surface: xmlrpc, username leakage, directory listings, security headers.

---

## Honest limits

**It doesn't find zero-days.** It matches your plugin versions against vulnerabilities that have been published. A flaw discovered last week and not yet disclosed is invisible to it — and to every other version-based scanner, including the paid ones. What it catches is the far more common problem: a vulnerability patched eight months ago that's still sitting on your site.

**It doesn't replace a penetration test.** It's an inspection, not an attack simulation.

**If it finds evidence you've already been hacked, get a professional.** Cleaning a compromised site properly is its own job. The skill will tell you when you're in that territory.

**It never changes anything.** No fixes are applied, no files edited, no settings touched. It reports; you decide.

---

## Troubleshooting

**"Claude didn't use the skill."** Ask more directly: "Use the wp-security-audit skill to check example.com." If it still doesn't, confirm the skill is installed (`ls ~/.claude/skills/` for Claude Code, or check Settings → Capabilities → Skills in the app).

**"unzip: command not found" (Windows).** Use PowerShell instead: `Expand-Archive wp.zip -DestinationPath .`

**"Permission denied" when connecting via SSH.** Usually the port is wrong, or SSH isn't enabled on your hosting account yet. Check your host's control panel again — some hosts require you to switch it on manually.

**The audit stops partway through.** Long audits on plugin-heavy sites can run into limits. Ask Claude to continue, or run the audit in sections ("just do the plugin CVE check first").

**Your host blocks the checks.** Some hosts run firewalls that block automated requests. If results look suspiciously empty, mention this to Claude — the skill knows how to work around it.

**Still stuck?** [Open an issue](https://github.com/mwstech/wp-security-audit-skill/issues) and tell us what happened. Confusing instructions are a bug; if something didn't make sense, we'd rather hear it than have you give up.

---

## For agencies

Run this for your clients. Put your own name on the report as the preparer; the small tool credit in the footer stays. It's MIT licensed, so you can fork it and adapt the checklist to your own standards.

---

Built by [Macronimous Web Solutions](https://www.macronimous.com) — offshore web development and WordPress specialists since 2002.

Found problems you'd rather hand to someone else? That's our day job: info@macronimous.com
