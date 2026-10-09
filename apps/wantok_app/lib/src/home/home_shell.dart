import 'package:flutter/material.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../vendor/provider_application_page.dart';
import '../vendor/taxi_driver_page.dart';
import '../vendor/vendor_commerce_page.dart';
import '../vendor/vendor_events_page.dart';
import '../vendor/vendor_jobs_page.dart';
import '../vendor/vendor_listings_page.dart';
import '../vendor/vendor_water_transport_page.dart';
import 'account_page.dart';
import 'activity_page.dart';
import 'client_home.dart';
import 'explore_page.dart';
import 'messages_page.dart';
import 'services_hub_page.dart';
import 'vendor_home.dart';
import 'wantok_agent_page.dart';
import 'wantok_pay_preview_page.dart';

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
      if (mounted) setState(() => _roles = roles);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not refresh account access. Check your connection.',
            ),
          ),
        );
      }
    } finally {
      _refreshingRoles = false;
    }
  }

  void _changeMode(AppMode value) {
    setState(() {
      _mode = value;
      _tabIndex = 0;
    });
    if (value == AppMode.vendor) _refreshRoles();
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(
            title: const Text('Account and profile'),
            actions: [
              PopupMenuButton<AppMode>(
                tooltip: 'Switch Client/Vendor mode',
                initialValue: _mode,
                onSelected: (value) {
                  Navigator.of(routeContext).pop();
                  _changeMode(value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: AppMode.client,
                    child: Text('Client mode'),
                  ),
                  PopupMenuItem(
                    value: AppMode.vendor,
                    child: Text('Vendor mode'),
                  ),
                ],
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
            ],
          ),
          body: AccountPage(roles: _roles, onSignOut: _auth.signOut),
        ),
      ),
    );
  }

  void _openAgent() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const WantokAgentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _mode == AppMode.client
        ? const [
            _NavItem(
              icon: Icons.home_rounded,
              outlineIcon: Icons.home_outlined,
              label: 'Home',
            ),
            _NavItem(
              icon: Icons.grid_view_rounded,
              outlineIcon: Icons.grid_view_outlined,
              label: 'Services',
            ),
            _NavItem(
              icon: Icons.explore_rounded,
              outlineIcon: Icons.explore_outlined,
              label: 'Explore',
            ),
            _NavItem(
              icon: Icons.route_rounded,
              outlineIcon: Icons.route_outlined,
              label: 'Track',
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_rounded,
              outlineIcon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
            ),
          ]
        : const [
            _NavItem(
              icon: Icons.dashboard_rounded,
              outlineIcon: Icons.dashboard_outlined,
              label: 'Dashboard',
            ),
            _NavItem(
              icon: Icons.work_rounded,
              outlineIcon: Icons.work_outline_rounded,
              label: 'Jobs',
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              outlineIcon: Icons.storefront_outlined,
              label: 'Listings',
            ),
            _NavItem(
              icon: Icons.person_rounded,
              outlineIcon: Icons.person_outline_rounded,
              label: 'Me',
            ),
          ];

    final pages = _mode == AppMode.client
        ? <Widget>[
            ClientHome(
              onAccountTap: _openAccount,
              onAgentTap: _openAgent,
              onServicesTap: () => setState(() => _tabIndex = 1),
              onExploreTap: () => setState(() => _tabIndex = 2),
            ),
            const ServicesHubPage(),
            ExplorePage(onBrowseServices: () => setState(() => _tabIndex = 1)),
            const ActivityPage(),
            const WantokPayPreviewPage(embedded: true),
            const MessagesPage(),
          ]
        : <Widget>[
            VendorHome(
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
              onOpenEvents: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const VendorEventsPage(),
                ),
              ),
              onOpenWaterTransport: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const VendorWaterTransportPage(),
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
            const VendorJobsPage(),
            const VendorListingsPage(),
            const MessagesPage(),
            AccountPage(roles: _roles, onSignOut: _auth.signOut),
          ];

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: _WantokBottomBar(
        items: navItems,
        selectedIndex: _tabIndex == (_mode == AppMode.client ? 5 : 3)
            ? -1
            : (_mode == AppMode.vendor && _tabIndex == 4 ? 3 : _tabIndex),
        onSelected: (index) => setState(
          () => _tabIndex = _mode == AppMode.vendor && index == 3 ? 4 : index,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final client = _mode == AppMode.client;

    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: WantokColors.ink,
      toolbarHeight: 66,
      titleSpacing: 18,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wantok',
                  style: TextStyle(
                    color: WantokColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Services',
                  style: TextStyle(
                    color: WantokColors.primary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          Text(
            client ? 'People. Places. Possibilities.' : 'Vendor workspace',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: WantokColors.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Inbox',
          onPressed: () =>
              setState(() => _tabIndex = _mode == AppMode.client ? 5 : 3),
          style: IconButton.styleFrom(
            backgroundColor: _tabIndex == (_mode == AppMode.client ? 5 : 3)
                ? const Color(0xFFE8F3EC)
                : Colors.transparent,
          ),
          icon: Icon(
            _tabIndex == (_mode == AppMode.client ? 5 : 3)
                ? Icons.forum_rounded
                : Icons.forum_outlined,
            color: WantokColors.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Account and profile',
                onPressed: _openAccount,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F3EC),
                  side: const BorderSide(color: Color(0xFFD2E6D8)),
                ),
                icon: Icon(Icons.person_rounded, color: WantokColors.primary),
              ),
              Positioned(
                right: 2,
                top: 7,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16B47D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
  });

  final IconData icon;
  final IconData outlineIcon;
  final String label;
}

class _WantokBottomBar extends StatelessWidget {
  const _WantokBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = index == selectedIndex;
            final item = items[index];
            return Expanded(
              child: Semantics(
                key: ValueKey('wantok-nav-${item.label}'),
                label: item.label,
                button: true,
                selected: selected,
                onTap: () => onSelected(index),
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.icon : item.outlineIcon,
                          size: 23,
                          color: selected
                              ? WantokColors.primary
                              : const Color(0xFF7D8593),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? WantokColors.primary
                                : const Color(0xFF7D8593),
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
