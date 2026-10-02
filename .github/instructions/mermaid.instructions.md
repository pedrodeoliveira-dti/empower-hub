---
applyTo: "**"
---
# Mermaid AI Skills

When the user asks to create, edit, or visualize any diagram, use the Mermaid
VS Code extension tools and commands described below. For what a hub diagram
should contain, see `.claude/skills/architecture-diagrams/SKILL.md`.

## Workflow

1. Determine the diagram type and generate Mermaid syntax.
2. Write the diagram to a `.mmd` file, or embed it as a fenced `mermaid` block
   in the artifact it supports (spec, plan, `pr-evidence.md`).
3. Validate syntax: correct first-line keyword, arrow types, balanced brackets.
4. Preview via the Mermaid extension - open the `.mmd` file (auto-preview) or run
   **MermaidChart: Preview Diagram** (`mermaidChart.preview`).

## LM Tools - call these for every diagram interaction

- `mermaid-diagram-validator` - validate Mermaid syntax before presenting any diagram
- `mermaid-diagram-preview` - render a live preview inside VS Code after generating
- `get-syntax-docs-mermaid` - fetch correct syntax docs for any diagram type

## VS Code Commands

Invoke via Command Palette or the VS Code command API (GitHub Copilot in VS Code only).
Do not invent command IDs. Prefer writing/editing `.mmd` files when a command is not needed.

### Diagram editing & preview
- **Preview** (`mermaidChart.preview`) - preview the active Mermaid editor (`.mmd` / `.mermaid` must be open).
- **Create Diagram** (`mermaidChart.createMermaidFile`) - creates a demo flowchart and opens preview side by side.
- **Repair Diagram** (`mermaidChart.repairDiagram`) - Mermaid AI repair for the active diagram; uses Mermaid AI credits - tell the user before running.
- **Improve Diagram** (`mermaidChart.improveDiagram`) - uses Copilot / LM API; suggests layout + styling variants for the active diagram.

### Mermaid Chart cloud
- **Login** (`mermaidChart.login`) / **Logout** (`mermaidChart.logout`)
- **Connect Diagram** (`mermaidChart.connectDiagramToMermaidChart`) - link a local diagram to Mermaid Chart.
- **Sync Diagram** (`mermaidChart.syncDiagramWithMermaid`) - only for diagrams already connected (frontmatter has `id:`).

### Install / update this pack
- **MermaidChart: Install AI Skills...** (`mermaidChart.installAiSkills`)

## Rules

1. Always call `mermaid-diagram-validator` before showing any diagram.
2. Always call `mermaid-diagram-preview` after generating a diagram.
3. Use `get-syntax-docs-mermaid` before generating an unfamiliar diagram type.
4. Never return unvalidated Mermaid syntax.
5. Warn the user before Repair (Mermaid AI credits).
6. Do not manually rewrite diagrams managed by Mermaid Chart sync.
7. Hub diagrams show flow and impact only - no product source code, secrets, or real user data.

## Docs

More commands and features: https://marketplace.visualstudio.com/items?itemName=MermaidChart.vscode-mermaid-chart
