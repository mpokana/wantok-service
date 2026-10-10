import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'reference_services_gallery.dart';
import 'wantok_category_ui.dart';

/// Web/tablet presentation of the canonical service categories.
/// Resolves every tap through the existing authorised ServicesHubPage routes.
class EnterpriseServicesCatalogue extends StatefulWidget {
  const EnterpriseServicesCatalogue({
    required this.onCategory,
    required this.onAllServices,
    this.onSearch,
    super.key,
  });
  final ValueChanged<ReferenceCategorySpec> onCategory;
  final VoidCallback onAllServices;
  final ValueChanged<String>? onSearch;
  @override
  State<EnterpriseServicesCatalogue> createState() =>
      _EnterpriseServicesCatalogueState();
}

class _EnterpriseServicesCatalogueState
    extends State<EnterpriseServicesCatalogue> {
  final _search = TextEditingController();
  String _filter = 'All';
  String _query = '';
  static const filters = [
    'All',
    'Transport',
    'Food',
    'Groceries',
    'Delivery',
    'Travel',
    'Stay',
    'Specialists',
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(ReferenceCategorySpec spec) {
    final slug = spec.slug ?? '';
    final q = _query.trim().toLowerCase();
    final search =
        q.isEmpty || spec.title.toLowerCase().contains(q) || slug.contains(q);
    final type = switch (_filter) {
      'Transport' => [
        'taxi-ride',
        'vehicle-hire',
        'boat-ship-rides',
      ].contains(slug),
      'Food' => slug == 'food',
      'Groceries' => slug == 'groceries',
      'Delivery' => slug == 'delivery',
      'Travel' => ['travel-flights', 'boat-ship-rides'].contains(slug),
      'Stay' => slug == 'accommodation',
      'Specialists' => [
        'specialist-services',
        'home-services',
        'general-labour',
      ].contains(slug),
      _ => true,
    };
    return search && type;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final desktop = size.maxWidth >= 1120;
      final items = ReferenceServiceCategories.items
          .where((e) => e.slug != 'more' && _matches(e))
          .toList(growable: false);
      return ListView(
        key: const ValueKey('enterprise-services-catalogue'),
        padding: EdgeInsets.fromLTRB(
          desktop ? 28 : 16,
          18,
          desktop ? 28 : 16,
          34,
        ),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height:
                  (desktop ? 175.0 : 172.0) +
                  (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(
                        0.0,
                        2.0,
                      ) *
                      140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/hero_water.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF06442E),
                          Color(0xE6064831),
                          Color(0x22064831),
                        ],
                        stops: [0, .55, 1],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(23),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SERVICES MARKETPLACE',
                          style: TextStyle(
                            color: WantokColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'All Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Find services and local providers across Papua New Guinea.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('enterprise-services-search'),
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: widget.onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search services, providers or locations (e.g. taxi, plumbing)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(() {
                              _query = '';
                              _search.clear();
                            }),
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => widget.onSearch?.call(_query),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, i) => ChoiceChip(
                key: ValueKey('enterprise-filter-${filters[i]}'),
                label: Text(filters[i]),
                selected: _filter == filters[i],
                onSelected: (_) => setState(() => _filter = filters[i]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _cards(items)),
                const SizedBox(width: 19),
                SizedBox(width: 255, child: _sidebar()),
              ],
            )
          else ...[
            _cards(items),
            const SizedBox(height: 15),
            _sidebar(),
          ],
        ],
      );
    },
  );

  Widget _cards(List<ReferenceCategorySpec> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Browse by category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${items.length} categories',
            style: const TextStyle(color: WantokColors.muted),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Text('No matching categories. Try another search.'),
          ),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 245,
            mainAxisExtent: 198,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, i) {
            final spec = items[i];
            return Material(
              color: Colors.white,
              elevation: .4,
              borderRadius: BorderRadius.circular(17),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('enterprise-category-${spec.title}'),
                onTap: () => widget.onCategory(spec),
                child: Column(
                  children: [
                    SizedBox(
                      height: 108,
                      width: double.infinity,
                      child: WantokCategoryPicture(
                        style: spec.style,
                        borderRadius: 0,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: spec.style.badgeSurface,
                              child: Icon(
                                spec.style.icon,
                                size: 17,
                                color: spec.style.accent,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                spec.title.replaceAll('\n', ' '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 17,
                              color: WantokColors.muted,
                            ),
                          ],
                        ),
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

  Widget _sidebar() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFE4F4EA), Color(0xFFFFF6E2)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.storefront_rounded,
              color: WantokColors.primary,
              size: 36,
            ),
            const SizedBox(height: 11),
            const Text(
              'Looking for a specific provider?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: WantokColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find approved providers, real ratings and available local services.',
              style: TextStyle(color: WantokColors.muted),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onAllServices,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Browse providers'),
                style: FilledButton.styleFrom(
                  backgroundColor: WantokColors.gold,
                  foregroundColor: WantokColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: WantokColors.primary),
              SizedBox(height: 6),
              Text(
                'Real services. Real people.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'Only providers approved by the connected catalogue may appear.',
                style: TextStyle(color: WantokColors.muted),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
