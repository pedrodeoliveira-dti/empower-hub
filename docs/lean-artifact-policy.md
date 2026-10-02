# Lean Documentation and Artifact Policy

## Core Rule

**This hub is lean by default.**

Create the minimum useful artifact set. Avoid duplicate explanations
across files. Prefer concise tables and checklists over prose. Do not
create large documentation trees for a small workflow change. Ask before
large changes.

This applies to every `speckit.*` command, every skill, and every ad hoc
hub change — not just this policy's own creation.

## Artifact Minimalism

Hub workflows generate **one primary artifact per workflow step** by
default (`spec.md`, `plan.md`, `tasks.md`, `pr-evidence.md`). A second file
is created only when it meets one of these:

- it has a different audience (human reviewer vs. Claude execution context)
- it has a different lifecycle or a formal approval gate
- it will be reused independently
- it is too large to keep inside the primary artifact

Do not create a separate file that only repeats content from another
artifact, is an intermediate thought process, or can be represented as a
section in the primary artifact instead.

## File Creation Limits

**Default limit**: up to 2 files may be created or updated without
additional approval.

**Large update limit**: if more than 5 files would be changed, stop and
ask, verbatim:

```
This change affects more than 5 files.

I recommend applying it in smaller steps.

Do you want me to continue with the full update, or should I split it into phases?
```

Between 2 and 5 files: present a short file-update plan (file, create/update,
why) and ask for approval before editing.

## Duplication Rules

Do not repeat the same full explanation across `CLAUDE.md`, `README.md`,
a command file, and a skill file. Each artifact type owns one kind of
content:

| Artifact | Owns |
|---|---|
| Command file (`.claude/commands/speckit.*.md`) | Operational behavior for that stage |
| Skill file (`.claude/skills/*/SKILL.md`) | Reusable, cross-command rules |
| `docs/*.md` | Product/cross-platform reference material |
| `docs/governance/current-hub-decisions.md` | At-a-glance ledger of current decisions (index only) |
| `constitution/*.md` | Non-negotiable hub rules and the reasoning behind them |
| `CLAUDE.md` | Entry point — pointers to the above, not a restatement |

When two files would otherwise say the same thing, the owning file (per
the table above) keeps the real content; every other file links to it.

## Documentation Update Rule

Update a global file only when its specific trigger applies:

| File | Update only if... |
|---|---|
| `README.md` | A command, agent, or skill was added, removed, or changed how it is used |
| `docs/release-notes.md` | A new command, agent, skill, workflow, or major capability was created |
| `docs/governance/current-hub-decisions.md` | A governance decision changed |
| `constitution/EMPOWER-HUB-CONSTITUTION.md` | A non-negotiable rule changed |
| `constitution/ENGINEERING-PRINCIPLES.md` | An engineering principle changed |
| `CLAUDE.md` | A global behavior rule changed |

## Lean Mode

Any command may be invoked with these natural-language instructions:

- **`Run this in lean mode. Create the minimum files needed and ask
  before updating more than 2 files.`**
- **`Proposal only. Do not edit files yet.`** — produce a file-update plan
  and stop.
- **`Apply only the approved minimal changes.`** — after a proposal was
  reviewed, apply exactly the approved file set, nothing more.

Commands are not required to mention Lean Mode explicitly in their own
files — this policy applies hub-wide by default.

## Rules

- Do not remove or weaken safety rules or approval gates for the sake of
  being lean — see
  [`constitution/EMPOWER-HUB-CONSTITUTION.md`](../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates).
- Do not duplicate this policy's content into other files — link to it.
- Do not rewrite a file just to make its wording identical to another
  file; update only what actually changed.
