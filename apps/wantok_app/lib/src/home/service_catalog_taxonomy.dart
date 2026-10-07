import 'package:flutter/material.dart';

/// Client-facing service taxonomy.
///
/// This keeps Home shortcuts and the full Services catalogue aligned while
/// allowing backend service categories to remain independently managed.
enum WantokServiceFamily {
  all(
    label: 'All services',
    shortLabel: 'All',
    subtitle: 'Everything available through Wantok Services.',
    icon: Icons.apps_rounded,
    slugs: <String>{},
  ),
  moveTravel(
    label: 'Move & travel',
    shortLabel: 'Move',
    subtitle: 'Rides, vehicle hire and water transport.',
    icon: Icons.route_rounded,
    slugs: <String>{
      'taxi-ride',
      'vehicle-hire',
      'boat-hire',
      'boat-ship-rides',
    },
  ),
  foodShopping(
    label: 'Food & shopping',
    shortLabel: 'Eat & shop',
    subtitle: 'Food, groceries and everyday shopping.',
    icon: Icons.shopping_basket_rounded,
    slugs: <String>{'food', 'groceries'},
  ),
  sendTasks(
    label: 'Send & errands',
    shortLabel: 'Send',
    subtitle: 'Delivery, courier and everyday errands.',
    icon: Icons.local_shipping_rounded,
    slugs: <String>{'delivery', 'errands'},
  ),
  peopleSkills(
    label: 'People & skills',
    shortLabel: 'People',
    subtitle: 'Specialists, trades and general labour.',
    icon: Icons.handyman_rounded,
    slugs: <String>{'specialist-services', 'general-labour'},
  ),
  bookEvents(
    label: 'Book & events',
    shortLabel: 'Book',
    subtitle: 'Venues, events and things to do.',
    icon: Icons.event_available_rounded,
    slugs: <String>{'venue-booking', 'events'},
  );

  const WantokServiceFamily({
    required this.label,
    required this.shortLabel,
    required this.subtitle,
    required this.icon,
    required this.slugs,
  });

  final String label;
  final String shortLabel;
  final String subtitle;
  final IconData icon;
  final Set<String> slugs;

  bool matches(String slug) =>
      this == WantokServiceFamily.all || slugs.contains(slug);

  static List<WantokServiceFamily> get catalogueFamilies => const [
    moveTravel,
    foodShopping,
    sendTasks,
    peopleSkills,
    bookEvents,
  ];
}

/// Home intentionally shows a small set of high-frequency entry points.
/// The complete catalogue remains in the Services tab.
const wantokHomeQuickAccessOrder = <String>[
  'taxi-ride',
  'food',
  'delivery',
  'vehicle-hire',
  'specialist-services',
  'groceries',
];
