---
name: html-documents
description: Use when writing a plan, spec, brainstorm, option comparison, report, or other document that a person has to review, and it should be an HTML file instead of Markdown. Also use when the person finds one section of such a document awkward to edit and needs a small single-file editor with an export button, or when a project needs a rendered reference page of its design tokens and components (design_system.html).
---

# HTML documents

A person reviewing your work reads a rendered page more carefully than a long text file. A page can show what a screen will look like, how data moves, and how options compare side by side. Use that to help the person check your thinking before work continues. The goal is a document they can verify, and visual polish does not substitute for specific content.

This skill covers three jobs: review documents, throwaway editors, and a design system page.

## Get the content right first

A rendered page looks authoritative, so errors in it are more likely to be believed.

- When the document describes existing code, read the code: the models, routes, schema, configuration, and tests. Do not rely on older documentation that may no longer match.
- When it describes a library or an outside system, check current documentation instead of working from memory.
- When it describes a process the person told you about, ask about anything unclear before drawing it.
- Use real code excerpts and real values. Do not include placeholder text or unfinished sections. If something is unknown, say so in the document as an open question.

## Requirements for every file

- One file, with its own CSS and JavaScript embedded.
- Follow the person's instructions on loading libraries from the internet. If their instructions allow it, you may load well-known libraries from a CDN, such as a diagram library, a slide library, an icon set, or web fonts. Pin exact versions, and make sure the text is still readable if a library fails to load. If their instructions require files that work offline, or say nothing on the subject, load nothing from a remote server and draw mockups and diagrams with HTML, CSS, or inline SVG.
- Use plain semantic markup (headings in order, sections, lists, tables) so a later agent session can read and edit the file. Give diagrams and mockups a text label that says what they show.
- Support light and dark display settings, keep text contrast high, and make the layout readable on a narrow screen.
- Include print styles so the page can be saved as a PDF without navigation or cut-off content.
- Give code blocks a copy button when the person is likely to paste from them.
- Save the file where a Markdown version would have gone, with an `.html` extension. Tell the person the path, and open it in their browser if you can. Do not publish it to a hosted service unless asked.

## Choosing a form

Pick the form from the content and how it will be read. These are starting points; combine them when that serves the reader.

| Content | Form |
|---|---|
| A plan, guide, or reference someone reads through and returns to | One long page with section navigation |
| Several facets of one subject, or parts meant for different readers (a product spec and a technical spec) | Tabs or collapsible sections |
| A sequence presented to a group, or a tutorial with one idea per step | Slides, built with plain HTML and CSS, or with a slide library if remote libraries are allowed |
| A high-level overview of a system or process | Large diagrams with short annotations |
| Numbers that are compared or tracked | A summary row of figures, then tables or charts |

## Diagrams

Choose the diagram by what you are showing:

- tables and how they relate: an entity-relationship diagram
- a request or message passing between parts over time: a sequence diagram
- a decision or branching logic: a flowchart
- the stages something moves through: a state diagram
- the parts of a system and how they connect: an architecture diagram
- who does what in a process: lanes, one per role

Label every box and arrow. Use one notation throughout a document. Put each diagram beside the text it explains and give it a caption. Leave out a diagram that does not make something easier to understand.

## Review documents

**Comparing options.** Give every option the same structure so they can be compared: the problem it solves, a small mockup or diagram, why it fits, one risk, and its cost. Place the options side by side. Say which one you recommend and what would change that recommendation. Do not start building any of them.

**Before a full plan.** If requirements are unclear, ask the person about them first. A detailed plan built on a guess wastes their review.

**Writing a plan.** Include what the person needs in order to approve it:

- what the user will see, as a mockup with the new parts marked
- the flow of data or control, as a diagram
- each file by its real path, marked new or changed, with its purpose
- the interfaces or types other code will depend on, as code
- the steps, each with the command or check that shows it worked
- risks with their mitigations, and open questions

Add anything else that helps them understand the work, and leave out anything that does not. Add in-page navigation when the document is longer than a few screens. Choose the layout yourself.

**Check it before handing it over.** Fix these three failures if you find them:

| Failure | Fix |
|---|---|
| The page is the Markdown text with a stylesheet: headings and bullet lists only | Restructure it. Use cards or a grid for things being compared, a mockup for anything visual, and separate callouts for risks and recommendations |
| The page looks finished and the content is general | Replace general statements with file paths, data flow, code excerpts, and a named check for each step |
| The page is unstyled or broken when opened from disk | Embed the page's own CSS and JavaScript. If files must work offline, remove every remote reference; otherwise check that each library URL is valid and pinned to a version |

## Throwaway editors

Use this when the person wants to change a structured part of a document, such as a table of rules or a list of settings, and doing it through chat or by editing markup would be slow.

1. Collect the current data and find out the exact format it must be returned in (a Markdown table, JSON, an HTML fragment).
2. Build one HTML page for that data only. Provide controls to add, remove, reorder, and edit entries. Design the interface around this specific data.
3. Keep every field from the source, including fields you do not show.
4. Provide a copy button that exports the data in the original format. If a value is invalid, show the problem beside the field that caused it.
5. If the editing will take a while, store the state in the browser so a reload does not lose it.
6. Do not add a server, a login, a framework, or more than one page.

When the person pastes the export back, apply it to the main document, confirm the document still displays correctly, and delete the editor unless they want to keep it.

## Design system page

Use this when a project has an existing interface and future work should match it.

1. Read the code for colors, type sizes, spacing, corner radii, breakpoints, and the main components. Record the source file for each.
2. If sources disagree, for example a marketing site and an application that use different type, list the disagreements and ask which source decides. Do not pick one silently.
3. Write `design_system.html`. Display each token as it looks, and each main component in its sizes and states, including hover, focus, disabled, loading, and error. Show the source file path beside each one.
4. If the person wants to try variations, add controls for the properties in question. Start from the real values, display the current value, and provide a reset.
5. Save the file in the repository. Commit it only if asked.

In later work, read `design_system.html` before building interface code and reuse its tokens and components. If a request conflicts with the file, say so before writing code. Regenerate the file when the tokens or components change.

## Origin

These practices were described by Thariq Shihipar of the Claude Code team on the "How I AI" podcast, and written up as three workflows on the show's site:

- https://www.chatprd.ai/how-i-ai/workflows/create-interactive-html-project-plans-with-ai-for-better-visualization
- https://www.chatprd.ai/how-i-ai/workflows/build-disposable-micro-apps-with-ai-to-edit-complex-plans
- https://www.chatprd.ai/how-i-ai/workflows/generate-a-living-html-design-system-with-ai-for-ui-consistency
