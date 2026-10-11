# E6H — Enterprise Self-Review and Clearance Independence

**Date:** 11 October 2026. **Owner:** E6 Operations security engineering on EAGLT02.
**Current status:** security migration and rollback-only pgTAP regression verified. The E6H migration is **NOT applied** to the existing local database, staging VM, or production. Formal E6 human acceptance remains **OPEN**.

## Gap found in source review

The existing `has_operations_staged_scope` already rejects an application whose `user_id` equals the JWT caller, while `has_operations_case_scope` for enterprise intake (most recently defined by E6F migration `20261011232000`) did **not** check `vendor_intake_cases.applicant_id<>auth.uid()`. Other mutating enterprise RPCs checked self-review individually; however the generic case-scope helper was also used by RLS and read queries. A provider who later received an Operations case duty could therefore be treated as internal staff for their own case reads. That is an independence gap even though specific review RPCs carried additional guards.

A separate clearance issue existed: `revoke_vendor_activation_clearance` denied previous clearance identity reviewers and approving officers, but `has_operations_clearance_scope` allowed a suitably duty-granted former reviewer to list/read the clearance through the safety investigator path. Revocation protection alone was insufficient to deny conflicted reads.

## Additive code change

Migration `supabase/migrations/20261011233000_operations_independent_case_review.sql` replaces only:
1. `has_operations_case_scope(text,uuid)`: preserves active country/region/category duty, trusted category map, enabled registered region and immutable recusal. Adds `c.applicant_id<>auth.uid()` for **all** case-reviewer, evidence-officer and investigator duties.
2. `has_operations_clearance_scope(text,uuid)`: preserves evidence-case-to-provider identity equality and independent safety duty. Adds explicit exclusions for applicant, `identity_reviewer` and `approving_officer` **at the read/scope layer**, not just the emergency revocation RPC.

No new CRUD, evidence ingestion, final KYC, paid service activation, authoriser seeding, or web admin privilege was introduced. These functions must not automatically mark unverified free-text jurisdiction as approved.

## Verified local regressions

`npm run test:e6:independence-local` uses fixed local Docker `supabase_db_wantok-service`, a `--local` guard, a single SQL transaction containing the **pending** E6H migration and one rollback-only pgTAP fixture per run. Each pgTAP file contains its own `ROLLBACK;`; the outer transaction is also discarded. No schema changes persist, no real accounts or applicants are created and no database reset occurs.

| Synthetic pgTAP test | Results |
| --- | ---: |
| 051: case jurisdiction | 35/35 PASS |
| 052: safety clearance | 34/34 PASS |
| 056: immutable case recusal | 18/18 PASS |
| **057: new independent case review and clearance reads** | **19/19 PASS** |
| **Total** | **106/106 PASS** |

New tests verify: applicant with a synthetic `case_reviewer` and `safety_investigator` duty is **still denied** on their own enterprise case; provider cannot read own clearance or revoke; the prior identity reviewer and approving officer cannot read that clearance through a newly held safety duty; unrelated staff retain normal permissions; applicant-owned read continues; anonymous and unsupported final-approval paths remain denied.

**Integration limitation:** the shared current branch also has independently owned T2.4 migrations `20261011240000` and `20261011241000` that are not applied to the local database. Consequently E6H deliberately does not run general `npm run db:migrate` or claim that all current tests pass. Coordinate the T2.4 developer and approved migration/backup sequencing before applying E6H or any other pending migration.

## Human and remaining approval gates

Formal E6-G1–G10 are **BLOCKED** pending real independently appointed staff identities, current ISO country/subdivision/legal proof, beneficial-owner and related-party checks, witnessed separate GoTrue logins/role isolation, key custody, negative privilege review, recovery audit and product owner/security acceptance. See `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`.

Do **not** deploy to the online VM, activate vendors, collect identity images or make payments. This checkpoint is a source-only improvement, not E6 sign-off or authorisation to start E7.
