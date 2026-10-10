import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// One source of truth for Wantok category identity, colours, and icons.
/// Use bySlug() on every surface; no local hard-coded category icons.
class WantokCategoryStyle {
  const WantokCategoryStyle({
    required this.slug,
    required this.title,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.badgeSurface,
    this.photoAsset,
  });

  final String slug;
  final String title;
  final IconData icon;
  final Color accent;
  final Color surface;
  final Color badgeSurface;

  /// AI-generated, locally bundled category picture; common on all screens.
  final String? photoAsset;
}

abstract final class WantokCategoryStyles {
  static const taxi = WantokCategoryStyle(
    slug: 'taxi-ride',
    title: 'Taxi &\nTransport',
    icon: Icons.local_taxi_rounded,
    accent: Color(0xFFD99500),
    surface: Color(0xFFFFF7DD),
    badgeSurface: Color(0xFFFFEAB0),
    photoAsset: 'assets/images/categories/category_taxi.webp',
  );
  static const food = WantokCategoryStyle(
    slug: 'food',
    title: 'Food &\nRestaurants',
    icon: Icons.restaurant_rounded,
    accent: Color(0xFFF25B36),
    surface: Color(0xFFFFEEE8),
    badgeSurface: Color(0xFFFFD8C7),
    photoAsset: 'assets/images/categories/category_food.webp',
  );
  static const groceries = WantokCategoryStyle(
    slug: 'groceries',
    title: 'Groceries &\nEssentials',
    icon: Icons.shopping_basket_rounded,
    accent: Color(0xFF0AAB63),
    surface: Color(0xFFEAF9F1),
    badgeSurface: Color(0xFFCAEFDC),
    photoAsset: 'assets/images/categories/category_groceries.webp',
  );
  static const shopping = WantokCategoryStyle(
    slug: 'shopping-retail',
    title: 'Shopping\n& Retail',
    icon: Icons.shopping_bag_rounded,
    accent: Color(0xFF8D42E4),
    surface: Color(0xFFF5ECFF),
    badgeSurface: Color(0xFFEAD9FF),
    photoAsset: 'assets/images/categories/category_shopping.webp',
  );
  static const home = WantokCategoryStyle(
    slug: 'home-services',
    title: 'Home\nServices',
    icon: Icons.home_rounded,
    accent: Color(0xFF1574E7),
    surface: Color(0xFFEBF3FF),
    badgeSurface: Color(0xFFD6E8FF),
    photoAsset: 'assets/images/categories/category_home_services.webp',
  );
  static const beauty = WantokCategoryStyle(
    slug: 'beauty-wellness',
    title: 'Beauty\n& Wellness',
    icon: Icons.spa_rounded,
    accent: Color(0xFFE13EA9),
    surface: Color(0xFFFFEFF9),
    badgeSurface: Color(0xFFFFD9EF),
    photoAsset: 'assets/images/categories/category_beauty.webp',
  );
  static const health = WantokCategoryStyle(
    slug: 'health-medical',
    title: 'Health\n& Medical',
    icon: Icons.favorite_rounded,
    accent: Color(0xFF0DAE9F),
    surface: Color(0xFFE9F9F6),
    badgeSurface: Color(0xFFCBF0E9),
    photoAsset: 'assets/images/categories/category_health.webp',
  );
  static const travel = WantokCategoryStyle(
    slug: 'travel-flights',
    title: 'Travel\n& Flights',
    icon: Icons.flight_rounded,
    accent: Color(0xFF216AF1),
    surface: Color(0xFFEDF3FF),
    badgeSurface: Color(0xFFD7E6FF),
    photoAsset: 'assets/images/categories/category_travel.webp',
  );
  static const events = WantokCategoryStyle(
    slug: 'events',
    title: 'Events\n& Tickets',
    icon: Icons.event_rounded,
    accent: Color(0xFFE74992),
    surface: Color(0xFFFFEFF5),
    badgeSurface: Color(0xFFFFD8E8),
    photoAsset: 'assets/images/categories/category_events.webp',
  );
  static const professional = WantokCategoryStyle(
    slug: 'specialist-services',
    title: 'Professional\nServices',
    icon: Icons.build_rounded,
    accent: Color(0xFF3867DC),
    surface: Color(0xFFEDF0FF),
    badgeSurface: Color(0xFFDCE3FF),
    photoAsset: 'assets/images/categories/category_professional.webp',
  );
  static const automotive = WantokCategoryStyle(
    slug: 'vehicle-hire',
    title: 'Automotive',
    icon: Icons.directions_car_rounded,
    accent: Color(0xFF2468DB),
    surface: Color(0xFFECF2FE),
    badgeSurface: Color(0xFFD8E6FB),
    photoAsset: 'assets/images/categories/category_automotive.webp',
  );
  static const more = WantokCategoryStyle(
    slug: 'more',
    title: 'More',
    icon: Icons.more_horiz_rounded,
    accent: Color(0xFF41638D),
    surface: Color(0xFFEFF2F8),
    badgeSurface: Color(0xFFDEE7F3),
    photoAsset: 'assets/images/categories/category_more.webp',
  );

