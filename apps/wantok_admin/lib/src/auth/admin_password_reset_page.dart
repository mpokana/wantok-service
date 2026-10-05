import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_ui/wantok_ui.dart';

class AdminPasswordResetPage extends StatefulWidget {
  const AdminPasswordResetPage({super.key});

  @override
  State<AdminPasswordResetPage> createState() => _AdminPasswordResetPageState();
}

class _AdminPasswordResetPageState extends State<AdminPasswordResetPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _busy = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _message = 'Use at least 8 characters.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      setState(() {
        _success = true;
        _message = 'Password reset successfully. Return to Wantok Admin and sign in.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 52,
                      color: WantokColors.primary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Reset Wantok Admin password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WantokColors.primaryDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!_success) ...[
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmController,
                        obscureText: true,
                        onSubmitted: (_) {
                          if (!_busy) _reset();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _busy ? null : _reset,
                        icon: const Icon(Icons.check),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Text(_busy ? 'Updating...' : 'Set new password'),
                        ),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _success
                              ? WantokColors.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
