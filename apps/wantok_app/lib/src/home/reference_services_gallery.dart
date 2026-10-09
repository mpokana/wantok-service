import 'package:flutter/material.dart';

import 'adaptive_category_grid.dart';

import 'package:wantok_ui/wantok_ui.dart';

import 'smoke_data.dart';
import 'reference_scene_details.dart';
import 'wantok_category_ui.dart';

/// Twelve-category front door from the approved reference. The explicit
/// categories always render, including before providers are onboarded.
/// Missing backend categories may ONLY open non-transactional sample previews.
class ReferenceCategorySpec {
  const ReferenceCategorySpec(this.style, this.slug, this.sampleScene);
  final WantokCategoryStyle style;
  final String? slug;
  final SmokeScene sampleScene;

  String get title => style.title;
  IconData get icon => style.icon;
  Color get colour => style.accent;
  Color get surface => style.surface;
}

abstract final class ReferenceServiceCategories {
  static const items = <ReferenceCategorySpec>[
    ReferenceCategorySpec(
      WantokCategoryStyles.taxi,
      'taxi-ride',
      SmokeScene.bookings,
    ),
    ReferenceCategorySpec(WantokCategoryStyles.food, 'food', SmokeScene.food),
    ReferenceCategorySpec(
      WantokCategoryStyles.groceries,
      'groceries',
      SmokeScene.groceries,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.shopping,
      'shopping-retail',
      SmokeScene.groceries,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.home,
      'home-services',
      SmokeScene.trades,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.beauty,
      'beauty-wellness',
      SmokeScene.trades,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.health,
      'health-medical',
      SmokeScene.trades,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.travel,
      'travel-flights',
      SmokeScene.travel,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.events,
      'events',
      SmokeScene.events,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.professional,
      'specialist-services',
      SmokeScene.trades,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.automotive,
      'vehicle-hire',
      SmokeScene.bookings,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.delivery,
      'delivery',
      SmokeScene.bookings,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.hotels,
      'accommodation',
      SmokeScene.travel,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.education,
      'education-training',
      SmokeScene.trades,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.financial,
      'financial-services',
      SmokeScene.providers,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.waterRides,
      'boat-ship-rides',
      SmokeScene.travel,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.labour,
      'general-labour',
      SmokeScene.trades,
    ),
    ReferenceCategorySpec(
      WantokCategoryStyles.more,
      null,
      SmokeScene.providers,
    ),
  ];
}

enum ReferenceScene {
  splash,
  signIn,
  home,
  services,
  foodListing,
  restaurantDetail,
  taxi,
  travel,
  bookings,
  tracking,
  wallet,
  account,
}

class ReferenceScreenSpec {
  const ReferenceScreenSpec(this.scene, this.title, this.asset, this.icon);
  final ReferenceScene scene;
  final String title;
  final String asset;
  final IconData icon;
  String get smokeId =>
      'SMOKE_20261008_SCREEN_${(scene.index + 1).toString().padLeft(3, '0')}';
}

abstract final class ReferenceScreenGallery {
  static const items = <ReferenceScreenSpec>[
    ReferenceScreenSpec(
      ReferenceScene.splash,
      'Splash / Launch',
      'assets/images/hero_water.png',
      Icons.waves_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.signIn,
      'Sign In',
      'assets/images/vanessa_local_provider.jpg',
      Icons.login_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.home,
      'Home',
      'assets/images/hero_water.png',
      Icons.home_filled,
    ),
    ReferenceScreenSpec(
      ReferenceScene.services,
      'Service Categories',
      'assets/images/hero_trades.png',
      Icons.grid_view_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.foodListing,
      'Service Listing (Food)',
      'assets/images/hero_food.png',
      Icons.restaurant_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.restaurantDetail,
      'Restaurant Detail',
      'assets/images/hero_food.png',
      Icons.restaurant_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.taxi,
      'Taxi Booking',
      'assets/images/hero_delivery.png',
      Icons.local_taxi_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.travel,
      'Travel / Flights',
      'assets/images/hero_water.png',
      Icons.flight_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.bookings,
      'Bookings',
      'assets/images/hero_events.png',
      Icons.event_note_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.tracking,
      'Tracking',
      'assets/images/hero_delivery.png',
      Icons.route_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.wallet,
      'Wallet / Payments',
      'assets/images/hero_food.png',
      Icons.account_balance_wallet_rounded,
    ),
    ReferenceScreenSpec(
      ReferenceScene.account,
      'Account',
      'assets/images/hero_trades.png',
      Icons.person_rounded,
    ),
  ];
}

