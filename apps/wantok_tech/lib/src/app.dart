import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'auth/tech_sign_in_page.dart';
import 'dashboard/technical_shell.dart';

class WantokTechnicalControlApp extends StatelessWidget {
  const WantokTechnicalControlApp({required this.backendConfigured, super.key});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wantok Technical Control',
      debugShowCheckedModeBanner: false,
      theme: WantokTheme.light(),
      home: backendConfigured
          ? const _TechnicalAuthGate()
          : const _TechnicalConfigurationPage(),
    );
  }
}

class _TechnicalAuthGate extends StatelessWidget {
  const _TechnicalAuthGate();

  static const _auth = WantokAuthService();
  static const _repository = TechnicalControlRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? _auth.currentSession;

        if (session == null) {
          return const TechSignInPage();
        }

        return FutureBuilder<bool>(
          future: _repository.canAccessConsole(),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (accessSnapshot.hasError || accessSnapshot.data != true) {
              return _TechnicalAccessDeniedPage(
                email: session.user.email,
                error: accessSnapshot.error,
              );
            }

            return TechnicalShell(email: session.user.email);
          },
        );
      },
    );
  }
}

class _TechnicalAccessDeniedPage extends StatelessWidget {
  const _TechnicalAccessDeniedPage({required this.email, this.error});

  final String? email;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 58,
                    color: WantokColors.coral,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Technical access required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email ?? 'This account',
                    style: const TextStyle(color: WantokColors.muted),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This console only exposes modules assigned to authorised technical staff.',
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => const WantokAuthService().signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
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

class _TechnicalConfigurationPage extends StatelessWidget {
  const _TechnicalConfigurationPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Wantok Technical Control needs SUPABASE_URL and '
            'SUPABASE_PUBLISHABLE_KEY supplied at build/run time.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
