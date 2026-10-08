# Evidence custody manifest and protected NTFS laboratory — EAGLT02

**Date:** 9 October 2026 · **Local development only** · **No real applicant upload**

## Implemented: metadata-only SQL custody record

Migration `supabase/migrations/20261009060000_custody_manifest_metadata.sql` is applied to local EAGLT02 Supabase ONLY. It adds `public.staged_evidence_custody_manifests`, one row per pre-existing server claim receipt, tied to claim/intent/applicant/application/check identities with foreign keys and exact RPC validation.

A restricted `record_staged_evidence_custody_manifest` RPC requires `service_role`; `anon` and `authenticated` cannot execute it and have no read or write access to the table. The RPC checks a non-withdrawn `claimed_for_quarantine` intent and an active planned requirement before accepting one metadata entry. Duplicate records cannot replace the original hashes. The recorded state is **always** `pending_independent_reconciliation`. There is **no read/release/approved state transition**, no Storage object policies and no applicant/backend HTTP intake.

The metadata contains a 64-character SHA-256 plaintext digest, a separate ciphertext-envelope SHA-256 digest, bounded byte counts, allowlisted MIME, non-secret encryption-key version identifier, and immutable one-time claim associations. **It does not contain ciphertext, file paths, plaintext filenames, actual encryption keys, login tokens, consent or applicant documents.**

An authorised server could still supply false digests; this metadata row is **not proof that a file exists or was scanned**, and a PostgreSQL insert cannot atomically commit an NTFS file. It is a **durable local database record**, not a completed cross-system custody transaction, append-only off-host audit or permission to verify a provider.

## Implemented: synthetic envelope-to-metadata proposal

`buildOfflineCustodyManifestProposal` in `packages/evidence_scanner/src/custody.mjs` verifies a **synthetic-only** sealed WQE2 envelope against the supplied key and exact claim binding, and returns the exact parameter field names expected by the SQL RPC. It **does not call the RPC**, use a service key, trust a client, move files, grant access or handle real documents. Its existing temporary-directory restriction and explicit `OFFLINE_SYNTHETIC_FIXTURE_ONLY` mode remain. It rejects altered envelopes/wrong keys and never returns document contents.

## Implemented: read-only Windows ACL audit and separate empty lab

`scripts/verify-evidence-vault-acl.ps1` is a **read-only EAGLT02 Windows NTFS ACL auditor**. It checks local-drive NTFS, existing non-reparse directory, disabled ACL inheritance and exactly two explicit FullControl grants: the executing Windows account and SYSTEM. No Users/Everyone/Authenticated Users/Administrators grants are accepted. It is not an installer, network service or production vault acceptance.

For an isolated, **empty** laboratory only, created:

`D:\Wantok_Project_Backups\Private_Evidence_Custody_Lab_20261009`

The folder has explicit grants to `EAGLT02\Mansfield` and `NT AUTHORITY\SYSTEM`, inheritance disabled, and zero files. The read-only verifier reported `EVIDENCE_VAULT_ACL_LAB_PASS`; it correctly rejected the ordinary repository path with inherited permissions. **Not yet tested:** negative logon under an independent account, service-identity separation, ACL tamper resistance, child-file ACLs under workloads, reparse-point race attacks, application-sandbox control, backup/restore or power-loss recovery.

## Verification and rollback

- `npm run db:test`: **35 SQL files / 767 pgTAP assertions PASS**, including the new role/claim/digest/no-Storage tests. pgTAP data changes are rolled back; no genuine applicant evidence was created.
- `npm run test:evidence`: **73 PASS**; `npm run test:evidence:real`: **6 PASS** (actual ClamAV plus EICAR).
- Required Flutter regression is recorded in `docs/HANDOVER.md` after completion.
- Private pre-migration PostgreSQL archive: `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-pre-custody-manifest-20261009.dump`. Post-migration archive: same folder, `wantok-post-custody-manifest-20261009.dump`. Verified `pg_restore -l` table-of-contents only; **NOT a full restore rehearsal**. Directory ACL limits the archives to SYSTEM and Mansfield. Keep separate GitHub feature checkpoint and verified local Git bundle.
- No production, Flutter UI, account, demo/smoke fixture, GVE or Wantok Neurons changes. The `staged-provider-evidence` Storage bucket is still sealed with **no ordinary user object policies**.

## Remaining production blockers

Proper approval of privacy/consent and retention, stronger authenticated GoTrue-to-claim-to-file service, durable transactional outbox and independent digest reconciliation, dedicated service principal and verified storage ownership, managed encryption-key lifecycle, isolated content decoder/normalisation, scanner health/version assurance, tamper-evident off-host audit, legal hold/deletion, least-privilege human reviewer release, concurrency and real crash/restore drills. **No upload route should be enabled before independent security acceptance.**
