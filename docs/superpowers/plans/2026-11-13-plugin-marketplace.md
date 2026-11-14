# Plugin and Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make this repository installable as a plugin, from its own marketplace, on Claude Code and on Codex, with the rule delivered by a session-start hook.

**Architecture:** The repository root is the plugin and the marketplace for both tools. One hook script, valid both as a Windows batch file and as a POSIX shell script, prints the user's override file if it exists and otherwise `html-output-rule.md`. Each tool adds that output to the session's context. The rule text, the skill, and `PROMPT.md` are not changed.

**Tech Stack:** JSON manifests, one `.cmd`/`sh` polyglot script, Bash test scripts, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-13-plugin-marketplace-design.html`. Read it before starting. Its "Unverified facts" table lists a fallback for each open question; this plan refers to rows of that table by their question.

## Global Constraints

- Plugin name `html-output`. Marketplace name `nathanphelps`. Install id `html-output@nathanphelps`.
- No `version` field in `.claude-plugin/plugin.json` or `.claude-plugin/marketplace.json`. `.codex-plugin/plugin.json` has `"version": "0.1.0"`.
- Override file: `$HOME/.config/html-documents/rule.md` on macOS and Linux, `%USERPROFILE%\.config\html-documents\rule.md` on Windows. A missing, empty, or whitespace-only file counts as absent.
- The hook prints the chosen file's text and nothing else, exits 0 in every case, and writes nothing to standard error.
- The hook uses no Node, Python, or Git Bash. On Windows it must work when started by `cmd.exe`, by PowerShell, and by Git Bash.
- One `SessionStart` hook entry with no matcher. No subagent hook.
- Do not change the wording of `html-output-rule.md`, `skills/html-documents/SKILL.md`, or the rule copy in `PROMPT.md`.
- Do not edit `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, or any other global instruction file. This machine already has the rule pasted there, so every "is the rule active" check uses an override file containing a marker sentence.
- Work on the branch `plugin-marketplace`. Commit to it and push it to `origin`. Do not commit to or merge into `main`, open a pull request, or tag a release.
- Never create Git worktrees. Work in the existing checkout.
- All prose written for people (README, CONTRIBUTING, manifest descriptions) uses literal statements and no figurative phrasing, in the style of the existing README.
- End every commit message with the two attribution lines given in the session's system reminder.

## Review Focus

Conditions the spec implies that are likely to affect a person using the plugin. Each has a test in Task 1.

1. The user's profile path or the plugin's install path contains a space (common on Windows). The hook prints the rule.
2. The session's working directory is not the plugin folder. The hook finds its files from its own location.
3. `HOME` or `USERPROFILE` is unset or points to a folder that does not exist. The hook prints the default rule and no error.
4. The override file contains non-ASCII text or Windows line endings. The bytes arrive unchanged.
5. The hook script is checked out with Windows line endings, which breaks the POSIX half. `.gitattributes` forces LF, and a test checks it.

---

### Task 1: Hook script, its test, and the hook registration

**Files:**
- Create: `hooks/print-rule.cmd`
- Create: `hooks/hooks.json`
- Create: `.gitattributes`
- Test: `tests/test-hook.sh`

**Interfaces:**
- Consumes: `html-output-rule.md` at the repository root (existing).
- Produces: `hooks/print-rule.cmd`, run with no arguments, prints the rule to standard output. `tests/test-hook.sh`, run from any directory with `bash tests/test-hook.sh`, exits 0 when every case passes and prints one `ok` or `FAIL` line per case. Task 4's CI runs it.

- [ ] **Step 1: Create the branch**

```bash
git switch -c plugin-marketplace
```

- [ ] **Step 2: Write the failing test `tests/test-hook.sh`**

A Bash script with `set -u`. It finds the repository root from its own path. Each case builds a temporary plugin copy (`hooks/` plus `html-output-rule.md`) and a temporary home, runs the hook with `HOME` and `USERPROFILE` both set to the temporary home, and compares standard output byte for byte with an expected file using `cmp`. Each case also asserts exit status 0 and empty standard error. On Windows (`uname` starts with `MINGW` or `MSYS`), convert paths for `USERPROFILE` with `cygpath -w`.

