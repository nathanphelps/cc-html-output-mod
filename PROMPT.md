# Install prompt: HTML output rule for Claude Code and Codex

Paste this whole file into a Claude Code or Codex session. Everything below the line is addressed to the agent.

---

I want you to install a standing instruction on this machine that makes coding agents write documents meant for me as HTML files instead of Markdown. Work through the steps below in order. Steps 2, 3, 4, and 7 are questions for me: ask each one, wait for my answer, and do not choose for me. Do not change any file before step 5.

## The rule to install

<!-- rule:start -->
# Document format

Write documents meant for me to read as HTML, not Markdown. This covers plans, specs, design docs, brainstorms and option comparisons, reports, research findings, reviews, status files, handoffs, roadmaps, and standalone documentation. I stop reading long Markdown, and I need to review this material before work continues. A chat reply of these kinds that would run past about one screen is also written as an HTML file, with a short summary and the file path in chat.

Keep Markdown where something requires it: files a tool loads by name or format (CLAUDE.md, AGENTS.md, SKILL.md, memory files), README.md and CHANGELOG.md, files a skill tells you to write as .md for another agent to execute, and additions to an existing set of Markdown documentation in a repository.

Each HTML document is one self-contained file: CSS and JavaScript embedded, no remote dependencies unless needed, and plain semantic markup so a later agent can read and edit it. Save it where the Markdown file would have gone, with an .html extension, and open it in my default browser when you can. Do not publish it to a hosted service unless I ask. Use mockups, diagrams, code excerpts, tabs, or whatever else helps me understand and check the content; the layout is your call. When a section is awkward to edit by hand, offer a small throwaway editor page with a copy button that exports the result for pasting back.
<!-- rule:end -->

## Step 1: Look at what I have

Do not create or change anything yet. On Windows, `~` means my user profile folder.

Check which tools are installed: whether the `claude` and `codex` commands exist, and whether the folders `~/.claude` and `~/.codex` exist.

Read these files if they exist:

