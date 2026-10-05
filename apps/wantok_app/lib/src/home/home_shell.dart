import 'package:flutter/material.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../vendor/provider_application_page.dart';
import '../vendor/taxi_driver_page.dart';
import '../vendor/vendor_commerce_page.dart';
import '../vendor/vendor_jobs_page.dart';
import '../vendor/vendor_listings_page.dart';
import 'activity_page.dart';
import 'client_home.dart';
import 'vendor_home.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.roles, required this.email, super.key});

  final Set<String> roles;
  final String? email;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const _auth = WantokAuthService();

  AppMode _mode = AppMode.client;
  int _tabIndex = 0;
  late Set<String> _roles;
  bool _refreshingRoles = false;

  bool get _hasVendorAccess =>
      _roles.contains('provider') || _roles.contains('driver');
  bool get _hasDriverAccess => _roles.contains('driver');

  @override
  void initState() {
    super.initState();
    _roles = Set<String>.from(widget.roles);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRoles();
    }
  }

  Future<void> _refreshRoles() async {
    if (_refreshingRoles) return;
    _refreshingRoles = true;
    try {
      final roles = await _auth.loadRoles();
      if (mounted) {
        setState(() => _roles = roles);
      }
    } finally {
      _refreshingRoles = false;
    }
  }

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
                if (value == AppMode.vendor) {
                  _refreshRoles();
                }
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
              : VendorHome(
                  hasVendorAccess: _hasVendorAccess,
                  hasDriverAccess: _hasDriverAccess,
                  onOpenTaxiDriver: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const TaxiDriverPage(),
                    ),
                  ),
                  onOpenCommerce: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const VendorCommercePage(),
                    ),
                  ),
                  onApply: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ProviderApplicationPage(),
                    ),
                  ),
                  onOpenJobs: () => setState(() => _tabIndex = 1),
                  onOpenListings: () => setState(() => _tabIndex = 2),
                ),
          _mode == AppMode.client
              ? const ActivityPage()
              : const VendorJobsPage(),
          _mode == AppMode.client
              ? const _PlaceholderPage(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',
                  message: 'Client-to-provider conversations will live here.',
                )
              : const VendorListingsPage(),
          _AccountPage(
            email: widget.email,
            roles: _roles,
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
