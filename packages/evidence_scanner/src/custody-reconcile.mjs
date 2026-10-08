// OFFLINE SYNTHETIC SNAPSHOT RECONCILIATION ONLY.
// No database client, network listener, file writes or release capability.
import { EvidenceError } from './scan.mjs';
import {
  inspectOfflineCustody, buildOfflineCustodyManifestProposal,
} from './custody.mjs';

const MODE = 'OFFLINE_SYNTHETIC_FIXTURE_ONLY';
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function deny() {
  throw new EvidenceError('CUSTODY_NOT_READY', 'Offline reconciliation denied');
}
function result(state, claimId, requiresManualReconciliation = true) {
  return Object.freeze({
    claimId,
    state,
    requiresManualReconciliation,
    storagePermitted: false,
    reviewerAccessPermitted: false,
    approved: false,
    uploadedToSupabase: false,
  });
}
function sameSnapshot(snapshot, proposal) {
  // Snapshot source is NOT trusted here: comparing cannot authenticate DB data.
  const fields = [
    ['claim_id','p_claim_id'],['intent_id','p_intent_id'],
    ['applicant_id','p_applicant_id'],['application_id','p_application_id'],
    ['check_id','p_check_id'],['plain_sha256','p_plain_sha256'],
    ['sealed_sha256','p_sealed_sha256'],['plain_bytes','p_plain_bytes'],
    ['sealed_bytes','p_sealed_bytes'],['mime','p_mime'],['key_id','p_key_id'],
  ];
  return snapshot?.state === 'pending_independent_reconciliation' &&
    snapshot?.envelope_version === 2 &&
    fields.every(([sql,rpc]) => snapshot[sql] === proposal[rpc]);
}
/**
 * Deterministic, read-only scratch reconciliation. A matching snapshot is
 * NEVER a release decision: no verified DB identity, off-host ledger or KMS.
 * Caller provides an UNTRUSTED copy of a record to test *consistency only*.
 */
export async function reconcileOfflineCustodySnapshot({
  mode, root, expected, keyId, key, snapshot, claimState,
}) {
  if (mode !== MODE || typeof expected?.claimId !== 'string' ||
      !UUID.test(expected.claimId) ||
      !['claimed_for_quarantine','withdrawn'].includes(claimState?.state)) deny();

  const inventory = await inspectOfflineCustody({root,claimId:expected.claimId});
  if (inventory.state !== 'sealed_candidate') {
    return result(
      inventory.state === 'absent' ? 'missing_sealed_candidate' :
      'interrupted_custody_requires_investigation', expected.claimId,
    );
  }
  if (claimState.state === 'withdrawn' || claimState.withdrawnAt != null) {
    return result('claim_withdrawn_no_release', expected.claimId);
  }
  if (snapshot == null) return result('missing_metadata_snapshot',expected.claimId);

  let proposal;
  try {
    proposal = await buildOfflineCustodyManifestProposal({
      mode, root, expected, keyId, key,
    });
  } catch {
    // No file paths, hashes, keys, or decryption failures in the public report.
    return result('sealed_integrity_requires_investigation',expected.claimId);
  }
  if (!sameSnapshot(snapshot,proposal)) {
    return result('metadata_mismatch_requires_investigation',expected.claimId);
  }
  return result('snapshot_matches_still_pending_independent_reconciliation',expected.claimId);
}
