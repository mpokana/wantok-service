import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Editorial discovery themes only, not live events, listings or bookings.
/// Uses imagery bundled with the app and opens only existing services.
class ExploreInspirationGrid extends StatelessWidget {
  const ExploreInspirationGrid({this.onBrowseServices, super.key});

  final VoidCallback? onBrowseServices;
  static const inspirations =
      <({String title, String description, String asset, IconData icon})>[
        (
          title: 'Coast & water',
          description: 'Discover ways to connect across the islands.',
          asset: 'assets/images/hero_water.png',
          icon: Icons.sailing_outlined,
        ),
        (
          title: 'Communities & events',
          description: 'Explore local gatherings and community services.',
          asset: 'assets/images/hero_events.png',
          icon: Icons.celebration_outlined,
        ),
        (
          title: 'People & skills',
          description: 'Find services and skilled people around you.',
          asset: 'assets/images/hero_trades.png',
          icon: Icons.handyman_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 480
          ? 2
          : 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore more of PNG',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: WantokColors.ink,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Explore themes and inspiration. Bookable experiences will appear '
            'only when connected providers are available.',
            style: TextStyle(fontSize: 13, color: WantokColors.muted),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            key: const ValueKey('explore-inspiration-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inspirations.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 232,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final entry = inspirations[index];
              return Material(
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                elevation: .3,
                child: InkWell(
                  key: ValueKey('explore-theme-$index'),
                  onTap: onBrowseServices,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.asset(entry.asset, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE1F3E9),
                              child: Icon(
                                entry.icon,
                                size: 18,
                                color: WantokColors.primary,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: WantokColors.ink,
                                    ),
                                  ),
                                  Text(
                                    entry.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: WantokColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onBrowseServices != null)
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: WantokColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
