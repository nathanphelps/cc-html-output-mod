# Document format

Write documents meant for me to read as HTML, not Markdown. This covers plans, specs, design docs, brainstorms and option comparisons, reports, research findings, reviews, status files, handoffs, roadmaps, and standalone documentation. I stop reading long Markdown, and I need to review this material before work continues. A chat reply of these kinds that would run past about one screen is also written as an HTML file, with a short summary and the file path in chat.

Keep Markdown where something requires it: files a tool loads by name or format (CLAUDE.md, AGENTS.md, SKILL.md, memory files), README.md and CHANGELOG.md, files a skill tells you to write as .md for another agent to execute, and repositories that already keep their docs in Markdown.

Each HTML document is one self-contained file: CSS and JavaScript embedded, no remote dependencies unless needed, and plain semantic markup so a later agent can read and edit it. Save it where the Markdown file would have gone, with an .html extension, and open it in my default browser when you can. Do not publish it to a hosted service unless I ask. Use mockups, diagrams, code excerpts, tabs, or whatever else helps me understand and check the content; the layout is your call. When a section is awkward to edit by hand, offer a small throwaway editor page with a copy button that exports the result for pasting back.
