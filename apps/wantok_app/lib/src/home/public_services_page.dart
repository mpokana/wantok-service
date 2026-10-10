import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Non-transactional public information directory.
/// Only verified official links should be added here in a later rollout.
class PublicServicesPage extends StatelessWidget {
  const PublicServicesPage({super.key});

  static const areas = <PublicServiceArea>[
    PublicServiceArea(
      title: 'Emergency & Safety',
      subtitle: 'Police, fire, ambulance, safety support.',
      icon: Icons.emergency_rounded,
      accent: Color(0xFFE02024),
      surface: Color(0xFFFFE4E4),
      photo: 'assets/images/reference/public_emergency_photo.jpg',
      iconAsset: 'assets/images/reference/public_emergency_icon.png',
      topics: [
        'Police',
        'Fire & rescue',
        'Ambulance',
        'Search & rescue',
        'Disaster response',
      ],
    ),
    PublicServiceArea(
      title: 'Health Services',
      subtitle: 'Hospitals, clinics, pharmacies, blood donation.',
      icon: Icons.health_and_safety_rounded,
      accent: Color(0xFF006D48),
      surface: Color(0xFFDAF7E5),
      photo: 'assets/images/reference/public_health_photo.jpg',
      iconAsset: 'assets/images/reference/public_health_icon.png',
      topics: [
        'Hospitals',
        'Health centres',
        'Clinics',
        'Pharmacies',
        'Blood donation',
      ],
    ),
    PublicServiceArea(
      title: 'Government Services',
      subtitle: 'NID, immigration, tax, licensing, offices.',
      icon: Icons.account_balance_rounded,
      accent: Color(0xFF005333),
      surface: Color(0xFFFFEDBA),
      photo: 'assets/images/reference/public_government_photo.jpg',
      iconAsset: 'assets/images/reference/public_government_icon.png',
      topics: [
        'National Identification (NID)',
        'Immigration',
        'Taxation',
        'Licensing',
        'Provincial offices',
      ],
    ),
    PublicServiceArea(
      title: 'Community Services',
      subtitle: 'NGOs, counselling, shelters, local support.',
      icon: Icons.groups_rounded,
      accent: Color(0xFF1163D9),
      surface: Color(0xFFDCEBFF),
      photo: 'assets/images/reference/public_community_photo.jpg',
      iconAsset: 'assets/images/reference/public_community_icon.png',
      topics: [
        'Charities & NGOs',
        'Counselling',
        'Shelters',
        'Community support',
        'Social services',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 900 ? 850.0 : width;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wantok Services',
              style: TextStyle(
                color: WantokColors.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'People. Places. Possibilities.',
              style: TextStyle(color: WantokColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              key: const ValueKey('public-services-page'),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
              children: [
                TextField(
                  key: const ValueKey('public-services-search'),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search public services or locations...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFE0E8EC)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onSubmitted: (value) {
                    final match = areas.where(
                      (area) =>
                          area.title.toLowerCase().contains(
                            value.trim().toLowerCase(),
                          ) ||
                          area.topics.any(
                            (topic) => topic.toLowerCase().contains(
                              value.trim().toLowerCase(),
                            ),
                          ),
                    );
                    if (value.trim().isNotEmpty && match.isNotEmpty) {
                      _openArea(context, match.first);
                    } else if (value.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No matching public service category yet.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 22),
                const Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: WantokColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find trusted services across Papua New Guinea.',
                  style: TextStyle(fontSize: 13, color: WantokColors.muted),
                ),
                const SizedBox(height: 16),
                _hero(context),
                const SizedBox(height: 21),
                Text(
                  'Public Services Categories',
                  key: _categoriesAnchor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: WantokColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explore key public service areas in Papua New Guinea.',
                  style: TextStyle(fontSize: 12, color: WantokColors.muted),
                ),
                const SizedBox(height: 13),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 320;
                    return GridView.builder(
                      key: const ValueKey('public-services-category-grid'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: areas.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: twoColumns ? 2 : 1,
                        mainAxisExtent: twoColumns ? 172 : 185,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) =>
                          _categoryCard(context, areas[index]),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Public service contacts and external links are added only after verification. '
                  'Wantok Services does not operate or dispatch emergency services.',
                  style: TextStyle(color: WantokColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(19),
    child: SizedBox(
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/reference/public_hero_photo.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF004329),
                  Color(0xF0004F33),
                  Color(0x33004F33),
                ],
                stops: [0, .59, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCF37),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 22,
                      color: Color(0xFF00462C),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Public Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Find essential public, government,\nhealth and community services.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.8,
                    height: 1.18,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  key: const ValueKey('public-services-explore'),
                  onPressed: () => Scrollable.ensureVisible(
                    _categoriesAnchor.currentContext ?? context,
                    duration: const Duration(milliseconds: 300),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Explore public services'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC32),
                    foregroundColor: const Color(0xFF10261C),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
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

  // Stable anchor for the banner action, independent of screen dimensions.
  static final GlobalKey _categoriesAnchor = GlobalKey();

  Widget _categoryCard(BuildContext context, PublicServiceArea area) =>
      Material(
        color: Colors.white,
        elevation: .6,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('public-area-${area.title}'),
          onTap: () => _openArea(context, area),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 9, 6),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: area.surface,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(area.iconAsset, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              area.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WantokColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              area.subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.4,
                                color: WantokColors.muted,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: WantokColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Image.asset(
                  area.photo,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: area.surface,
                    child: Icon(area.icon, color: area.accent, size: 35),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void _openArea(BuildContext context, PublicServiceArea area) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PublicServiceAreaPage(area: area),
        ),
      );
}

class PublicServiceArea {
  const PublicServiceArea({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.photo,
    required this.iconAsset,
    required this.topics,
  });
  final String title, subtitle, photo, iconAsset;
  final IconData icon;
  final Color accent, surface;
  final List<String> topics;
}

/// The second-level pages are deliberately informational, not booking forms.
class PublicServiceAreaPage extends StatelessWidget {
  const PublicServiceAreaPage({required this.area, super.key});
  final PublicServiceArea area;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FBFC),
    appBar: AppBar(title: Text(area.title)),
    body: ListView(
      key: ValueKey('public-area-page-${area.title}'),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: area.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(area.icon, size: 42, color: area.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(area.subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final topic in area.topics)
          Card(
            child: ListTile(
              title: Text(topic),
              leading: Icon(area.icon, color: area.accent),
              subtitle: const Text(
                'Official contact details are being verified.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Do not rely on this directory for immediate emergency response. '
          'Use your verified local emergency contacts directly.',
          style: TextStyle(fontSize: 12, color: WantokColors.muted),
        ),
      ],
    ),
  );
}
