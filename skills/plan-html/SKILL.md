---
name: plan-html
description: Deliver plans as a self-contained, collapsible HTML file (optionally with an index page linking previews/versions). Use when the user asks for a plan, design doc, proposal, or says "/plan-html".
---

# /plan-html

Plans are HTML, not markdown walls. Goal: skim in 30 seconds, drill down on demand.

## Rules
- One self-contained HTML file, no build step. Copy `template.html` from this skill folder as the base — don't reinvent styling.
- Top-level sections are `<details class="section">`: headline + short hint visible, detail inside. Key sections `open` by default, supporting detail collapsed. Nest `<details class="sub">` for finer detail.
- Lead with a recommendation (`.rec`) where there is a choice; list alternatives briefly.
- End with a "Decisions for you" section listing open questions.
- Write to `./plans/<slug>.html` in the current project.
- If the plan has multiple previews/mockups/versions: write each as its own HTML file and generate `./plans/index.html` linking the plan and every preview so the user can click between them.
- After writing, `open` the file (or the index) and print the absolute path(s).