  // Existing backend categories stay in the same catalogue and use a
  // consistent shared identity, including ones not on the 12-tile home.
  static const delivery = WantokCategoryStyle(
    slug: 'delivery',
    title: 'Delivery',
    icon: Icons.local_shipping_rounded,
    accent: Color(0xFF0D88CB),
    surface: Color(0xFFE8F6FF),
    badgeSurface: Color(0xFFD1EDFF),
    photoAsset: 'assets/images/categories/category_delivery.webp',
  );
  static const errands = WantokCategoryStyle(
    slug: 'errands',
    title: 'Errands',
    icon: Icons.shopping_bag_rounded,
    accent: Color(0xFFB57209),
    surface: Color(0xFFFFF4E4),
    badgeSurface: Color(0xFFFFE8BD),
    photoAsset: 'assets/images/categories/category_groceries.webp',
  );
  static const boatHire = WantokCategoryStyle(
    slug: 'boat-hire',
    title: 'Boat Hire',
    icon: Icons.directions_boat_rounded,
    accent: Color(0xFF087E95),
    surface: Color(0xFFE8F7F9),
    badgeSurface: Color(0xFFD1F0F4),
    photoAsset: 'assets/images/categories/category_water_transport.webp',
  );
  static const waterRides = WantokCategoryStyle(
    slug: 'boat-ship-rides',
    title: 'Water Transport',
    icon: Icons.sailing_rounded,
    accent: Color(0xFF067A91),
    surface: Color(0xFFE8F7F9),
    badgeSurface: Color(0xFFCCEDF3),
    photoAsset: 'assets/images/categories/category_water_transport.webp',
  );
  static const labour = WantokCategoryStyle(
    slug: 'general-labour',
    title: 'General Labour',
    icon: Icons.groups_rounded,
    accent: Color(0xFF7A53BA),
    surface: Color(0xFFF3EDFF),
    badgeSurface: Color(0xFFE5DAFA),
    photoAsset: 'assets/images/categories/category_professional.webp',
  );
  static const venue = WantokCategoryStyle(
    slug: 'venue-booking',
    title: 'Venue Booking',
    icon: Icons.apartment_rounded,
    accent: Color(0xFF8E56AA),
    surface: Color(0xFFF8EFFE),
    badgeSurface: Color(0xFFEEDCF9),
    photoAsset: 'assets/images/hero_events.png',
  );
  static const hotels = WantokCategoryStyle(
    slug: 'accommodation',
    title: 'Hotels',
    icon: Icons.hotel_rounded,
    accent: Color(0xFFD04C7B),
    surface: Color(0xFFFFEFF4),
    badgeSurface: Color(0xFFFFD9E6),
    photoAsset: 'assets/images/categories/category_home_services.webp',
  );

  // Catalogue-only addition: reuse bundled imagery (no new generation).
  static const education = WantokCategoryStyle(
    slug: 'education-training',
    title: 'Education &\nTraining',
    icon: Icons.school_rounded,
    accent: Color(0xFFBC693E),
    surface: Color(0xFFFFEDE6),
    badgeSurface: Color(0xFFFFDACC),
    photoAsset: 'assets/images/categories/category_professional.webp',
  );
  static const financial = WantokCategoryStyle(
    slug: 'financial-services',
    title: 'Financial\nServices',
    icon: Icons.account_balance_rounded,
    accent: Color(0xFF13856A),
    surface: Color(0xFFE9F8F0),
    badgeSurface: Color(0xFFD0F1E3),
    photoAsset: 'assets/images/categories/category_more.webp',
  );

  static const publicServices = WantokCategoryStyle(
    slug: 'public-services',
    title: 'Public\nServices',
    icon: Icons.account_balance_rounded,
    accent: Color(0xFF005337),
    surface: Color(0xFFFFF2C6),
    badgeSurface: Color(0xFFFFE49B),
  );

  static const reference = <WantokCategoryStyle>[
    taxi,
    food,
    groceries,
    shopping,
    home,
    beauty,
    health,
    travel,
    events,
    professional,
    automotive,
    delivery,
    hotels,
    education,
    financial,
    waterRides,
    labour,
    publicServices,
    more,
  ];

