# Wantok Services — Enterprise Release Readiness Gates
**Working control register.** Updated October 2026. An item listed as complete
below means a **local functional/control foundation**, not production approval.

## Non-negotiable architecture
- Wantok Services is a modular, international, multi-country platform.
- Separate Customer, Vendor, Operations, and Technical Control roles.
- Version-controlled source, additive database migrations, bounded secrets,
  distinct app configuration and persistent production data.
- One versioned **installable/upgradeable Linux VM source release**, not manual
  EAGLT02 filesystem synchronisation or database replacement.
- Production environment, identity uploads and VM untouched until explicit
  go-live instruction and acceptance.

## Current acceptance matrix

| Area | Current status | Remaining hard gate |
| --- | --- | --- |
| Web apps and modular monorepo | Local working baseline | Cross-app auth/role audit, build and browser E2E |
| Flutter responsive client | Local regression covered | Physical mobile/tablet acceptance and accessibility |
| Operations (not Technical Control) | Local role gates/review modules | Scoped country/regional RBAC; separation of duties audit |
| Technical Control | Separate existing application | Theme/icon publish regression, audit and rollback acceptance |
| International provider location | Country/region discovery baseline | Maintained ISO country/subdivision catalogue, locale/currency/time-zone validation |
| Individual/business vendor intake | Preliminary, auditable local flow | Document checks, mandatory sector licences, applicant identity sourcing |
| Two-person procedural review | Local DB guard and audit | Reviewer competency, delegated authority, fraud/COI checks |
| Country privacy/compliance policies | Phase 2E **internal drafts** and independent review | Legal/regulator attestation, translation, effective notice approval, periodic review |
| Identity document request/preflight | Fail-closed, applicant-scoped | Secure ingress, consent, evidence upload, file review access |
| Scanner/encrypted custody | Offline synthetic/ClamAV tests | Sandbox, managed keys, private remote storage, atomic off-host ledger, recovery |
| Consent & rights | Not production implemented | Purpose-specific signed/versioned notices, withdrawal and DSR |
| Retention and deletion | Draft duration only | Legally approved retention engine, purge/legal hold/export and audit |
| Final KYC and vendor activation | Disabled by design | Independently verified evidence + externally authorised clearance |
| Fraud and safety | Revocation workflow local | Case correlation, risk scoring review, investigator RBAC, alerting |
| Dedicated Helpdesk | Not enterprise implemented | Ticket lifecycle, SLA, escalation, privacy segregation, complaints and appeals |
| Payments/settlement | Separate platform module | Jurisdiction legal checks, ledger/payout reconciliation and dispute controls |
| Observability/security | Not enterprise accepted | SIEM, admin audit integrity, rate limits, uptime, metrics, alerting |
| Backups/disaster recovery | VPS scripts and local package | Off-host encrypted backup, restore testing, RTO/RPO acceptance |
| VM package/install/upgrade | Versioned archive and verified installer inputs | Linux staging install, upgrade, downgrade strategy, restore rehearsal, signed release |
| Production go-live | **Not authorised** | Acceptance checklist and explicit decision by the owner |

## Release acceptance rules
A feature is **not** production-ready solely because source code exists,
its tests pass, or a Docker container builds. We require:
1. Documentation, security design and appropriate external approvals.
2. Role/tenant/jurisdiction isolation and threat-model tests.
3. Functional tests, realistic integration and UI acceptance.
4. Recoverable migration, secure backup and negative/revocation tests.
5. Operational runbooks, monitoring, fail-close behaviour and incident response.
6. Signed, immutable release artifacts and explicit deployment approval.

## Immediate engineering order
1. Country/region-scoped authorisation for Operations/Trust staff.
2. Country privacy notice and purpose-bound consent model, gated behind
   external legal approval; individual rights and retention workflows.
3. Hardened evidence gateway using current valid authentication, scanning,
   KMS and durable encrypted custody. Keep upload disabled until all gate tests.
4. Independent evidence verification, clearance issuance/revocation, expiry
   maintenance and appeals with investigator audits.
5. Separate enterprise Helpdesk, SLA and fraud/safety escalations.
6. International location/locale/currency/service eligibility hardening and
   cross-app E2E acceptance.
7. Run Linux staging installation, migrations, rollback/restore and monitoring
   drills **only when the owner authorises VM work**.

Work in the first six stages may proceed on EAGLT02; the VM remains untouched.
Keep unrelated changes owned by other development streams out of commits.