/// Reference layout and icons are production styling; only contents of
/// preview pages/fixtures are smoke data and opt in at build time.
class ReferenceServicesLanding extends StatelessWidget {
  const ReferenceServicesLanding({
    super.key,
    required this.onCategory,
    required this.onAllServices,
    this.onSearch,
  });

  final ValueChanged<ReferenceCategorySpec> onCategory;
  final VoidCallback onAllServices;
  final ValueChanged<String>? onSearch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('reference-services-landing'),
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 26),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'All Services',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: WantokColors.ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Find trusted services and providers across Papua New Guinea.',
                  style: TextStyle(fontSize: 11.5, color: WantokColors.muted),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('reference-all-services'),
                onPressed: onAllServices,
                child: const Text('Browse providers'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          child: TextField(
            key: const ValueKey('reference-services-search'),
            onSubmitted: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search services, shops or providers',
              hintStyle: TextStyle(fontSize: 12),
              prefixIcon: Icon(Icons.search, color: Color(0xFF65748B)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 13),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFEDF0F4)),
                borderRadius: BorderRadius.all(Radius.circular(19)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final height =
                (constraints.maxWidth / 3.0 * 1.06 +
                        (scale - 1).clamp(0, 2) * 55)
                    .toDouble();
            return AdaptiveCategoryGrid(
              itemCount: ReferenceServiceCategories.items.length,
              tileHeight: height,
              rowSpacing: 8,
              columnSpacing: 8,
              itemBuilder: (context, index) {
                final cat = ReferenceServiceCategories.items[index];
                return WantokCategoryTile(
                  key: ValueKey('reference-category-${cat.title}'),
                  style: cat.style,
                  onTap: () => onCategory(cat),
                );
              },
            );
          },
        ),
        // Photographic reference samples now live on Explore, not Services.
      ],
    );
  }
}

/// A development-only photographic design gallery, shown on Explore.
/// These twelve previews are not providers, ads, bookings, or live products.
class ReferenceScreenSamplesSection extends StatelessWidget {
  const ReferenceScreenSamplesSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!WantokSmokeData.enabled) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('explore-reference-samples'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SmokeMarker(),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Reference screen samples',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'All twelve reference screens: example imagery and UI only.',
          style: TextStyle(color: WantokColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        AdaptiveCategoryGrid(
          itemCount: ReferenceScreenGallery.items.length,
          tileHeight: 135,
          columnSpacing: 10,
          rowSpacing: 10,
          itemBuilder: (context, index) {
            final item = ReferenceScreenGallery.items[index];
            return _ReferenceSceneTile(item: item);
          },
        ),
      ],
    );
  }
}

