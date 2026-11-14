: << 'CMDBLOCK'
@echo off
REM Session-start hook: prints the HTML document rule to standard output.
REM
REM This one file is read by two interpreters. cmd.exe treats line 1 as a
REM label and runs the batch lines below. A POSIX shell treats line 1 as a
REM here-document that hides the batch lines, then runs the part after
REM CMDBLOCK. Keep LF line endings and do not add goto or other labels:
REM cmd.exe mishandles goto targets in files with LF endings.
REM
REM Prints the user's override file when it exists and has non-blank
REM content, otherwise the rule file shipped with the plugin. Always exits 0
REM and prints no errors: a session without the rule is better than a
REM session that starts with an error.
setlocal
set "RULE=%~dp0..\html-output-rule.md"
set "OVERRIDE="
if defined USERPROFILE set "OVERRIDE=%USERPROFILE%\.config\html-documents\rule.md"
if defined OVERRIDE if exist "%OVERRIDE%" findstr /r /c:"[^ 	]" "%OVERRIDE%" >nul 2>&1 && set "RULE=%OVERRIDE%"
if exist "%RULE%" type "%RULE%" 2>nul
exit /b 0
CMDBLOCK

# POSIX half. $0 is split with parameter expansion instead of dirname so the
# script still works when the host starts it with an empty PATH.
case "$0" in
  */*|*\\*) dir="${0%[/\\]*}" ;;
  *) dir="." ;;
esac
rule="$dir/../html-output-rule.md"
override="${HOME:-}/.config/html-documents/rule.md"
if [ -n "${HOME:-}" ] && [ -f "$override" ] && grep -q '[^[:space:]]' "$override" 2>/dev/null; then
  rule="$override"
fi
if [ -r "$rule" ]; then
  cat "$rule" 2>/dev/null
fi
exit 0
