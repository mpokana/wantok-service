import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'wantok_category_ui.dart';

typedef ServiceArt = ({
  String icon,
  String photo,
  String title,
  String subtitle,
});

/// Artwork cropped from the three references supplied by the app owner.
abstract final class ScreenshotServiceArt {
  static const items = <String, ServiceArt>{
    'taxi-ride': (
      icon: 'services_taxi_icon.png',
      photo: 'services_taxi_photo.jpg',
      title: 'Taxi / Transport',
      subtitle: 'Taxis, PMVs, buses and local transport.',
    ),
    'vehicle-hire': (
      icon: 'services_hire_icon.png',
      photo: 'services_hire_photo.jpg',
      title: 'Hire Car',
      subtitle: 'Car rentals for work, travel or everyday use.',
    ),
    'food': (
      icon: 'services_food_icon.png',
      photo: 'services_food_photo.jpg',
      title: 'Food',
      subtitle: 'Restaurants, cafés, takeaway and more.',
    ),
    'groceries': (
      icon: 'services_groceries_icon.png',
      photo: 'services_groceries_photo.jpg',
      title: 'Groceries',
      subtitle: 'Supermarkets, fresh food and local stores.',
    ),
    'delivery': (
      icon: 'services_delivery_icon.png',
      photo: 'services_delivery_photo.jpg',
      title: 'Delivery',
      subtitle: 'Food, groceries, parcels and more.',
    ),
    'travel-flights': (
      icon: 'services_travel_icon.png',
      photo: 'services_travel_photo.jpg',
      title: 'Travel & Flights',
      subtitle: 'Flights, hotels, tours and travel services.',
    ),
    'specialist-services': (
      icon: 'services_specialists_icon.png',
      photo: 'services_specialists_photo.jpg',
      title: 'Specialists',
      subtitle: 'Find trusted local professionals.',
    ),
    'public-services': (
      icon: 'services_public_icon.png',
      photo: 'services_public_photo.jpg',
      title: 'Public Services',
      subtitle: 'Government, health and community services.',
    ),
  };

  static const priority = <String>[
    'taxi-ride',
    'vehicle-hire',
    'food',
    'groceries',
    'delivery',
    'travel-flights',
    'specialist-services',
    'public-services',
  ];
  static String asset(String file) => 'assets/images/reference/$file';

  static Widget visual(
    BuildContext context,
    ServiceArt art, {
    required bool icon,
    BoxFit fit = BoxFit.cover,
  }) {
    // Web and Android now use the SAME photo and published cardImage slot,
    // including the existing Public Services photograph.
    final slug = items.entries.firstWhere((entry) => entry.value == art).key;
    return WantokCategoryPicture(
      style: WantokCategoryStyles.bySlug(slug),
      compact: icon,
      mediaSlot: icon ? 'homeIcon' : 'cardImage',
      borderRadius: 0,
    );
  }
}

class ScreenshotHomeTile extends StatelessWidget {
  const ScreenshotHomeTile({required this.art, required this.onTap, super.key});
  final ServiceArt art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6EDF1)),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
        child: Column(
          children: [
            Expanded(
              child: ScreenshotServiceArt.visual(
                context,
                art,
                icon: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    art.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      color: WantokColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: WantokColors.ink,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ScreenshotServicesCard extends StatelessWidget {
  const ScreenshotServicesCard({
    required this.art,
    required this.onTap,
    super.key,
  });
  final ServiceArt art;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5EDF2)),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // Large accessibility text needs more vertical caption space.
              flex: MediaQuery.textScalerOf(context).scale(1) > 1.25 ? 8 : 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 7, 5),
                child: Row(
                  children: [
                    // The large photograph below is the single category image.
                    // Keep this caption text-only so it is not repeated.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            art.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WantokColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            art.subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WantokColors.muted,
                              fontSize: 9.5,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: WantokColors.ink,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: MediaQuery.textScalerOf(context).scale(1) > 1.25 ? 4 : 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: ScreenshotServiceArt.visual(context, art, icon: false),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
