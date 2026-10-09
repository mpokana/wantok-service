import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../home/explore_page.dart';
import '../home/adaptive_category_grid.dart';
import '../home/wantok_profile_menu.dart';

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

  void _showPreviewSheet(String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _selectProfileAction(WantokProfileAction action) {
    switch (action) {
      case WantokProfileAction.settings:
        _showPreviewSheet(
          'My Settings',
          'Account preferences and security settings become available with approved sign-in. This is an offline demonstration.',
        );
      case WantokProfileAction.wallet:
        _open(4);
      case WantokProfileAction.vendor:
        _showPreviewSheet(
          'Vendor',
          'Apply for a vendor profile using your Wantok account when signed in. Approved vendors will access their dashboard for application progress, jobs, products, sales and future advertising and payout modules. Nothing is active in this offline preview.',
        );
    }
  }

  void _unavailable() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Offline design preview only — no live account or service connected.',
      ),
    ),
  );
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
            tooltip: 'Inbox unavailable in preview',
            onPressed: _unavailable,
            icon: const Icon(Icons.forum_outlined, color: WantokColors.primary),
          ),
          WantokProfileMenu(onSelected: _selectProfileAction),
        ],
      ),
      body: Column(
        children: [
          Container(
            key: const ValueKey('phone-preview-warning'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: const Color(0xFFFFF3D7),
            child: const Text(
              'OFFLINE PREVIEW · Sample imagery · No sign-in, bookings or money movement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF684907),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _PreviewHome(
                  onExplore: () => _open(2),
                  onServices: () => _open(1),
                ),
                _PreviewServices(onNotice: _unavailable),
                ExplorePage(onBrowseServices: () => _open(1)),
                const _Placeholder(
                  title: 'Track',
                  info: 'Live bookings and journey history require an approved staging connection.',
                ),
                const _Placeholder(
                  title: 'Wallet',
                  info: 'Wantok Pay remains a preview. No balance, top-up or money movement is active.',
                ),
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

class _PreviewHome extends StatelessWidget {
  const _PreviewHome({required this.onExplore, required this.onServices});
  final VoidCallback onExplore, onServices;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('phone-preview-home'),
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
    children: [
      const Text(
        'Discover local services',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 5),
      const Text(
        'Explore our design with sample photography, not live listings.',
        style: TextStyle(fontSize: 12, color: WantokColors.muted),
      ),
      const SizedBox(height: 14),
      _PhotoCard(
        image: 'assets/images/vanessa_local_provider.jpg',
        title: 'Services for everyday life',
        eyebrow: 'LOCAL PROVIDERS · SAMPLE',
        action: 'Explore services',
        onTap: onServices,
      ),
      const SizedBox(height: 22),
      const Text(
        'Service categories',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 12),
      _CategoryTiles(onTap: onServices),
      const SizedBox(height: 28),
      const Text(
        'Explore our communities',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      _PhotoCard(
        key: const ValueKey('phone-preview-scenic-card'),
        image: 'assets/images/hero_water.png',
        title: 'Explore PNG and beyond',
        eyebrow: 'DISCOVER PNG · PHOTO PREVIEW',
        action: 'Explore',
        onTap: onExplore,
      ),
    ],
  );
}

class _PreviewServices extends StatelessWidget {
  const _PreviewServices({required this.onNotice});
  final VoidCallback onNotice;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 25),
    children: [
      const Text(
        'Services',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 5),
      const Text(
        'Photo categories only. Provider search and enquiries are disabled.',
        style: TextStyle(fontSize: 12, color: WantokColors.muted),
      ),
      const SizedBox(height: 14),
      _CategoryTiles(onTap: onNotice),
    ],
  );
}

class _CategoryTiles extends StatelessWidget {
  const _CategoryTiles({required this.onTap});
  final VoidCallback onTap;
  static const values = <(String, String)>[
    ('Taxi & Ride', 'category_taxi.webp'),
    ('Food', 'category_food.webp'),
    ('Home Services', 'category_home_services.webp'),
    ('Delivery', 'category_delivery.webp'),
    ('Water Transport', 'category_water_transport.webp'),
    ('Shopping', 'category_shopping.webp'),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveCategoryGrid(
    gridKey: const ValueKey('preview-category-grid'),
    tileHeight: 164,
    itemCount: values.length,
    itemBuilder: (context, i) => InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3EC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/categories/${values[i].$2}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                values[i].$1,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    super.key,
    required this.image,
    required this.title,
    required this.eyebrow,
    required this.action,
    required this.onTap,
  });
  final String image, title, eyebrow, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(25),
    child: SizedBox(
      height: 226,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xF506452D),
                  Color(0xAF06452D),
                  Color(0x0006452D),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xFFFFBD2F),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 225,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  key: ValueKey(
                    'phone-preview-${action.replaceAll(' ', '-').toLowerCase()}',
                  ),
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFBD2F),
                    foregroundColor: const Color(0xFF201E19),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(action),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.info});
  final String title, info;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: WantokColors.primary, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            info,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WantokColors.muted),
          ),
        ],
      ),
    ),
  );
}