- `~/.claude/CLAUDE.md` (Claude Code's user-level instructions)
- `~/.codex/AGENTS.md` and `~/.codex/AGENTS.override.md` (Codex's user-level instructions)

Then tell me, briefly:

- which tools are installed, which of these files exist, and roughly how long each is
- whether `CLAUDE.md` and `AGENTS.md` have the same content, overlapping content, or unrelated content
- whether any file already has a "Document format" section, or any other instruction about output format that would conflict with the rule
- whether `CLAUDE.md` already uses `@` imports
- whether `~/.codex/AGENTS.override.md` exists and is not empty. If it does, Codex reads it in place of `AGENTS.md`, so a rule added to `AGENTS.md` would have no effect. Ask me whether to install into the override file instead.

## Step 2: Ask which tools

Ask whether to install for Claude Code, Codex, or both. Offer the tools you found in step 1, and let me say otherwise.

## Step 3: Ask which install method

Describe all of the methods that fit my answer to step 2, each with its trade-off, and ask me to pick. Do not recommend one unless I ask for your opinion.

Two facts decide what is possible. Claude Code expands `@path` imports inside `CLAUDE.md`. Codex reads `AGENTS.md` as plain text and does not expand imports, so any method that relies on an import works for Claude Code only.

1. **Paste the section into each global file.** Add the rule to `~/.claude/CLAUDE.md`, to `~/.codex/AGENTS.md`, or to both. Works for one tool or two and depends on nothing else. With two tools, the rule exists in two places and later edits have to be made twice.
2. **One shared file.** `~/.codex/AGENTS.md` holds my user-level instructions, including the rule, and `~/.claude/CLAUDE.md` starts with one line that imports it (`@~/.codex/AGENTS.md`). Both tools only. I edit one file from then on. Instructions meant for Claude Code alone stay in `CLAUDE.md` below the import line. If the import ever stops working, Claude Code loses the shared instructions without an error.
3. **A standalone rule file.** Save the rule as its own file and leave my existing `CLAUDE.md` content where it is. For Claude Code, a file placed in `~/.claude/rules/` is loaded at user level with no import line; a file placed anywhere else needs one `@` import line added to `~/.claude/CLAUDE.md`. For Codex the rule text still has to be pasted into `~/.codex/AGENTS.md`, so with two tools there are two copies.
4. **One project only.** Add the rule to a single repository's instruction file and leave my user-level files alone. The rule then applies only inside that repository, and to anyone else who uses the repository if the file is committed.

One more trade-off for methods 2 and 3 when they use an `@` import: some Claude environments, such as Cowork sessions in the desktop app, skip user-level imports that point outside the working folder, so the rule would not load there.

If I pick method 4, ask which repository. List the instruction files that exist in it and tell me which file each tool will read there. Codex reads `AGENTS.md`. Claude Code reads `CLAUDE.md`, and recent versions read `AGENTS.md` when the repository has no `CLAUDE.md`; check this for my version before choosing the file. Do not commit anything unless I ask.

## Step 4: Ask about the wording

Show me the rule text. Then ask me this question, describe both answers with their trade-offs, and do not choose for me:

**May documents load libraries from the internet?**

- **No, every file works offline.** Diagrams and mockups are drawn with HTML, CSS, and inline SVG. Files open anywhere, keep working years later, and send nothing to a third party when opened. Complex diagrams and slide decks take the agent more effort and more tokens, and can look plainer. This is the wording in the rule text above.
- **Yes, well-known libraries from a CDN are allowed.** The agent can use a diagram library, a slide library, an icon set, or web fonts. Complex diagrams and presentations are quicker to produce. Files need a network connection to display fully, can break if the CDN changes, and contact the CDN each time they are opened. For this answer, replace the first sentence of the rule's third paragraph with these two sentences:

  > Each HTML document is one file with its own CSS and JavaScript embedded and plain semantic markup so a later agent can read and edit it. Well-known libraries may be loaded from a CDN when they help, such as Mermaid for diagrams, Reveal.js for slides, an icon set, or web fonts; pin exact versions.

Then ask whether I want to change any of these:

- which document types it covers
- which files stay Markdown
- the "about one screen" threshold for long chat replies
- opening the file in my browser
- the ban on publishing to a hosted service

Apply what I ask for. Keep the rule short. Do not add requirements about page layout, section order, or styling: the rule deliberately leaves those to the agent writing the document.

## Step 5: Install

- Back up every file you are about to change by copying it beside the original with a `.bak-YYYYMMDD` suffix. If a backup with that name already exists, do not overwrite it; add the time to the new name. For method 4, put the backup outside the repository.
- If a target file already has a "Document format" section, show it to me and ask before replacing it. If I agree, replace it in place; do not add a second copy.
- If you reported a conflicting output-format instruction in step 1, ask whether to keep, edit, or remove it.
- If a target file does not exist, create it, but only for a tool I selected.
- For method 2:
  - If `CLAUDE.md` and `AGENTS.md` are identical, no merge is needed. If `AGENTS.md` does not exist, create it from the `CLAUDE.md` content.
  - If they differ, ask me which parts of `CLAUDE.md` are for Claude Code only. Those parts, and any existing `@` import lines, stay in `CLAUDE.md` below the new import line. Merge the rest into `AGENTS.md` without dropping anything.
  - Show me both resulting files and wait for my approval before you write them.
  - Tell me if the resulting `AGENTS.md` is larger than 32 KB, because Codex stops reading instruction files past that size by default.
- Change nothing else in these files.

## Step 6: Verify

For each tool you installed for, start a fresh non-interactive session and ask it to quote the first sentence of its "Document format" instruction. Run it from a folder that is not inside a project, except for method 4, where you run it from inside that repository. For example:

- `claude -p "Quote the first sentence under your 'Document format' instruction heading. If you have none, say NONE."`
- `codex exec --skip-git-repo-check "Quote the first sentence under your 'Document format' instruction heading. If you have none, say NONE."`

If you cannot run these, give me the commands to run myself. If an import written with `~` does not load, try the absolute path. If it still does not load, tell me, restore the backup, and ask which other method I want.

## Step 7: Offer the optional skill

Ask whether I also want the companion skill. Explain that the rule works without it, and that the skill adds longer instructions for writing HTML documents, throwaway editors, and a design system page, which load only when a task calls for them.

If I say yes, get the file from `https://raw.githubusercontent.com/nathanphelps/cc-html-output-mod/main/skills/html-documents/SKILL.md`, or from a local copy of the repository if I point you to one. Show me its contents before saving it. Then save it for the tools I selected in step 2:

- Claude Code: `~/.claude/skills/html-documents/SKILL.md`
- Codex: `~/.agents/skills/html-documents/SKILL.md`, the folder Codex's documentation names. If I already keep my Codex skills in `~/.codex/skills/`, which Codex also reads, ask me which folder to use.

If a skill with that name already exists, ask before replacing it.

## Step 8: Report

Tell me which files changed, which files are new, where the backups are, which method was used, and whether the skill was installed. Explain how to undo it: restore the backups for changed files, delete the files that are new, and delete the skill folder. Mention that restoring a backup also removes any edits I make to that file after today. Then suggest one way to try it: ask either tool for an implementation plan for a small feature and see what comes back.
