---
name: orchestrate-feature
description: Cross-platform impact analysis before any spec work or implementation. Read-only.
---

# Orchestrate Feature

Invoke the `product-orchestrator` agent to analyze the feature, bug, or change described by the user, using its repo impact matrix, third-party contract impact, data/state impact, observability impact, testing strategy, implementation order, risks.

This is always the first step for any change that might span more than one repo. It is read-only: no files are modified, nothing is implemented, nothing is committed.

## Usage

```
/orchestrate-feature

Feature: <describe the feature, bug, or change here>
```

## After this command

If the orchestration plan recommends a hub-level spec, the next step is:

```
/speckit.specify
```

using the feature description and the orchestration plan's "Write the spec" section as input.

## Related command

If the change is already a specific Azure DevOps work item (not just a free-text feature description), consider `/orchestrate-pbi <id>` instead — it fetches the work item, archives it, and drives the rest of this same pipeline (specify → plan → tasks → implement) from that ID directly.
