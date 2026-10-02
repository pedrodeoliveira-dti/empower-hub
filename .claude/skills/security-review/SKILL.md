---
name: security-review
description: Manual mobile security lens for specs, plans, and reviews in the Empower hub — token and session storage, biometrics, Jumio/KYC and ISN ID wallet data, geolocation permission, deep links, logging and PII, third-party SDKs. Manual only; never run a scanner. Use when a change touches any of these or when security considerations must be verified.
---

# Security Review (manual)

Security is a dimension of every change ([Constitution §10](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#10-security-and-privacy-rules)). This skill is the reading lens; it is **manual and spec-driven** and never runs, invokes, or simulates an automated scanner ([Constitution §5](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#5-operational-invariants)). It adds no gate. Used by `qa-reviewer` and `code-reviewer`, and when writing a spec's security considerations.

## Verdicts

Per item: `verified` (evidence found, name it), `not verified` (looked, evidence absent), or `unable to verify` (could not inspect; say why). Never a guess. Say whether the finding is static inspection or a confirmed run.

## Lens

| Area | Ask |
|---|---|
| Tokens and session | Where are access/refresh tokens stored (secure storage vs. plain prefs/defaults)? Cleared on logout and account deletion? Sent only to intended hosts? Behavior on expiry |
| Biometrics and local auth | Is it a gate on the sensitive action itself, with a defined fallback and no bypass when the check is unavailable or fails? |
| Jumio / KYC and ISN ID wallet | Is identity or document data kept off logs, screenshots, and caches? What is retained on-device, and for how long? Is the wallet card / QR content exposed beyond need? |
| Geolocation | Permission requested at point of need, with each state handled (denied, while-in-use only, revoked). No more precision or frequency than required; location not logged |
| Deep links and dynamic links | Are parameters validated and treated as untrusted? Can a link reach an authenticated screen or action without auth? No sensitive data in the URL |
| Logging and PII | Nothing on the never-log list ([Constitution §7](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#7-third-party-contracts-observability-and-security)); masking and known risks per [`docs/observability.md`](../../../docs/observability.md). This also applies to examples written into hub artifacts |
| Third-party SDKs | New or upgraded SDK: what data does it collect or transmit, what permissions does it add, does it match [`docs/api-contracts.md`](../../../docs/api-contracts.md) and existing consent behavior? |
| Input and files | Untrusted input validated at the boundary; uploaded documents and certificates checked for type/size; worker form data not persisted longer than needed |
| Mock vs. production | Mock environments, debug tooling, and test certificates cannot leak into production builds |

## Method

1. Start from the spec's security considerations; add the rows above that the change touches even if the spec omitted them.
2. Find the code or test that proves each item (`graphify query` first if a graph exists), in the correct repo; one platform never vouches for the other.
3. Record verdicts in the review output or `pr-evidence.md`; a risk acceptance is written there with who accepted it.
4. Leaking something sensitive is always at least a Must Fix. Never copy a real secret or PII into a finding; cite file and line.

## Output

```markdown
Security considerations — <repo>
| Item | Verdict | What was checked (file / test) |
|---|---|---|
```

Feed the table into `/speckit.review` Stage 3; the verdict stays with that command.

## Rules

- Mandatory when the change touches login, tokens, ISN ID wallet, Jumio/KYC, geolocation, documents, certificates, or PII, even if the spec listed nothing.
- Do not edit CI/CD, signing, or secrets configuration as a "fix"; report it ([Constitution §5](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#5-operational-invariants)).
