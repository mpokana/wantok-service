import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'auth/admin_password_reset_page.dart';
import 'auth/admin_sign_in_page.dart';
import 'dashboard/admin_shell.dart';
import 'dashboard/vendor_intake_queue_page.dart';
import 'dashboard/vendor_policy_governance_page.dart';

class WantokAdminApp extends StatelessWidget {
  const WantokAdminApp({required this.backendConfigured, super.key});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wantok Operations',
      debugShowCheckedModeBanner: false,
      theme: WantokTheme.light(),
      home: backendConfigured
          ? const _AdminAuthGate()
          : const _AdminConfigurationPage(),
    );
  }
}

class _AdminAuthGate extends StatelessWidget {
  const _AdminAuthGate();

  static const _auth = WantokAuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authChanges,
      builder: (context, snapshot) {
        final authState = snapshot.data;
        final session = authState?.session ?? _auth.currentSession;
        final isRecovery =
            authState?.event == AuthChangeEvent.passwordRecovery ||
            Uri.base.fragment.contains('type=recovery');

        if (session == null) {
          return const AdminSignInPage();
        }

        if (isRecovery) {
          return const AdminPasswordResetPage();
        }

        return FutureBuilder<Set<String>>(
          future: _auth.loadRoles(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final roles = roleSnapshot.data ?? const <String>{};
            if (roles.contains('admin')) {
              return AdminShell(roles: roles, email: session.user.email);
            }

            // A scoped officer cannot inherit the broad administrator shell.
            return FutureBuilder<Set<String>>(
              future: _loadScopedDuties(),
              builder: (context, dutySnapshot) {
                if (dutySnapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final duties = dutySnapshot.data ?? const <String>{};
                if (duties.isEmpty) {
                  return _AccessDeniedPage(email: session.user.email);
                }
                return _ScopedPolicyWorkspace(
                  email: session.user.email,
                  duties: duties,
                );
              },
            );
          },
        );
      },
    );
  }
}

Future<Set<String>> _loadScopedDuties() async {
  try {
    final response = await WantokBackend.client
        .from('operations_duty_grants')
        .select('duty,issued_at,expires_at,revoked_at')
        .inFilter('duty', [
          'policy_author',
          'policy_reviewer',
          'case_reviewer',
          'evidence_officer',
        ]);
    final now = DateTime.now().toUtc();
    final active = <String>{};
    for (final record in (response as List)) {
      final row = Map<String, dynamic>.from(record as Map);
      final start = DateTime.tryParse(row['issued_at']?.toString() ?? '');
      final end = DateTime.tryParse(row['expires_at']?.toString() ?? '');
      if (row['revoked_at'] == null &&
          start != null &&
          !start.toUtc().isAfter(now) &&
          (end == null || end.toUtc().isAfter(now))) {
        active.add(row['duty'].toString());
      }
    }
    return active;
  } catch (_) {
    // Older backends or unavailable scope data must not grant entry.
    return <String>{};
  }
}

class _ScopedPolicyWorkspace extends StatelessWidget {
  const _ScopedPolicyWorkspace({required this.email, required this.duties});
  final String? email;
  final Set<String> duties;

  @override
  Widget build(BuildContext context) {
    final policy =
        duties.contains('policy_author') || duties.contains('policy_reviewer');
    final cases =
        duties.contains('case_reviewer') || duties.contains('evidence_officer');
    if (!policy && !cases) {
      return const Scaffold(
        body: Center(child: Text('No authorised workspace')),
      );
    }
    return DefaultTabController(
      length: (policy ? 1 : 0) + (cases ? 1 : 0),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wantok Operations · Scoped Compliance'),
          actions: [
            if (email != null)
              Center(child: Text(email!, overflow: TextOverflow.ellipsis)),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => const WantokAuthService().signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            tabs: [
              if (policy) const Tab(text: 'Policy drafts'),
              if (cases) const Tab(text: 'Vendor cases'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (policy) const VendorPolicyGovernancePage(),
            if (cases)
              VendorIntakeQueuePage(
                canTriage: duties.contains('case_reviewer'),
                canReviewChecks: duties.contains('case_reviewer'),
                canRequestEvidence: duties.contains('evidence_officer'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 54,
                    color: WantokColors.coral,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Admin access required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email ?? 'This account',
                    style: const TextStyle(color: WantokColors.muted),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: () => const WantokAuthService().signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminConfigurationPage extends StatelessWidget {
  const _AdminConfigurationPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Wantok Operations needs SUPABASE_URL and '
            'SUPABASE_PUBLISHABLE_KEY supplied at build/run time.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