/// Keeps the image-only subject visible when an existing source photograph
/// contains unwanted baked-in artefacts on the far left. No image is generated
/// or overwritten; the view simply crops from the right.
class _ReferencePhoto extends StatelessWidget {
  const _ReferencePhoto({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    final cropRight =
        asset.contains('hero_water') ||
        asset.contains('hero_trades') ||
        asset.contains('hero_delivery');
    return ClipRect(
      child: Transform.scale(
        scale: cropRight ? 1.9 : 1.0,
        alignment: Alignment.centerRight,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _ReferenceSceneTile extends StatelessWidget {
  const _ReferenceSceneTile({required this.item});
  final ReferenceScreenSpec item;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('reference-scene-${item.scene.name}'),
    borderRadius: BorderRadius.circular(14),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReferenceSampleScenePage(item: item),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ReferencePhoto(asset: item.asset),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x190A284E), Color(0xE208213D)],
              ),
            ),
          ),
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const SmokeMarker(),
            ),
          ),
          Positioned(
            left: 10,
            right: 6,
            bottom: 9,
            child: Row(
              children: [
                Icon(item.icon, size: 17, color: Colors.white),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Visual reproduction previews do not invoke underlying service/payment APIs.
class ReferenceSampleScenePage extends StatelessWidget {
  const ReferenceSampleScenePage({super.key, required this.item});
  final ReferenceScreenSpec item;

  @override
  Widget build(BuildContext context) {
    final scene = item.scene;
    final data = switch (scene) {
      ReferenceScene.foodListing ||
      ReferenceScene.restaurantDetail => SmokeScene.food,
      ReferenceScene.taxi ||
      ReferenceScene.bookings ||
      ReferenceScene.tracking => SmokeScene.bookings,
      ReferenceScene.wallet => SmokeScene.wallet,
      ReferenceScene.travel => SmokeScene.travel,
      ReferenceScene.account => SmokeScene.providers,
      ReferenceScene.services => SmokeScene.trades,
      ReferenceScene.signIn => SmokeScene.providers,
      ReferenceScene.splash || ReferenceScene.home => SmokeScene.providers,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: Colors.white,
        foregroundColor: WantokColors.ink,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 25),
        children: [
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: _ReferencePhoto(asset: item.asset),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmokeMarker(),
                        SizedBox(width: 6),
                        Text(
                          'Sample screen',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SmokeMarker(),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  'Sample ID: ${item.smokeId}',
                  style: const TextStyle(
                    color: WantokColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Visual preview only — not real inventory, routes,'
                  ' accounts, orders or funds.',
                  style: TextStyle(color: WantokColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                if (scene == ReferenceScene.restaurantDetail)
                  const _SampleRestaurantDetail(),
                if (scene == ReferenceScene.taxi ||
                    scene == ReferenceScene.tracking)
                  const _SampleJourneyDiagram(),
                if (scene == ReferenceScene.wallet) const _SampleWalletBanner(),
                if (scene == ReferenceScene.signIn) const _SampleAuthPreview(),
                ReferenceSceneDetails(scene: scene.name),
                if (scene == ReferenceScene.splash ||
                    scene == ReferenceScene.signIn ||
                    scene == ReferenceScene.services)
                  SmokePreviewSection(scene: data, heading: 'Sample records'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleRestaurantDetail extends StatelessWidget {
  const _SampleRestaurantDetail();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'The Waterfront',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
      ),
      const SizedBox(height: 7),
      const Row(
        children: [
          Icon(Icons.star_rounded, color: Color(0xFFF3AB16), size: 17),
          Text(
            ' 4.6 (320 sample reviews) · 20–30 min',
            style: TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
          SizedBox(width: 5),
          SmokeMarker(),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Menu    Reviews    Info',
        style: TextStyle(
          color: WantokColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      for (final meal in const [
        ('Grilled Snapper', 'K38.00'),
        ('Coconut Prawns', 'K32.00'),
      ])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/hero_food.png',
              width: 58,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(meal.$1),
          subtitle: const Text('Sample menu item · no checkout'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(meal.$2),
              const SizedBox(width: 5),
              const SmokeMarker(),
            ],
          ),
        ),
    ],
  );
}

class _SampleJourneyDiagram extends StatelessWidget {
  const _SampleJourneyDiagram();
  @override
  Widget build(BuildContext context) => Container(
    height: 205,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF3F1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _ReferenceRoutePainter())),
        const Positioned(
          left: 22,
          top: 38,
          child: Icon(Icons.location_on, color: WantokColors.primary, size: 32),
        ),
        const Positioned(
          right: 28,
          bottom: 30,
          child: Icon(Icons.location_on, color: Color(0xFFEF5A3D), size: 34),
        ),
        const Positioned(
          left: 12,
          bottom: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SmokeMarker(),
              SizedBox(width: 5),
              Text('Illustrative route only', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReferenceRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFCBD5D7)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final y = (i + .5) * size.height / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 16), road);
    }
    for (var i = 0; i < 7; i++) {
      final x = (i + .5) * size.width / 7;
      canvas.drawLine(Offset(x, 0), Offset(x + 35, size.height), road);
    }
    final route = Paint()
      ..color = WantokColors.primary
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .13, size.height * .31)
      ..lineTo(size.width * .34, size.height * .49)
      ..lineTo(size.width * .59, size.height * .42)
      ..lineTo(size.width * .82, size.height * .79);
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SampleWalletBanner extends StatelessWidget {
  const _SampleWalletBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Color(0xFF0763DF), Color(0xFF40B0FF)],
      ),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sample wallet balance',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(width: 6),
            SmokeMarker(),
          ],
        ),
        Text(
          'K120.50',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 30,
          ),
        ),
        Text(
          'Not real funds; no payment functionality',
          style: TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}

class _SampleAuthPreview extends StatelessWidget {
  const _SampleAuthPreview();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            'Wantok Services',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
          ),
          Text('Your everyday services in Papua New Guinea'),
          Divider(),
          ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('Email or phone number'),
          ),
          ListTile(leading: Icon(Icons.lock_outline), title: Text('Password')),
          SmokeMarker(),
          Text('Sample design only; sign-in disabled here'),
        ],
      ),
    ),
  );
}
