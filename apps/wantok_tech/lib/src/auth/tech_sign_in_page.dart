import 'package:flutter/material.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

class TechSignInPage extends StatefulWidget {
  const TechSignInPage({super.key});

  @override
  State<TechSignInPage> createState() => _TechSignInPageState();
}

class _TechSignInPageState extends State<TechSignInPage> {
  static const _auth = WantokAuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.signIn(email: _email.text.trim(), password: _password.text);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            Expanded(
              child: Container(
                color: const Color(0xFF102D24),
                padding: const EdgeInsets.all(52),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_input_component_outlined,
                      size: 72,
                      color: Colors.white,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Wantok Technical Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Module configuration, diagnostics, health and technical access — isolated from marketplace operations administration.',
                      style: TextStyle(
                        color: Color(0xFFD4E8DF),
                        fontSize: 17,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Technical Control Panel',
                        style: TextStyle(
                          color: WantokColors.primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Authorised technical staff only',
                        style: TextStyle(color: WantokColors.muted),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        onSubmitted: (_) => _signIn(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _busy ? null : _signIn,
                        icon: const Icon(Icons.login),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Text(_busy ? 'Signing in...' : 'Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
