# Contributing

Changes are welcome: to the rule, the skill, the hook, the install prompt, and the documentation. Open a pull request against `main`.

## What ships, and when

This repository is the plugin. There is no build step and no release step.

- **Claude Code.** The manifests in `.claude-plugin/` have no `version` field on purpose. Claude Code then treats each commit as a new version, so every merge to `main` reaches users the next time their plugin updates. Do not add a `version` field: with one, commits pushed without raising the number do not reach users. CI checks that the field is absent.
- **Codex.** `.codex-plugin/plugin.json` has a `version`. Raise it in any pull request that changes a file users receive: `html-output-rule.md`, anything in `hooks/` or `skills/`, or a manifest.

Because a merge is a release, keep unfinished work off `main`.

## Changing the rule

`html-output-rule.md` is the source of the rule. `PROMPT.md` contains a copy between the `<!-- rule:start -->` and `<!-- rule:end -->` markers, and the two must match. CI checks this.

Keep the rule short, and do not add requirements about page layout, section order, or styling. The README's "Changing the rule" section gives the reason.

## Testing a change

Run these from the repository root. On Windows, use Git Bash.

| Command | What it checks |
|---|---|
| `bash tests/test-hook.sh` | The hook prints the right file in each case: no override, an override, an empty override, a missing home folder, paths with spaces, and others. On Windows it runs the hook through `cmd.exe`, PowerShell, and Git Bash |
| `bash tests/check-rule-sync.sh` | The rule copy in `PROMPT.md` matches `html-output-rule.md` |
| `claude plugin validate .` | The Claude Code manifests. It reports the missing `version` as a warning, which is expected |

To try the plugin in a session without installing it:

```
claude --plugin-dir .
```

To try it on Codex, add your working tree as a marketplace, install from it, and trust the hook with `/hooks` in a session:

```
codex plugin marketplace add /path/to/your/clone
codex plugin add html-output@nathanphelps
```

After changing files, run `codex plugin add html-output@nathanphelps` again to copy them into Codex's plugin folder. Remove the marketplace when you are done, with `codex plugin remove html-output@nathanphelps` and `codex plugin marketplace remove nathanphelps`.

Both tools may already have the rule from your own `CLAUDE.md` or `AGENTS.md`. To see what the hook contributes, put a sentence you will recognise in `~/.config/html-documents/rule.md`, ask a new session to quote it, and delete the file afterwards.

## The hook script

`hooks/print-rule.cmd` is one file read by two interpreters: `cmd.exe` on Windows and a POSIX shell everywhere else. The comment at the top of the file explains how. When you change it:

- Keep LF line endings. `.gitattributes` enforces this, and the test checks it.
- Do not add `goto` or labels to the batch half. `cmd.exe` mishandles them in files with LF line endings.
- Do not depend on Node, Python, or Git Bash. Plain `cmd.exe` and plain `sh` must be enough.
- Print the rule text and nothing else, write nothing to standard error, and exit 0 in every case. A session without the rule is better than a session that starts with an error.
- Keep the executable bit set in Git. On Windows: `git update-index --chmod=+x hooks/print-rule.cmd`.

## What CI checks

`.github/workflows/check.yml` runs on every pull request:

- every manifest and hooks file is valid JSON, and the Claude Code manifests have no `version` field
- the rule copy in `PROMPT.md` matches `html-output-rule.md`
- `tests/test-hook.sh` passes on Ubuntu, macOS, and Windows
- `claude plugin validate .` passes
