#!/usr/bin/env bash
# Checks that the rule copy embedded in PROMPT.md matches html-output-rule.md.
# Usage: bash tests/check-rule-sync.sh   (from any directory)
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Lines strictly between the two markers, without carriage returns.
tr -d '\r' <"$ROOT/PROMPT.md" |
  awk '/<!-- rule:end -->/ {inside = 0} inside {print} /<!-- rule:start -->/ {inside = 1}' >"$TMP/embedded"
tr -d '\r' <"$ROOT/html-output-rule.md" >"$TMP/source"

if [ ! -s "$TMP/embedded" ]; then
  echo "FAIL: no text found between the rule:start and rule:end markers in PROMPT.md"
  exit 1
fi

if diff -u "$TMP/source" "$TMP/embedded"; then
  echo "ok   the rule in PROMPT.md matches html-output-rule.md"
else
  echo "FAIL: the rule in PROMPT.md differs from html-output-rule.md (diff above: - is html-output-rule.md, + is PROMPT.md)"
  exit 1
fi
