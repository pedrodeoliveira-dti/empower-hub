# Hazard Assistant

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs. Labelled "Beta Release" in-app on both platforms.

## Purpose

An AI-assisted, photo-based jobsite hazard-recognition tool. The worker photographs their work site; the AI writes a plain-language scene description for the worker to review/edit, then generates a structured **Hazard Analysis**: a list of hazards tagged by the 10 classic hazardous-energy-source categories (Gravity, Mechanical, Motion, Sound, Pressure, Radiation, Electrical, Temperature, Biological, Chemical), each with identified control measures (or a note that none could be identified), a risk-control score, and suggested [Toolbox Talk](toolbox-talks.md) topics/courses. It's a guided, JSA-style hazard sanity check a worker can run without a safety professional physically present.

## User journey

1. Entry from Home or Tools: *"Upload a job site image to get started"* / *"Take a photo and learn about job site hazards with AI."*
2. Take/pick photos, up to a **server-configured cap** (`config.maxImages`).
3. Android splits this into a distinct "Added Images" thumbnail-management screen; iOS combines photo-taking into the main screen and only pushes to a details screen once ≥1 photo exists — functionally identical, different screen boundary.
4. On submit, images are compressed and base64-encoded, then POSTed to create a **Scene Description**. If the server can't recognize any work activity, a **"No Work Activity Detected"** modal blocks progress.
5. **Review Description**: the AI-generated description is shown in an editable text field; the user must confirm they've reviewed/edited it before generating the analysis. Save/Generate is disabled while offline or blank.
6. "Generate Hazard Analysis" POSTs the (possibly edited) description. The same "invalid images or description" error can recur here as "Analysis Not Available."
7. **Results**: Total Hazards / Total Controls Identified, per-hazard energy-classification badges, control measures (or a "couldn't identify — use your best judgment" fallback), related Toolbox Talks, a shareable PDF.
8. **Feedback loop**: thumbs up/down. Down opens a "Tell us more" panel (server-configured checkbox list + free text with a character limit and allow-listed-character regex) before submitting a rating.
9. **Recents** (UI label; code internally calls this "Archived" on iOS): a searchable, paginated history, **retained 30 days** per the in-app copy, feedback controls hidden on historical entries.

## Business rules / validation

- **Max images**: server-configured (`HazardAssistantConfig.maxImages`); add/submit disabled at the cap or while offline.
- **Image size cap**: Android compresses to under 200 KB per image before upload; iOS compresses by a fixed JPEG quality factor with no explicit byte cap — **a real, if minor, platform difference in how the size constraint is enforced.**
- **`invalid_images_or_description` server error** is specifically handled — surfaced as "No Work Activity Detected" at submission and "Analysis Not Available" at generate-analysis, both distinct from the generic network-error dialog.
- **Save/Generate gating**: description must be non-blank AND device online.
- **Rating gating**: Send is enabled only when online, the free-text comment passes a character-limit and allow-listed-character check (both server-configured), and either a checkbox was picked or free text was written.
- **`isDirectControl` flag** on each hazard result distinguishes a positively-identified "direct control" from a merely-suggested/example one — drives which UI copy is shown. What server-side logic sets this flag is **not visible from the client.**
- **API versioning**: every Hazard Assistant endpoint is a flat `v1` — no version fragmentation, unlike [Quick Check](quick-check.md).
- **Retention**: the 30-day cutoff is server-driven, read from the API response — not hardcoded client-side, so it could change without a client release.
- No QR or qualification/training gating exists here — Hazard Assistant is a standalone AI tool, not a compliance record like Quick Check.

## Screens

| Android | iOS |
|---|---|
| `HazardAssistantFragment` (upload prompt) | `HazardAssistantView` (upload prompt, combined) |
| `AddedImagesFragment` (thumbnail management) | `HazardAssistantDetailsView` |
| `ReviewDescriptionFragment` | `ReviewDescriptionView` |
| `HazardAnalysisResultFragment` | `HazardAssistantResultsView` |
| `HazardAssistantRecentsFragment` | `HazardAssistantArchivedListView` (code name "Archived," UI string "Recents") |

## Platform differences

- **Screen structure**: Android splits upload-prompt and image-management into two screens; iOS combines them — same end state.
- **Compression strategy**: Android guarantees a max file size (200 KB); iOS guarantees a fixed JPEG quality regardless of resulting size — worth confirming with backend whether there's a target payload size the AI model expects both platforms to hit.
- **Feedback UI object**: iOS reuses a generic cross-feature `RateConfig`/`CommonProblemItem` component; Android appears to implement this more bespoke per-feature — worth checking if Android should adopt a shared component too.

## Key user-facing strings

- *"Upload a job site image to get started"* / *"Take a photo and learn about job site hazards with AI"*
- *"Take or upload up to %d photos of your work site."*
- *"We couldn't tell what's happening in this image. Please try again with a clearer or more relevant photo."*
- *"By tapping the button below, you confirm you have reviewed and modified the description as needed."*
- *"We couldn't identify any control measures based on the image(s) submitted. Please use your best judgment as you assess this hazard."*
- *"You don't have any recent Hazard Analyses. Once generated, you can access them here for 30 days."*

## Open questions for a PO

1. What determines `isDirectControl` server-side?
2. Why does iOS compress by JPEG quality while Android enforces an explicit byte cap — is there a shared target payload size expectation?
3. Is the 30-day retention meant to stay server-configurable, or should it become a fixed business rule?
4. Should Hazard Assistant ever gate on Quick Check-style qualifications (e.g. only show hazards relevant to a worker's certified equipment)? No such linkage exists today.

## Related

- [Toolbox Talks](toolbox-talks.md) — suggested from a hazard analysis's results.
- [Quick Check](quick-check.md) — the other major AI/compliance-adjacent feature, entirely independent of this one in the code.
