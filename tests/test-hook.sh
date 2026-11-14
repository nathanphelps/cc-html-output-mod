#!/usr/bin/env bash
# Tests hooks/print-rule.cmd: which file it prints, under each way a host can start it.
# Usage: bash tests/test-hook.sh   (from any directory)
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_REL="hooks/print-rule.cmd"
RULE="$ROOT/html-output-rule.md"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

case "$(uname -s)" in MINGW*|MSYS*) WIN=1 ;; *) WIN=0 ;; esac
fails=0

native() { if [ "$WIN" = 1 ]; then cygpath -w "$1"; else printf '%s' "$1"; fi; }

# make_plugin <dir> [norule]: a copy of the files the hook needs.
make_plugin() {
  mkdir -p "$1/hooks"
  cp "$ROOT/$HOOK_REL" "$1/hooks/" 2>/dev/null
  [ "${2:-}" = norule ] || cp "$RULE" "$1/"
}

# make_home <dir> [override-bytes-file]
make_home() {
  mkdir -p "$1"
  if [ -n "${2:-}" ]; then
    mkdir -p "$1/.config/html-documents"
    cp "$2" "$1/.config/html-documents/rule.md"
  fi
}

launch() { # <launcher> <plugin-dir>
  local hook="$2/$HOOK_REL"
  case "$1" in
    direct)     "$hook" ;;
    sh)         sh "$hook" ;;
    cmd)        cmd.exe //c "$(native "$hook")" ;;
    powershell) powershell.exe -NoProfile -Command "& '$(native "$hook")'" ;;
  esac
}

# check <launcher> <case-name> <expected-file> <plugin-dir> <home-dir|UNSET> [cwd]
check() {
  local launcher="$1" name="$2" expected="$3" plugin="$4" home="$5" cwd="${6:-$TMP}"
  local out="$TMP/out" err="$TMP/err" status
  if [ "$home" = UNSET ]; then
    ( cd "$cwd" && env -u HOME -u USERPROFILE bash -c "$(declare -f launch native); WIN=$WIN HOOK_REL=$HOOK_REL; launch \"\$1\" \"\$2\"" _ "$launcher" "$plugin" ) >"$out" 2>"$err"
  else
    ( cd "$cwd" && HOME="$home" USERPROFILE="$(native "$home")" launch "$launcher" "$plugin" ) >"$out" 2>"$err"
  fi
  status=$?
  if [ "$status" -eq 0 ] && cmp -s "$out" "$expected" && [ ! -s "$err" ]; then
    echo "ok   [$launcher] $name"
  else
    echo "FAIL [$launcher] $name (exit $status, stdout $(wc -c <"$out") bytes, expected $(wc -c <"$expected"), stderr $(wc -c <"$err") bytes)"
    fails=$((fails + 1))
  fi
}

# Fixtures
printf 'MARKER-RULE-7f3a\n' >"$TMP/marker"
: >"$TMP/empty"
printf ' \n\t\n' >"$TMP/blank"
printf 'Caf\xc3\xa9 r\xc3\xa8gle\r\nline two\r\n' >"$TMP/utf8crlf"

make_plugin "$TMP/plugin"
make_plugin "$TMP/plugin-norule" norule
make_plugin "$TMP/dir with space/plugin"
make_home "$TMP/home-none"
make_home "$TMP/home-marker" "$TMP/marker"
make_home "$TMP/home-empty" "$TMP/empty"
make_home "$TMP/home-blank" "$TMP/blank"
make_home "$TMP/home-utf8" "$TMP/utf8crlf"
make_home "$TMP/dir with space/home-none"
make_home "$TMP/dir with space/home-marker" "$TMP/marker"

if [ "$WIN" = 1 ]; then LAUNCHERS="direct sh cmd powershell"; else LAUNCHERS="direct sh"; fi

for l in $LAUNCHERS; do
  check "$l" default             "$RULE"         "$TMP/plugin" "$TMP/home-none"
  check "$l" override            "$TMP/marker"   "$TMP/plugin" "$TMP/home-marker"
  check "$l" override-empty      "$RULE"         "$TMP/plugin" "$TMP/home-empty"
  check "$l" override-whitespace "$RULE"         "$TMP/plugin" "$TMP/home-blank"
  check "$l" home-missing        "$RULE"         "$TMP/plugin" "$TMP/no-such-home"
  check "$l" home-unset          "$RULE"         "$TMP/plugin" UNSET
  check "$l" rule-missing        "$TMP/empty"    "$TMP/plugin-norule" "$TMP/home-none"
  check "$l" spaces-default      "$RULE"         "$TMP/dir with space/plugin" "$TMP/dir with space/home-none"
  check "$l" spaces-override     "$TMP/marker"   "$TMP/dir with space/plugin" "$TMP/dir with space/home-marker"
  check "$l" other-cwd           "$RULE"         "$TMP/plugin" "$TMP/home-none" /
  check "$l" override-utf8-crlf  "$TMP/utf8crlf" "$TMP/plugin" "$TMP/home-utf8"
done

# The script must be stored with LF endings and the executable bit.
eol="$(git -C "$ROOT" ls-files --eol "$HOOK_REL")"
case "$eol" in
  i/lf*w/lf*) echo "ok   line endings are LF" ;;
  *) echo "FAIL line endings: '$eol'"; fails=$((fails + 1)) ;;
esac
mode="$(git -C "$ROOT" ls-files -s "$HOOK_REL")"
case "$mode" in
  100755*) echo "ok   executable bit set in git" ;;
  *) echo "FAIL executable bit: '$mode'"; fails=$((fails + 1)) ;;
esac

if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
