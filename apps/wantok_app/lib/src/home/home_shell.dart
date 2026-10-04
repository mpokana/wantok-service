import 'package:flutter/material.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'client_home.dart';
import 'vendor_home.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.roles, required this.email, super.key});

  final Set<String> roles;
  final String? email;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _auth = WantokAuthService();

  AppMode _mode = AppMode.client;
  int _tabIndex = 0;

  bool get _hasVendorAccess =>
      widget.roles.contains('provider') || widget.roles.contains('driver');

  @override
  Widget build(BuildContext context) {
    final destinations = _mode == AppMode.client
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              label: 'Listings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'wantok',
              style: TextStyle(
                color: WantokColors.primaryDark,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Text(
              '.service',
              style: TextStyle(
                color: WantokColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WantokModeSwitcher(
              value: _mode,
              onChanged: (value) {
                setState(() {
                  _mode = value;
                  _tabIndex = 0;
                });
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _mode == AppMode.client
              ? const ClientHome()
              : VendorHome(hasVendorAccess: _hasVendorAccess),
          _PlaceholderPage(
            icon: _mode == AppMode.client
                ? Icons.receipt_long_outlined
                : Icons.work_outline,
            title: _mode == AppMode.client ? 'Activity' : 'Jobs',
            message: _mode == AppMode.client
                ? 'Your rides, bookings, orders and service requests will appear here.'
                : 'Open jobs, quotes and active work will appear here.',
          ),
          _PlaceholderPage(
            icon: _mode == AppMode.client
                ? Icons.chat_bubble_outline
                : Icons.storefront_outlined,
            title: _mode == AppMode.client ? 'Messages' : 'Listings',
            message: _mode == AppMode.client
                ? 'Client-to-provider conversations will live here.'
                : 'Manage approved services, resources, pricing and availability here.',
          ),
          _AccountPage(
            email: widget.email,
            roles: widget.roles,
            onSignOut: _auth.signOut,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: destinations,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: WantokColors.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.email,
    required this.roles,
    required this.onSignOut,
  });

  final String? email;
  final Set<String> roles;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final sortedRoles = roles.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Account', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(email ?? 'Wantok user'),
            subtitle: Text(
              sortedRoles.isEmpty ? 'customer' : sortedRoles.join(', '),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
