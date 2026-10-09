import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_api/wantok_api.dart';

import '../home/reference_services_gallery.dart';
import '../home/smoke_data.dart';

/// Deterministic, in-memory visual category set for owner review.
/// No provider identities, approvals, orders or financial records are created.
abstract final class OfflineDemoCatalogue {
  static final List<WantokServiceCategory>
  services = List<WantokServiceCategory>.unmodifiable([
    for (var i = 0; i < ReferenceServiceCategories.items.length; i++)
      if (ReferenceServiceCategories.items[i].slug != null)
        WantokServiceCategory(
          id: '${WantokSmokeData.namespace}_CATEGORY_${(i + 1).toString().padLeft(3, '0')}',
          slug: ReferenceServiceCategories.items[i].slug!,
          name: ReferenceServiceCategories.items[i].title,
          vertical: 'visual-demo',
          bookingMode: 'information',
          description:
              'SAMPLE ONLY — interactive design preview, not a real offer.',
          sortOrder: i,
        ),
  ]);

  static const providers = <ClientProviderDiscovery>[
    ClientProviderDiscovery(
      providerId: 'SMOKE_20261008_PROVIDER_001',
      displayName: 'SAMPLE · The Waterfront',
      providerType: 'business',
      bio: 'Illustrative restaurant card only, not a verified merchant.',
      ratingAverage: 0,
      ratingCount: 0,
      serviceCount: 1,
      categoryIds: ['SMOKE_20261008_CATEGORY_002'],
      categoryNames: ['Food'],
      serviceTitles: ['Sample restaurant'],
      coverageProvinces: ['National Capital District'],
      coverageTowns: ['Port Moresby'],
      organicScore: 0,
    ),
    ClientProviderDiscovery(
      providerId: 'SMOKE_20261008_PROVIDER_002',
      displayName: 'SAMPLE · Local market vendor',
      providerType: 'business',
      bio: 'Demonstration market listing only.',
      ratingAverage: 0,
      ratingCount: 0,
      serviceCount: 1,
      categoryIds: ['SMOKE_20261008_CATEGORY_003'],
      categoryNames: ['Groceries'],
      serviceTitles: ['Sample market groceries'],
      coverageProvinces: ['Morobe'],
      coverageTowns: ['Lae'],
      organicScore: 0,
    ),
  ];

  static Future<List<WantokServiceCategory>> load() async => services;
  static Future<List<ClientProviderDiscovery>> loadProviders() async =>
      providers;
}
