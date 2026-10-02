---
name: drawio-diagram-generation
description: Generate diagrams.net / draw.io compatible mxGraphModel XML for architecture, integration maps, system context and dependency diagrams in Empower discovery or planning work. Use only when the user asks for a draw.io file or a visual that Mermaid cannot express well.
---

# Draw.io Diagram Generation

Generates draw.io XML for hub documentation. Default to Mermaid (see `architecture-diagrams`) when the diagram lives inside a spec, plan or `pr-evidence.md`; use draw.io when the user asks for a `.drawio` file or the map is too large for Mermaid. Flow and integration only: no product code structure.

## Before generating

- Do not generate a diagram when text is enough.
- Name the question the diagram answers and its scope: which of `MyIsn.Android`, `MyIsn.iOS`, `Mockoon` and which third-party services.
- Ground nodes in `docs/architecture.md`, `docs/cross-platform-flows.md` and `docs/api-contracts.md`. Anything unconfirmed is shown as `Unknown` or left out, never invented.
- Lean policy: one file, and only if requested. Ask first when it would be the third file in the change. See [`docs/lean-artifact-policy.md`](../../../docs/lean-artifact-policy.md).

## Output contract

- Valid `mxGraphModel` XML in a single fenced `xml` block, or saved as `<name>.drawio` next to the artifact it supports.
- Include the mandatory root cells `id="0"` and `id="1" parent="0"`.
- Every cell has a unique `id`; every vertex has `vertex="1"` and an `mxGeometry` with `as="geometry"`; every edge has `edge="1"`, `source` and `target`.
- Use a left-to-right grid, about 40 px spacing, no overlapping shapes, short labels.
- Escape `&`, `<`, `>` and quotes in labels.
- No secrets, tokens, real user data or internal URLs.

## Style conventions

| Element | Style hint |
|---|---|
| Mobile app (Android, iOS) | `rounded=1;whiteSpace=wrap;html=1;` |
| Mock or internal service (Mockoon) | `shape=cylinder3;whiteSpace=wrap;html=1;` |
| External third-party | `rounded=1;dashed=1;whiteSpace=wrap;html=1;` |
| Sync call | solid edge, `endArrow=classic;html=1;` |
| Async or optional | `dashed=1;endArrow=classic;html=1;` |

Label every edge with the action or contract.

## Skeleton

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="app" value="Android app" style="rounded=1;whiteSpace=wrap;html=1;" vertex="1" parent="1">
      <mxGeometry x="40" y="40" width="140" height="60" as="geometry"/>
    </mxCell>
    <mxCell id="svc" value="Third-party service" style="rounded=1;dashed=1;whiteSpace=wrap;html=1;" vertex="1" parent="1">
      <mxGeometry x="280" y="40" width="160" height="60" as="geometry"/>
    </mxCell>
    <mxCell id="e1" value="request" style="endArrow=classic;html=1;" edge="1" parent="1" source="app" target="svc">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

## Before presenting

Check unique ids, valid `source`/`target` references, balanced tags, and that the diagram matches the artifact it supports. State any assumption as an Open Question.
