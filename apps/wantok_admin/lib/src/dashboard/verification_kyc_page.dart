import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'staged_provider_review_page.dart';
import 'vendor_intake_queue_page.dart';
import 'vendor_clearance_status_page.dart';
import 'vendor_policy_governance_page.dart';

/// Read-only verification cockpit. These counts are not a KYC certification.
class VerificationKycSnapshot {
  const VerificationKycSnapshot({
    required this.providers,
    required this.staged,
  });
  final List<Map<String, dynamic>> providers, staged;
  static Future<VerificationKycSnapshot> load() async {
    final db = WantokBackend.client;
    final providers = await db
        .from('provider_profiles')
        .select('provider_id,display_name,verification_status,is_active')
        .order('created_at', ascending: false)
        .limit(100);
    final staged = await db
        .from('staged_provider_applications')
        .select('id,applicant_name,status,coverage_province,submitted_at')
        .order('submitted_at', ascending: false)
        .limit(100);
    return VerificationKycSnapshot(
      providers: (providers as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      staged: (staged as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

class VerificationKycPage extends StatefulWidget {
  const VerificationKycPage({super.key, this.loader});
  final Future<VerificationKycSnapshot> Function()? loader;
  @override
  State<VerificationKycPage> createState() => _VerificationKycPageState();
}

class _VerificationKycPageState extends State<VerificationKycPage> {
  late Future<VerificationKycSnapshot> _future =
      (widget.loader ?? VerificationKycSnapshot.load)();
  void _refresh() => setState(
    () => _future = (widget.loader ?? VerificationKycSnapshot.load)(),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<VerificationKycSnapshot>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 38,
                  color: WantokColors.primaryDark,
                ),
                const SizedBox(height: 10),
                const Text('Verification access unavailable'),
                const Text(
                  'The database permission policy controls this view.',
                ),
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }
      final data = snapshot.data!;
      int total(String status) => data.providers
          .where((p) => p['verification_status'] == status)
          .length;
      final waiting = data.staged
          .where(
            (p) => const {
              'submitted',
              'under_review',
              'needs_followup',
              'pending',
            }.contains(p['status']),
          )
          .length;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF003F2D), Color(0xFF087350)],
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 12,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRUST & COMPLIANCE',
                      style: TextStyle(
                        color: WantokColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Verification & KYC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Identity, business and preliminary eligibility queues.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('kyc-vendor-cases-link'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VendorIntakeQueuePage(),
                ),
              ),
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text(
                'Vendor applications & two-person review tasks',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('kyc-clearance-monitor'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VendorClearanceStatusPage(),
                ),
              ),
              icon: const Icon(Icons.gpp_bad_outlined),
              label: const Text('Clearance monitoring & emergency revocation'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('kyc-policy-governance-link'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VendorPolicyGovernancePage(),
                ),
              ),
              icon: const Icon(Icons.policy_outlined),
              label: const Text('International compliance policy proposals'),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 760
                  ? 4
                  : c.maxWidth >= 440
                  ? 2
                  : 1;
              final width = (c.maxWidth - (cols - 1) * 10) / cols;
              final counts = [
                (
                  'Legacy verified flag',
                  total('verified'),
                  Icons.verified_user,
                  const Color(0xFF086747),
                ),
                (
                  'Pending',
                  total('pending'),
                  Icons.pending_actions,
                  const Color(0xFFB97906),
                ),
                (
                  'Rejected',
                  total('rejected'),
                  Icons.cancel_outlined,
                  const Color(0xFFBA4545),
                ),
                (
                  'Staged reviews',
                  waiting,
                  Icons.fact_check_outlined,
                  const Color(0xFF2463A7),
                ),
              ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in counts)
                    SizedBox(
                      width: width,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Icon(item.$3, color: item.$4, size: 26),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.$2}',
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      item.$1,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preliminary onboarding checks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'A staged application is NOT proof of KYC approval. '
                    'The existing controlled verification checklist remains authoritative.',
                    style: TextStyle(color: WantokColors.muted),
                  ),
                  const SizedBox(height: 10),
                  for (final row in data.staged.take(8))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.assignment_ind_outlined),
                      ),
                      title: Text(
                        row['applicant_name']?.toString() ?? 'Applicant',
                      ),
                      subtitle: Text(
                        'Stage: ${row['status'] ?? 'pending'} · '
                        '${row['coverage_province'] ?? 'Region not specified'}',
                      ),
                    ),
                  if (data.staged.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('No staged applications are visible.'),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StagedProviderReviewPage(),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Open preliminary review queue'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Provider verification status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Read-only status from provider records. Official document '
                    'collection and regulatory identity verification are not yet enabled.',
                    style: TextStyle(fontSize: 12, color: WantokColors.muted),
                  ),
                  for (final row in data.providers.take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        row['display_name']?.toString() ?? 'Provider',
                      ),
                      subtitle: Text(
                        'Status: ${row['verification_status'] ?? 'pending'}',
                      ),
                      trailing: Icon(
                        row['verification_status'] == 'verified'
                            ? Icons.verified
                            : Icons.shield_outlined,
                        color: row['verification_status'] == 'verified'
                            ? WantokColors.primary
                            : WantokColors.muted,
                      ),
                    ),
                  if (data.providers.isEmpty)
                    const Text('No providers visible.'),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
