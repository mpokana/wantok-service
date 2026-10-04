import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'auth/sign_in_page.dart';
import 'home/home_shell.dart';

class WantokApp extends StatelessWidget {
  const WantokApp({required this.backendConfigured, super.key});

  final bool backendConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wantok Service',
      debugShowCheckedModeBanner: false,
      theme: WantokTheme.light(),
      home: backendConfigured
          ? const _AuthGate()
          : const _ConfigurationRequiredPage(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  static const _auth = WantokAuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? _auth.currentSession;
        if (session == null) {
          return const SignInPage();
        }

        return FutureBuilder<Set<String>>(
          future: _auth.loadRoles(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return HomeShell(
              roles: roleSnapshot.data ?? const <String>{},
              email: session.user.email,
            );
          },
        );
      },
    );
  }
}

class _ConfigurationRequiredPage extends StatelessWidget {
  const _ConfigurationRequiredPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 44,
                        color: WantokColors.primary,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Wantok backend is not configured',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Build or run the app with SUPABASE_URL and '
                        'SUPABASE_PUBLISHABLE_KEY supplied through Dart defines. '
                        'Machine-specific configuration is intentionally not stored '
                        'inside the application source.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
