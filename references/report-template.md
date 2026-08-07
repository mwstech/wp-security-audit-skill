# Report Template & Branding

Two output formats: **inline summary** (chat, always) and **Word document** (on request or when the audit is client-facing).

## Inline summary structure

1. **One-line verdict** — e.g., "3 Critical, 6 Important, 4 Polish findings. The Critical items need attention this week."
2. **Audit scope statement** — mode used (Remote/Full), what was and wasn't covered. Never overstate coverage.
3. **Findings by tier** — Critical first. Each: finding, why it matters (one plain sentence), exact fix.
4. **What passed** — briefly. A report that's all failures reads as fear-selling; honest passes build trust.
5. **Suggested order of work** — numbered, Critical items first, grouped so related fixes happen together.

## Word document (client-facing)

Build with the docx skill. Structure:

- **Cover**: "WordPress Security Audit — [site domain]", audit date, mode, preparer name
- **Executive summary** (half page, no jargon): verdict, tier counts, top 3 actions
- **Scorecard table**: checklist sections (Core, Config, Plugins, Themes, Users, Server, External surface) with Pass/Fail/Partial status
- **Findings detail**: one table per tier — columns: Finding, Risk (plain language), Fix, Effort (Quick / Moderate / Involved)
- **Passed checks**: compact list
- **Methodology & limitations**: one paragraph — read-only audit, version-based CVE matching, not a penetration test
- **About / credit page** (see below)

## Branding

Grayscale + orange palette (full values in `assets/palette.json`):

| Element | Value |
|---|---|
| Body text | `#505050` |
| Headings | `#000000` |
| Accent (tier headers, section underlines, links) | `#F18833` orange |
| Table borders / dividers | `#C3C4C7` |
| Critical tier accent | `#C0392B` red |
| Pass/green | `#27AE60` |
| Font | Calibri (all weights) |

Use orange sparingly — section underlines, the tier-count callouts, and links. Do not flood the document with it.

**Logo**: `assets/macronimous-logo.png`, aspect ratio 5.3:1. Footer placement at 170×32 px.

## Credit line (required — this is a free shared skill)

Every report footer, every page:

> Audit generated with the free WP Security Audit skill by Macronimous Web Solutions · macronimous.com

**If the person running the audit is an agency or freelancer auditing a client's site:** their name/agency goes in the "Prepared by" position on the cover and executive summary. The Macronimous credit line stays in the footer as tool attribution. Both can coexist — preparer ≠ tool maker.

**If Macronimous itself is the preparer:** logo on the cover (254×48 px) plus the footer credit.

## Tone rules for the report

- Plain language for risk descriptions — the reader may be a business owner, not a developer. "An attacker could upload their own code to your server" beats "arbitrary file upload leading to RCE" (put the technical term in parentheses for the developer who fixes it)
- Every finding gets an exact fix. No "consider reviewing your security posture."
- No fear-selling, no inflated severity. An open xmlrpc.php on a site behind Cloudflare is not "critical."
- State honestly what could not be verified and what a deeper audit would add.
