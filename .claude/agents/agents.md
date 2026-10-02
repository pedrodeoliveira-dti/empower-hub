# Agent Catalog

Sub-agents available in this hub. Each is backed by a command or skill; none
needs to be called directly unless noted.

| Agent | Backs | Use | Edits files? |
|---|---|---|---|
| [`product-orchestrator`](product-orchestrator.agent.md) | `/orchestrate-feature` | Cross-platform impact analysis across `MyIsn.Android`, `MyIsn.iOS`, and `Mockoon` before any implementation | No (read-only) |
| [`code-reviewer`](code-reviewer.agent.md) | `/speckit.review` Stage 2 | Diff-level code review of one repo against the artifacts, repo standards, style guide, observability, and contracts | No (read-only) |
| [`qa-reviewer`](qa-reviewer.agent.md) | `/speckit.review` Stage 3 | Acceptance criteria traced to tests/evidence; security considerations verified; spec drift | No (read-only) |
| [`cross-platform-reviewer`](cross-platform-reviewer.agent.md) | `/speckit.review` (multi-repo changes) | Android vs. iOS vs. Mockoon drift in behavior, flags, contract, analytics | No (read-only) |
| [`current-state-analyzer`](current-state-analyzer.agent.md) | `specs/technical-refinement/*/current-state.md` | Read-only analysis of how a feature/module is implemented today across the repos | No (read-only) |
| [`documentation-maintainer`](documentation-maintainer.agent.md) | `/sync-context` | Deeper doc drift analysis; proposes fixes, not a second governance authority | No (proposes only) |
| [`code-refactor-planner`](code-refactor-planner.agent.md) | `safe-refactoring` skill | Plans behavior-preserving refactors for one repo | No (plan only) |

None of the three review agents sets the verdict — only `/speckit.review` does, after synthesizing them.

When adding an agent: add a row here and an entry in
[`docs/release-notes.md`](../../docs/release-notes.md). Size guidance:
[`docs/lean-artifact-policy.md`](../../docs/lean-artifact-policy.md).
