#!/usr/bin/env bash
# Build wp-security-audit.zip for a GitHub release.
#
# The layout inside the zip must match v1.1 exactly. The public install
# command on macronimous.com unzips this file straight into ~/.claude/skills,
# and the README tells users to upload the same zip to Claude. See DECISIONS.md.
#
#   wp-security-audit/SKILL.md
#   wp-security-audit/README.md
#   wp-security-audit/references/...
#   wp-security-audit/assets/...
#
# Usage: ./build-release.sh [git-ref]    (default: HEAD)
# Builds from committed content only, so uncommitted edits never ship.

set -euo pipefail
cd "$(dirname "$0")"

REF="${1:-HEAD}"
SRC="skills/wp-security-audit"
OUT="wp-security-audit.zip"

rm -f "$OUT"
git archive --format=zip --prefix=wp-security-audit/ -o "$OUT" "$REF:$SRC"

echo "Built $OUT from $REF:$SRC"
unzip -l "$OUT"