Define `run_hook <plugin-dir>` as a function variable so the whole case list runs once per launcher:

| Launcher | Platforms | Invocation |
|---|---|---|
| `direct` | all | `"$plugin/hooks/print-rule.cmd"` (proves the executable bit on macOS and Linux; on Windows Git Bash hands the file to `cmd.exe`) |
| `cmd` | Windows | `cmd.exe //c "$(cygpath -w "$plugin/hooks/print-rule.cmd")"` |
| `powershell` | Windows | `powershell.exe -NoProfile -Command "& '$(cygpath -w "$plugin/hooks/print-rule.cmd")'"` |
| `sh` | all | `sh "$plugin/hooks/print-rule.cmd"` |

Cases, each run under every launcher:

| Case name | Setup | Expected output |
|---|---|---|
| `default` | no override file | bytes of `html-output-rule.md` |
| `override` | override contains `MARKER-RULE-7f3a\n` | `MARKER-RULE-7f3a\n` |
| `override-empty` | override is a zero-byte file | default rule |
| `override-whitespace` | override contains ` \n\t\n` | default rule |
| `home-missing` | `HOME` and `USERPROFILE` point to a path that does not exist | default rule |
| `home-unset` | `HOME` and `USERPROFILE` unset (`env -u`) | default rule |
| `rule-missing` | plugin copy without `html-output-rule.md`, no override | empty output |
| `spaces` | plugin copy and home both under a folder named `dir with space` | default rule; then with an override, the override |
| `other-cwd` | run with the working directory set to `/` (or `C:\` ) | default rule |
| `override-utf8-crlf` | override bytes are `Caf\xc3\xa9 r\xc3\xa8gle\r\nline two\r\n` | the same bytes |

Two more assertions, not per launcher:

- `git ls-files --eol hooks/print-rule.cmd` reports `i/lf` and `w/lf`.
- On macOS and Linux, `git ls-files -s hooks/print-rule.cmd` starts with `100755`.

- [ ] **Step 3: Run the test and confirm it fails**

Run: `bash tests/test-hook.sh`
Expected: every case prints `FAIL` because `hooks/print-rule.cmd` does not exist; exit status 1.

- [ ] **Step 4: Write `.gitattributes`**

```
hooks/print-rule.cmd text eol=lf
tests/*.sh text eol=lf
```

- [ ] **Step 5: Write `hooks/print-rule.cmd`**

The file has two halves, in the pattern of Superpowers' `hooks/run-hook.cmd` (readable on this machine at `~/.claude/plugins/cache/claude-plugins-official/superpowers/7.0.2/hooks/run-hook.cmd`).

- Line 1 is `: << 'CMDBLOCK'`. `cmd.exe` reads it as a label; a POSIX shell reads it as the start of a here-document that hides the batch half.
- Batch half: `@echo off`, `setlocal`. The default path is `%~dp0..\html-output-rule.md`. Use the override path only when `USERPROFILE` is defined, the file exists, and `findstr /r /c:"[^ 	]"` (space and tab inside the brackets) finds a non-blank character in it. Print the chosen file with `type "<path>" 2>nul` only if it exists. End with `exit /b 0`, then the line `CMDBLOCK`.
- POSIX half: derive the script folder from `$0` with parameter expansion (`${0%[/\\]*}`), not `dirname`. Use the override only when `HOME` is non-empty, the file is a regular file, and `grep -q '[^[:space:]]'` matches. Print with `cat "<path>" 2>/dev/null` only if readable. End with `exit 0`.
- No `goto` and no labels other than line 1: the file has LF line endings, and `cmd.exe` mishandles `goto` targets in LF files.

Set the executable bit in Git, which Windows does not do on its own:

```bash
git add hooks/print-rule.cmd
git update-index --chmod=+x hooks/print-rule.cmd
```

- [ ] **Step 6: Run the test and confirm it passes**

Run: `bash tests/test-hook.sh`
Expected: every case prints `ok` under the `direct`, `cmd`, `powershell`, and `sh` launchers; exit status 0.

- [ ] **Step 7: Write `hooks/hooks.json`**

```json
{
  "description": "Prints the HTML document rule at session start",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/print-rule.cmd\"",
            "powershell": "& \"${CLAUDE_PLUGIN_ROOT}/hooks/print-rule.cmd\"",
            "shell": "bash"
          }
        ]
      }
    ]
  }
}
```

The `powershell` and `shell` fields are copied from Superpowers' `hooks/hooks.json`, which is how that plugin runs a `.cmd` hook on Windows with and without Git Bash. Task 2 checks them against `claude plugin validate`.

- [ ] **Step 8: Commit**

```bash
git add .gitattributes hooks tests docs/superpowers
git commit -m "Add session-start hook that prints the rule, with tests"
```

This commit also adds the design document and this plan. Whether they stay in the repository at merge is Nathan's decision; say so in the final report.

---

### Task 2: Claude Code manifests and local verification

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: `hooks/hooks.json` and `skills/html-documents/` from their default locations.
- Produces: a plugin that `claude plugin validate .` accepts and that installs as `html-output@nathanphelps`.

- [ ] **Step 1: Write `.claude-plugin/plugin.json`**

```json
{
  "name": "html-output",
  "description": "Makes Claude Code and Codex write plans, specs, reports, and other documents meant for you as HTML files instead of Markdown.",
  "author": { "name": "Nathan Phelps", "url": "https://github.com/nathanphelps" },
  "homepage": "https://github.com/nathanphelps/cc-html-output-mod",
  "repository": "https://github.com/nathanphelps/cc-html-output-mod",
  "license": "MIT",
  "keywords": ["html", "documents", "plans", "specs", "output-format"]
}
```

- [ ] **Step 2: Write `.claude-plugin/marketplace.json`**

```json
{
  "name": "nathanphelps",
  "description": "Plugins by Nathan Phelps",
  "owner": { "name": "Nathan Phelps", "url": "https://github.com/nathanphelps" },
  "plugins": [
    {
      "name": "html-output",
      "source": "./",
      "description": "Makes Claude Code and Codex write plans, specs, reports, and other documents meant for you as HTML files instead of Markdown."
    }
  ]
}
```

- [ ] **Step 3: Validate**

Run: `claude plugin validate . --strict`
Expected: "Validation passed", exit status 0. If the only complaint is the `powershell` or `shell` key in `hooks/hooks.json`, keep the keys, run without `--strict` from here on, and record the warning text for Task 4 and Task 5. If `owner.url` or `author.url` is rejected, remove that field.

- [ ] **Step 4: Check the hook in a session, without installing**

Confirm `~/.config/html-documents/` does not exist (it did not when this plan was written). Create the override with a marker, run a session that loads the plugin from the working tree, then delete the override:

```bash
mkdir -p ~/.config/html-documents
printf '# Document format\n\nMARKER-RULE-7f3a is the marker sentence for this test.\n' > ~/.config/html-documents/rule.md
cd "$(mktemp -d)" && claude --plugin-dir "C:/Users/Nathan.Phelps/cc-html-output-mod" -p "Does any instruction you were given contain a string starting with MARKER-RULE? If yes, quote that sentence exactly. If no, say NONE."
rm -r ~/.config/html-documents
```

Expected: the reply quotes `MARKER-RULE-7f3a is the marker sentence for this test.` If the reply is `NONE`, the hook's output did not reach the context: check `claude --debug` output for the hook's run before changing anything.

- [ ] **Step 5: Check the real install route from a local marketplace**

```bash
claude plugin marketplace add "C:/Users/Nathan.Phelps/cc-html-output-mod"
claude plugin install html-output@nathanphelps
claude plugin details html-output@nathanphelps
```

Expected: `details` lists the skill `html-documents` and one `SessionStart` hook. Repeat the marker check from Step 4 without `--plugin-dir`; expect the marker again.

- [ ] **Step 6: Uninstall and confirm nothing remains**

```bash
claude plugin uninstall html-output@nathanphelps
claude plugin marketplace remove nathanphelps
```

Expected: `claude plugin list` no longer shows `html-output`, and `~/.config/html-documents/` does not exist. Nathan installs from GitHub after merging.

- [ ] **Step 7: Commit**

```bash
git add .claude-plugin
git commit -m "Add Claude Code plugin and marketplace manifests"
```

---

### Task 3: Codex manifests and verification

This task settles the Codex rows of the spec's "Unverified facts" table. Write each answer down as you get it; Task 5 puts them in the README and `CONTRIBUTING.md`.

**Files:**
- Create: `.codex-plugin/plugin.json`
- Create: `.agents/plugins/marketplace.json`
- Possibly create: `hooks/hooks.codex.json` (only if Step 4 requires it)
- Possibly modify: `hooks/print-rule.cmd`, `tests/test-hook.sh` (only if Step 5 requires JSON output)

**Interfaces:**
- Consumes: `hooks/hooks.json`, `hooks/print-rule.cmd`, `skills/html-documents/`.
- Produces: a plugin that installs on Codex 0.169.0 as `html-output@nathanphelps`, and a written list of answers to the six Codex questions.

- [ ] **Step 1: Write `.codex-plugin/plugin.json`**

```json
{
  "name": "html-output",
  "version": "0.1.0",
  "description": "Makes Claude Code and Codex write plans, specs, reports, and other documents meant for you as HTML files instead of Markdown.",
  "author": { "name": "Nathan Phelps", "url": "https://github.com/nathanphelps" },
  "homepage": "https://github.com/nathanphelps/cc-html-output-mod",
  "repository": "https://github.com/nathanphelps/cc-html-output-mod",
  "license": "MIT",
  "keywords": ["html", "documents", "plans", "specs", "output-format"],
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json",
  "interface": {
    "displayName": "HTML Output",
    "shortDescription": "Documents meant for you are written as HTML files, not Markdown",
    "longDescription": "Adds a standing instruction that makes the agent write plans, specs, design docs, option comparisons, reports, and handoffs as single HTML files with mockups and diagrams, and a skill with detailed guidance for review documents, throwaway editors, and a design system page.",
    "developerName": "Nathan Phelps",
    "category": "Productivity",
    "capabilities": ["Read", "Write"],
    "websiteURL": "https://github.com/nathanphelps/cc-html-output-mod"
  }
}
```

- [ ] **Step 2: Write `.agents/plugins/marketplace.json`**

```json
{
  "name": "nathanphelps",
  "interface": { "displayName": "Nathan Phelps" },
  "plugins": [
    {
      "name": "html-output",
      "source": { "source": "local", "path": "./" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
```

- [ ] **Step 3: Add the marketplace and install from the CLI**

```bash
codex plugin marketplace add "C:/Users/Nathan.Phelps/cc-html-output-mod"
codex plugin list
codex plugin add html-output@nathanphelps
```

Expected: `list` shows `html-output` under `nathanphelps`; `add` succeeds. This answers "Does `codex plugin add` work from the CLI?". If `add` fails, record the error and install through the Codex desktop app instead.

Also answer "Which marketplace file does Codex read when both exist?": temporarily rename `.agents/plugins/marketplace.json`, remove and re-add the marketplace, and see whether `list` still shows the plugin from `.claude-plugin/marketplace.json`. Restore the file. Keep both files unless they conflict.

- [ ] **Step 4: Ask Nathan to trust the hook**

Stop and ask Nathan to open a Codex session, run `/hooks`, and trust the `html-output` session-start hook. Ask him to report what the review screen shows as the hook's command. Do not use `--dangerously-bypass-hook-trust`.

If no `html-output` hook is listed, Codex did not load `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`: create `hooks/hooks.codex.json` with the same content using `${PLUGIN_ROOT}`, point `"hooks"` in `.codex-plugin/plugin.json` at it, reinstall, and ask again.

- [ ] **Step 5: Check that plain output reaches the context**

Create the marker override as in Task 2 Step 4, then:

```bash
cd "$(mktemp -d)" && codex exec --skip-git-repo-check "Does any instruction or context you were given contain a string starting with MARKER-RULE? If yes, quote that sentence exactly. If no, say NONE."
rm -r ~/.config/html-documents
```

Expected: the reply quotes the marker sentence. This answers "Does plain standard output enter the context on Codex?" and "How does Codex run a hook command on Windows?".

If the reply is `NONE` and the hook ran, apply the spec's fallback: when `PLUGIN_ROOT` is set and `CLAUDE_PLUGIN_ROOT` is not, or by a first argument `json` passed from a Codex-only hooks file, the script emits `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<escaped text>"}}`. The batch half does this by calling `powershell.exe -NoProfile -Command` with `Get-Content -Raw` and `ConvertTo-Json`; the POSIX half escapes `\`, `"`, newline, carriage return, and tab with parameter substitution. Add a `json` launcher to `tests/test-hook.sh` that parses the output with `jq -r .hookSpecificOutput.additionalContext` and compares it with the expected text for every case. If the hook did not run at all on Windows, use the `commandWindows` field from Codex's hooks documentation for the Windows command.

- [ ] **Step 6: Check re-trust and upgrade behavior**

With no override file, on the branch:

1. Append a line `MARKER-DEFAULT-91c2` to `html-output-rule.md` in the working tree (do not commit it).
2. Run `codex plugin marketplace upgrade nathanphelps`, then the `codex exec` question from Step 5 asking for `MARKER-DEFAULT`.
3. Record: did the new text arrive without changing `version`? Did Codex ask for trust again?
4. If the text did not arrive, change `version` to `0.1.1`, upgrade, and ask again. Record the result, then set `version` back to `0.1.0`.
5. Revert `html-output-rule.md` with `git checkout -- html-output-rule.md` and confirm `git diff --stat` shows no change to it.

These answer "Does Codex ask for trust again when only the rule changes?" and "Does upgrade pick up new commits when the version is unchanged?". A local-path marketplace may behave differently from a GitHub one; say so beside the answers.

- [ ] **Step 7: Uninstall and confirm nothing remains**

```bash
codex plugin remove html-output@nathanphelps
codex plugin marketplace remove nathanphelps
```

Expected: `codex plugin list` no longer shows `html-output`; `~/.codex/config.toml` has no `nathanphelps` marketplace entry. Leftover `hooks.state` entries for the plugin, if any, are recorded for the README's uninstall section.

- [ ] **Step 8: Run the hook test again and commit**

Run: `bash tests/test-hook.sh`
Expected: all `ok`.

```bash
git add .codex-plugin .agents hooks tests
git commit -m "Add Codex plugin and marketplace manifests"
```

---

### Task 4: CI

**Files:**
- Create: `tests/check-rule-sync.sh`
- Create: `.github/workflows/check.yml`

**Interfaces:**
- Consumes: `tests/test-hook.sh` from Task 1; every `.json` file from Tasks 1 to 3.
- Produces: `tests/check-rule-sync.sh`, run with `bash tests/check-rule-sync.sh`, exits 0 when the rule copy in `PROMPT.md` matches `html-output-rule.md`. A workflow named `check` that Task 5's `CONTRIBUTING.md` describes.

- [ ] **Step 1: Write `tests/check-rule-sync.sh`**

Extract the lines strictly between `<!-- rule:start -->` and `<!-- rule:end -->` in `PROMPT.md`, strip carriage returns from both sides, and `diff` against `html-output-rule.md`. Print the diff and exit 1 on a difference.

- [ ] **Step 2: Prove it detects a difference, then passes**

Run: `bash tests/check-rule-sync.sh` → expected exit 0.
Change one word in `html-output-rule.md`, run again → expected exit 1 with the diff shown. Revert with `git checkout -- html-output-rule.md`.

- [ ] **Step 3: Write `.github/workflows/check.yml`**

Triggers: `pull_request`, and `push` to `main` and `plugin-marketplace`. `permissions: contents: read`. Pin `actions/checkout` to a full commit SHA with the version in a comment.

| Job | Runs on | Steps |
|---|---|---|
| `manifests` | `ubuntu-latest` | `jq empty` on each of `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, and every `hooks/*.json`; `bash tests/check-rule-sync.sh`; assert with `jq -e` that `.claude-plugin/plugin.json` and the marketplace entry have no `version` key |
| `hook` | matrix: `ubuntu-latest`, `macos-latest`, `windows-latest` | `bash tests/test-hook.sh` (`shell: bash` on every runner) |
| `validate` | `ubuntu-latest` | `npm install -g @anthropic-ai/claude-code`, then `claude plugin validate .` with `--strict` if Task 2 Step 3 passed with it |

- [ ] **Step 4: Commit and push the branch**

```bash
git add tests/check-rule-sync.sh .github
git commit -m "Add CI: manifest checks, rule sync, hook test on three systems"
git push -u origin plugin-marketplace
```

- [ ] **Step 5: Watch the run and fix failures**

Run: `gh run watch` (or `gh run list --branch plugin-marketplace` then `gh run view <id> --log-failed`).
Expected: all three jobs pass. Fix hook or test failures on macOS and Linux in `hooks/print-rule.cmd` or `tests/test-hook.sh`, commit, push, and watch again. If the `validate` job fails because the command needs a signed-in account, delete that job and record that validation is a local step for `CONTRIBUTING.md`.

---

### Task 5: README and CONTRIBUTING

**Files:**
- Modify: `README.md` (sections "What changes after you install it", "Install", "Offline files or CDN libraries", "Changing the rule", "Optional skill", "Costs and limits", "Uninstall", "Files")
- Create: `CONTRIBUTING.md`

**Interfaces:**
- Consumes: the recorded answers from Task 3 and the validation outcome from Tasks 2 and 4.
- Produces: user-facing instructions. No code depends on them.

- [ ] **Step 1: Rewrite the README's "Install" section**

Order: "As a plugin" first, with one subsection per tool, then "Without the plugin" holding the existing "With the prompt", "Install methods", and "By hand" text unchanged.

Claude Code subsection, exact commands:

```
claude plugin marketplace add nathanphelps/cc-html-output-mod
claude plugin install html-output@nathanphelps
```

Then: updates are off by default for this marketplace; to turn them on, `/plugin` → Marketplaces → nathanphelps → Enable auto-update; to update by hand, `claude plugin update html-output@nathanphelps`.

Codex subsection, exact commands (replace with the desktop app steps if Task 3 Step 3 found the CLI install does not work):

```
codex plugin marketplace add nathanphelps/cc-html-output-mod
codex plugin add html-output@nathanphelps
```

Then: open a session, run `/hooks`, and trust the plugin's hook, because Codex does not run a plugin's hooks until they are trusted; update with `codex plugin marketplace upgrade nathanphelps`; and whether trust is asked again after an upgrade, as found in Task 3 Step 6.

Add these statements, each once:

- The plugin includes the skill, so there is nothing else to install.
- If you already pasted the rule into `CLAUDE.md` or `AGENTS.md`, remove that copy, or the agent receives the rule twice.
- The plugin gives the rule to the main session. Subagents do not receive it. With a pasted rule, most subagents do.

- [ ] **Step 2: Update the sections that describe changing the rule**

In "Changing the rule" and "Offline files or CDN libraries", add the plugin route: copy `html-output-rule.md` to `~/.config/html-documents/rule.md` (on Windows, `%USERPROFILE%\.config\html-documents\rule.md`) and edit the copy. State that the file replaces the plugin's rule entirely, that a person with this file no longer receives rule changes from plugin updates, that an empty file is ignored, and that Claude Code cuts hook output off at 10,000 characters. Keep the existing CDN replacement sentence as the text to swap in.

- [ ] **Step 3: Update "Optional skill", "Costs and limits", "Uninstall", and "Files"**

- "Optional skill": first sentence says the plugin includes the skill; the copy instructions apply to installs without the plugin.
- "Costs and limits": add one bullet that the plugin's rule arrives as hook output and not as an instruction file, and that this project has not measured whether agents follow it as reliably.
- "Uninstall": add the plugin route for each tool (the commands from Task 2 Step 6 and Task 3 Step 7), plus deleting `~/.config/html-documents/` if it was created, and anything Task 3 Step 7 found left behind.
- "Files": add rows for `.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/`, `hooks/`, `tests/`, and `CONTRIBUTING.md`.

- [ ] **Step 4: Write `CONTRIBUTING.md`**

Sections, short:

1. **What ships.** Every merge to `main` reaches Claude Code users on their next plugin update, because the manifests have no version. State the Codex rule found in Task 3 Step 6: either "no version change needed" or "raise `version` in `.codex-plugin/plugin.json` when a shipped file changes".
2. **Changing the rule.** `html-output-rule.md` is the source. The copy in `PROMPT.md` must match it; CI checks this. Keep the rule short and do not add layout requirements, for the reason given in the README's "Changing the rule".
3. **Testing a change.** `bash tests/test-hook.sh`; `bash tests/check-rule-sync.sh`; `claude plugin validate .`; trying it in a session with `claude --plugin-dir .`; trying it on Codex by adding the working tree as a marketplace.
4. **The hook script.** It is one file read by both `cmd.exe` and POSIX shells; it must keep LF line endings, use no `goto`, and need no Node, Python, or Git Bash.
5. **What CI checks.** The three jobs from Task 4, as they ended up.

- [ ] **Step 5: Check the prose and links**

Read the changed README sections and `CONTRIBUTING.md` once for figurative phrasing and replace any with a literal statement. Confirm every relative link in the README resolves:

```bash
grep -o '](\([^)#h][^)]*\))' README.md CONTRIBUTING.md | sed 's/.*](\(.*\))/\1/' | sort -u | while read -r p; do [ -e "$p" ] || echo "MISSING $p"; done
```

Expected: no `MISSING` lines.

- [ ] **Step 6: Commit and push**

```bash
git add README.md CONTRIBUTING.md
git commit -m "Document plugin install, override file, and contributing"
git push
```

Expected: the CI run for this push passes.

---

### Task 6: Final verification and handoff

**Files:** none.

- [ ] **Step 1: Install from GitHub at the branch, on both tools**

```bash
claude plugin marketplace add nathanphelps/cc-html-output-mod@plugin-marketplace
claude plugin install html-output@nathanphelps
codex plugin marketplace add nathanphelps/cc-html-output-mod --ref plugin-marketplace
codex plugin add html-output@nathanphelps
```

If Claude Code does not accept `@plugin-marketplace` on the source, use the full Git URL with `#plugin-marketplace`. Ask Nathan to trust the Codex hook again if Codex asks. Repeat the marker check on each tool (Task 2 Step 4 without `--plugin-dir`, Task 3 Step 5). Expected: the marker is quoted on both.

- [ ] **Step 2: Uninstall on both tools**

Run the uninstall commands from Task 2 Step 6 and Task 3 Step 7, and delete `~/.config/html-documents/`. Expected: neither tool lists the plugin or the marketplace.

- [ ] **Step 3: Confirm the working tree and the global files**

Run: `git status --short` → expected empty. `git log --oneline main..plugin-marketplace` → the commits from Tasks 1 to 5.
Confirm `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` are unchanged by comparing their modification times with the start of the work.

- [ ] **Step 4: Report to Nathan**

State: the branch name and its CI status; the answer found for each row of the spec's "Unverified facts" table, and which fallbacks were applied; anything that failed or was skipped; that the branch is unmerged and merging it ships to users; that the design document and this plan are committed on the branch under `docs/superpowers/` and he may want them removed before merging; and that his own machine has the rule pasted globally, so installing the plugin there gives him the rule twice unless he removes the pasted copy.
