import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'auth/admin_sign_in_page.dart';
import 'dashboard/admin_shell.dart';

class WantokAdminApp extends StatelessWidget {
  const WantokAdminApp({required this.backendConfigured, super.key});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wantok Admin',
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
        final session = snapshot.data?.session ?? _auth.currentSession;
        if (session == null) {
          return const AdminSignInPage();
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
            if (!roles.contains('admin')) {
              return _AccessDeniedPage(email: session.user.email);
            }

            return AdminShell(roles: roles, email: session.user.email);
          },
        );
      },
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
            'Wantok Admin needs SUPABASE_URL and '
            'SUPABASE_PUBLISHABLE_KEY supplied at build/run time.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