  static WantokCategoryStyle bySlug(String? slug) => switch (slug) {
    'taxi-ride' || 'taxi' => taxi,
    'food' || 'restaurants' => food,
    'groceries' => groceries,
    'shopping' || 'shopping-retail' => shopping,
    'home-services' => home,
    'beauty' || 'wellness' || 'beauty-wellness' => beauty,
    'health' || 'medical' || 'health-medical' => health,
    'travel' || 'flights' || 'travel-flights' => travel,
    'events' => events,
    'professional-services' || 'specialist-services' => professional,
    'vehicle-hire' || 'automotive' => automotive,
    'delivery' => delivery,
    'errands' => errands,
    'boat-hire' => boatHire,
    'boat-ship-rides' => waterRides,
    'general-labour' => labour,
    'venue-booking' => venue,
    'hotels' || 'accommodation' => hotels,
    'education-training' => education,
    'financial-services' => financial,
    'public-services' => publicServices,
    _ => more,
  };
}

/// A single illustration component shared by category tiles and compact
/// headers. Photographs are bundled locally and never require network access.
class WantokCategoryPicture extends StatelessWidget {
  const WantokCategoryPicture({
    super.key,
    required this.style,
    this.compact = false,
    this.borderRadius = 13,
  });

  final WantokCategoryStyle style;
  final bool compact;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: ColoredBox(
      color: style.badgeSurface,
      child: style.slug == 'more'
          ? Center(
              child: CircleAvatar(
                radius: compact ? 14 : 29,
                backgroundColor: const Color(0xFFE4EAF5),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: WantokColors.primary,
                  size: compact ? 20 : 30,
                ),
              ),
            )
          : style.photoAsset == null
          ? Center(
              child: Icon(
                style.icon,
                color: style.accent,
                size: compact ? 21 : 28,
              ),
            )
          : Image.asset(
              style.photoAsset!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  style.icon,
                  color: style.accent,
                  size: compact ? 21 : 28,
                ),
              ),
            ),
    ),
  );
}

/// The header badge uses the SAME photo identity as its category tile,
/// rather than a separate Material icon.
class WantokCategoryBadge extends StatelessWidget {
  const WantokCategoryBadge({
    super.key,
    required this.style,
    this.size = 43,
    this.iconSize = 23,
  });

  final WantokCategoryStyle style;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(color: style.badgeSurface, width: 1),
      boxShadow: [
        BoxShadow(
          color: style.accent.withValues(alpha: .11),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipOval(
      child: WantokCategoryPicture(
        style: style,
        compact: true,
        borderRadius: 0,
      ),
    ),
  );
}

/// Premium, photo-forward category card. One picture/label pairing across
/// Services, Home, All Services and development-only sample previews.
/// The booking, saved-category and navigation callbacks remain unchanged.
class WantokCategoryTile extends StatelessWidget {
  const WantokCategoryTile({
    super.key,
    required this.style,
    required this.onTap,
    this.label,
    this.compact = false,
    this.badge,
    this.saved,
    this.onSavedToggle,
  });

  final WantokCategoryStyle style;
  final VoidCallback onTap;
  final String? label;
  final bool compact;
  final String? badge;
  final bool? saved;
  final VoidCallback? onSavedToggle;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 18 : 21),
      child: Ink(
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(compact ? 18 : 21),
          border: Border.all(color: style.accent.withValues(alpha: .09)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF24334B).withValues(alpha: .07),
              blurRadius: compact ? 8 : 13,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 5 : 6,
                compact ? 5 : 6,
                compact ? 5 : 6,
                compact ? 7 : 9,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: compact ? 5 : 6,
                    child: SizedBox(
                      width: double.infinity,
                      child: WantokCategoryPicture(
                        style: style,
                        compact: compact,
                        borderRadius: compact ? 13 : 16,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Flexible(
                    flex: 3,
                    child: Center(
                      child: Text(
                        label ?? style.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 10.2 : 11.5,
                          height: 1.12,
                          letterSpacing: -.15,
                          fontWeight: FontWeight.w800,
                          color: WantokColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 6,
                left: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: style.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ),
            if (onSavedToggle != null)
              Positioned(
                right: 3,
                top: 3,
                child: SizedBox(
                  height: 27,
                  width: 27,
                  child: IconButton(
                    tooltip: saved == true
                        ? 'Remove saved category'
                        : 'Save category',
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    onPressed: onSavedToggle,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .95),
                    ),
                    icon: Icon(
                      saved == true
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: style.accent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
