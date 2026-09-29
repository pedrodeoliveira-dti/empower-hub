# Worker Forms

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a hiring client push a structured evaluation/questionnaire to a contractor's worker (e.g. safety self-certifications, equipment checklists). The worker answers a sequence of typed questions, reviews all answers, and submits the form; clients/admins may also contribute answers for certain categories, and can send it back with feedback for the worker to update. Solves "get compliance/onboarding data directly from the field worker, structured and auditable, without paper forms."

## User journey

1. **List**: pick a connected contractor company if more than one; forms grouped by owner, each with a status banner (start/continue/reassigned/expired/complete).
2. **Details**: metadata, a privacy notice (shown only when a response is required and nothing has been answered yet), and a read-only "Answers" section grouped by who answered (worker/client/admin).
3. **Start/Continue → Questions**: one question per screen. **Resume logic** (same 3-tier rule, independently implemented on both platforms):
   - No answers yet → start at question 1.
   - Some answered → jump to the first unanswered **required**, non-instruction question.
   - All required answered, some optional unanswered → jump to the **last** unanswered non-instruction question.
   - Everything answered → go straight to Review.
4. Each answer is submitted **as soon as the user taps Next** (per-question, not batched) — except instruction items (no answer captured) and unchanged/skipped optional items, which just advance locally.
5. **Review**: lists all non-instruction questions with answers, flags any unanswered mandatory ones, lets the user edit any answer, then Submit (or "Submit Update" if reassigned).
6. If a client sends the form back with feedback, the worker sees a "Form reassigned to you" banner with the client's comment and an "Edit My Answers" entry point instead of Start/Continue.

## Item/response-type pattern

A form is a flat list of typed **items** across **categories**. Item types (identical on both platforms):

| Type | Notes |
|---|---|
| `single_select` | exactly 1 selection |
| `multi_select` | 1+ selections, min/max count configurable |
| `free_text` | allow-list regex + min/max length configurable |
| `numeric` | min/max int configurable |
| `date` | min/max date bounds configurable |
| `email` | allow-list regex; **validated only on Next/submit tap, not per keystroke** — confirmed identical on both platforms |
| `instruction` | description-only, no response, but still advances the flow/counts as "answered" |

Every type except `instruction` can independently be marked **"Not Applicable,"** clearing/ignoring the type-specific answer.

## Business rules / validation

- **Category roles gate who can answer what**: `worker_only`, `client_only`, `admin_only`, `worker_and_admin` — the worker only sees/answers worker-eligible categories while a form is in progress; a `COMPLETE`/`EXPIRED` form shows everything unfiltered.
- **Statuses**: `complete`, `response_required`, `pending_others` (waiting on hiring client), `pending_future` (not yet the worker's turn), `expired` — banner/footer visibility is entirely status-driven.
- **Mandatory-answer gate on submit**: Review disables/warns Submit if any required, non-N/A question lacks an answer.
- **Per-question submission, not batch**: matches both platforms; Submit at Review is a separate, final "lock it in" call.
- **Unchanged-answer optimization**: revisiting a question that resolves to the same stored answer makes no network call.
- **Privacy notice** only appears on first-time entry (response required, nothing answered yet).
- **No PDF/export flow was found** for Worker Forms on either platform — unlike every sibling feature in this group ([Toolbox Talks](toolbox-talks.md), [Written Programs](written-programs.md), [Acknowledgements](acknowledgements.md)) which all have real PDF/document flows. **Worth flagging to the PO as either an intentional scope gap or a missing capability.**

## Screens

| Android | iOS |
|---|---|
| `list` | `List` |
| `details` | `Details` |
| `survey` (question wizard) | `Questions` (embeds Review as a sub-flow) |
| `review` | `Review` |
| `editanswer` | (part of `Questions`/`Review`) |

## Platform differences

- iOS presents Review as a modal/embedded state of the Questions flow; Android navigates to a distinct Review screen/route — functionally equivalent, structurally different.
- iOS explicitly tracks submitted item IDs locally as a defensive measure, with a code comment noting the server's contract for instruction-item responses is uncertain — no equivalent workaround documented on Android.
- iOS's Next button dynamically shows "Skip" for an unanswered optional question; this exact label nuance wasn't confirmed on Android's Compose UI layer (not read in this pass).

## Key user-facing strings

- *"The client needs your answers. Please respond to the evaluation so they can review your information."*
- *"Form reassigned to you — The client reviewed this form and is seeking additional feedback. Please review and update your responses as necessary."*
- *"You still have one or more mandatory questions unanswered. Provide response to submit."*
- *"Featured Questions — These are your client's priority questions. They will see these responses first, but they can also see the rest of your answers below."*

## Open questions for a PO

1. Confirm whether Worker Forms genuinely has no PDF/export capability, or whether it's planned/hidden behind an unenabled flag.
2. What triggers `pending_future` vs. `pending_others` from a business-process standpoint?
3. Does a "Not Applicable" answer count as "resolved" for audit/compliance purposes?
