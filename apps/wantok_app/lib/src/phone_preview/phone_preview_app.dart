import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';
import 'package:wantok_api/wantok_api.dart';

import '../home/explore_page.dart';
import '../home/client_home.dart';
import '../home/services_hub_page.dart';
import '../home/activity_page.dart';
import '../home/messages_page.dart';
import '../home/vendor_home.dart';
import '../home/wantok_pay_preview_page.dart';
import '../home/offline_demo_navigation.dart';
import 'offline_demo_catalogue.dart';
import '../home/adaptive_category_grid.dart';
import '../home/wantok_profile_menu.dart';

Future<List<Map<String, dynamic>>> _emptyMapRows() async =>
    const <Map<String, dynamic>>[];
Future<List<ClientServiceRecommendation>> _emptyRecommendations() async =>
    const <ClientServiceRecommendation>[];
Future<List<ClientServicePlace>> _emptyPlaces() async =>
    const <ClientServicePlace>[];

/// Offline ARM64 phone review only. No Supabase bootstrap, real identity,
/// providers, bookings, payment, upload, geolocation or messaging.
class WantokPhonePreviewApp extends StatelessWidget {
  const WantokPhonePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wantok Services — Offline Preview',
    debugShowCheckedModeBanner: false,
    theme: WantokTheme.light(),
    home: const WantokPhonePreviewShell(),
  );
}

class WantokPhonePreviewShell extends StatefulWidget {
  const WantokPhonePreviewShell({super.key});

  @override
  State<WantokPhonePreviewShell> createState() =>
      _WantokPhonePreviewShellState();
}

class _WantokPhonePreviewShellState extends State<WantokPhonePreviewShell> {
  int _tab = 0;
  final ValueNotifier<int?> _gridDensity = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _gridDensity.dispose();
    super.dispose();
  }

  void _selectProfileAction(WantokProfileAction action) {
    switch (action) {
      case WantokProfileAction.settings:
        OfflineDemoNavigation.account(context);
      case WantokProfileAction.wallet:
        _open(4);
      case WantokProfileAction.vendor:
        _openVendorDemo();
    }
  }

  void _openVendorDemo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vendor · demonstration only',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              const Text(
                'Choose a visual journey. Neither option changes your account or approves a vendor.',
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.how_to_reg_outlined),
                title: const Text('Applicant view'),
                subtitle: const Text(
                  'See the existing vendor application entry',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showVendorPage(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Approved vendor dashboard · SAMPLE'),
                subtitle: const Text(
                  'Design preview; no approval, products, ads or payouts',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showVendorPage(true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVendorPage(bool approvedMock) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              approvedMock
                  ? 'Vendor dashboard · SAMPLE'
                  : 'Vendor application · SAMPLE',
            ),
          ),
          body: Column(
            children: [
              const _OfflineBanner(),
              Expanded(
                child: VendorHome(
                  hasVendorAccess: approvedMock,
                  hasDriverAccess: false,
                  onApply: () => OfflineDemoNavigation.notice(
                    context,
                    'Vendor application',
                  ),
                  onOpenJobs: () =>
                      OfflineDemoNavigation.notice(context, 'Vendor jobs'),
                  onOpenListings: () =>
                      OfflineDemoNavigation.notice(context, 'Vendor listings'),
                  onOpenTaxiDriver: () =>
                      OfflineDemoNavigation.notice(context, 'Taxi driver'),
                  onOpenCommerce: () =>
                      OfflineDemoNavigation.notice(context, 'Vendor commerce'),
                  onOpenEvents: () =>
                      OfflineDemoNavigation.notice(context, 'Vendor events'),
                  onOpenWaterTransport: () =>
                      OfflineDemoNavigation.notice(context, 'Water transport'),
                  onOpenProfile: () =>
                      OfflineDemoNavigation.notice(context, 'Vendor profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInbox() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Inbox · SAMPLE')),
          body: const Column(
            children: [
              _OfflineBanner(),
              Expanded(
                child: MessagesPage(
                  demoMode: true,
                  loadThreads: _emptyMapRows,
                  loadSupportRequests: _emptyMapRows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) => AdaptiveGridDensityScope(
    density: _gridDensity,
    child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: const Color(0xFFF5F7F8),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Wantok ',
                    style: TextStyle(color: WantokColors.ink),
                  ),
                  TextSpan(
                    text: 'Services',
                    style: TextStyle(color: WantokColors.primary),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              'People. Places. Possibilities.',
              style: TextStyle(fontSize: 11, color: WantokColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Inbox',
            onPressed: _openInbox,
            icon: const Icon(Icons.forum_outlined, color: WantokColors.primary),
          ),
          WantokProfileMenu(onSelected: _selectProfileAction),
        ],
      ),
      body: Column(
        children: [
          const _OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                ClientHome(
                  key: const ValueKey('phone-full-client-home'),
                  loadServices: OfflineDemoCatalogue.load,
                  loadTopProviders: OfflineDemoCatalogue.loadProviders,
                  demoMode: true,
                  onServicesTap: () => _open(1),
                  onExploreTap: () => _open(2),
                  onAgentTap: () =>
                      OfflineDemoNavigation.notice(context, 'Wantok Agent'),
                ),
                ServicesHubPage(
                  key: const ValueKey('phone-full-services'),
                  loadServices: OfflineDemoCatalogue.load,
                  loadTopProviders: OfflineDemoCatalogue.loadProviders,
                  loadRecommendations: _emptyRecommendations,
                  loadPlaces: _emptyPlaces,
                  showMarketplaceLandingWhenInjected: true,
                  demoMode: true,
                ),
                ExplorePage(onBrowseServices: () => _open(1)),
                const ActivityPage(
                  loadReservations: _emptyMapRows,
                  demoMode: true,
                ),
                const WantokPayPreviewPage(embedded: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: _tab,
          onDestinationSelected: _open,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              label: 'Services',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              label: 'Track',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Wallet',
            ),
          ],
        ),
      ),
    ),
  );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('phone-preview-warning'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    color: const Color(0xFFFFF3D7),
    child: const Text(
      'OFFLINE DEMONSTRATION · Sample data only · No sign-in, bookings or money movement',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10,
        color: Color(0xFF684907),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
