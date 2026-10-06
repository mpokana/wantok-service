import 'wantok_backend.dart';

class ClientProviderDiscovery {
  const ClientProviderDiscovery({
    required this.providerId,
    required this.displayName,
    required this.providerType,
    required this.bio,
    required this.ratingAverage,
    required this.ratingCount,
    required this.serviceCount,
    required this.categoryIds,
    required this.categoryNames,
    required this.serviceTitles,
    required this.coverageProvinces,
    required this.coverageTowns,
    required this.organicScore,
  });

  final String providerId;
  final String displayName;
  final String providerType;
  final String? bio;
  final double ratingAverage;
  final int ratingCount;
  final int serviceCount;
  final List<String> categoryIds;
  final List<String> categoryNames;
  final List<String> serviceTitles;
  final List<String> coverageProvinces;
  final List<String> coverageTowns;
  final double organicScore;

  bool get hasRatings => ratingCount > 0;

  factory ClientProviderDiscovery.fromMap(Map<String, dynamic> row) {
    return ClientProviderDiscovery(
      providerId: row['provider_id'] as String,
      displayName: row['display_name'] as String? ?? 'Wantok Provider',
      providerType: row['provider_type'] as String? ?? 'individual',
      bio: row['bio'] as String?,
      ratingAverage: _toDouble(row['rating_average']) ?? 0,
      ratingCount: _toInt(row['rating_count']) ?? 0,
      serviceCount: _toInt(row['service_count']) ?? 0,
      categoryIds: _stringList(row['category_ids']),
      categoryNames: _stringList(row['category_names']),
      serviceTitles: _stringList(row['service_titles']),
      coverageProvinces: _stringList(row['coverage_provinces']),
      coverageTowns: _stringList(row['coverage_towns']),
      organicScore: _toDouble(row['organic_score']) ?? 0,
    );
  }
}

class ClientProviderService {
  const ClientProviderService({
    required this.id,
    required this.title,
    required this.description,
    required this.pricingModel,
    required this.basePrice,
    required this.currency,
    required this.unitLabel,
    required this.coverageProvince,
    required this.coverageTown,
    required this.categoryId,
    required this.categorySlug,
    required this.categoryName,
  });

  final String id;
  final String title;
  final String? description;
  final String pricingModel;
  final double? basePrice;
  final String currency;
  final String? unitLabel;
  final String? coverageProvince;
  final String? coverageTown;
  final String categoryId;
  final String categorySlug;
  final String categoryName;

  factory ClientProviderService.fromMap(Map<String, dynamic> row) {
    final category = _asMap(row['service_categories']);
    return ClientProviderService(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Wantok service',
      description: row['description'] as String?,
      pricingModel: row['pricing_model'] as String? ?? 'quote',
      basePrice: _toDouble(row['base_price']),
      currency: row['currency'] as String? ?? 'PGK',
      unitLabel: row['unit_label'] as String?,
      coverageProvince: row['coverage_province'] as String?,
      coverageTown: row['coverage_town'] as String?,
      categoryId: category['id'] as String? ?? '',
      categorySlug: category['slug'] as String? ?? '',
      categoryName: category['name'] as String? ?? 'Service',
    );
  }
}

class ProviderDiscoveryRepository {
  const ProviderDiscoveryRepository();

  Future<List<ClientProviderDiscovery>> searchProviders({
    String? query,
    String? categoryId,
    String? province,
    String? town,
    int limit = 30,
  }) async {
    final result = await WantokBackend.client.rpc(
      'search_client_providers',
      params: {
        'p_query': _emptyToNull(query),
        'p_category_id': _emptyToNull(categoryId),
        'p_province': _emptyToNull(province),
        'p_town': _emptyToNull(town),
        'p_limit': limit,
      },
    );

    return (result as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClientProviderDiscovery.fromMap)
        .toList(growable: false);
  }

  Future<List<ClientProviderDiscovery>> loadTopProviders({
    String? categoryId,
    String? province,
    String? town,
    int poolLimit = 20,
    int displayLimit = 5,
  }) async {
    final result = await WantokBackend.client.rpc(
      'list_top_client_providers',
      params: {
        'p_category_id': _emptyToNull(categoryId),
        'p_province': _emptyToNull(province),
        'p_town': _emptyToNull(town),
        'p_pool_limit': poolLimit,
        'p_display_limit': displayLimit,
      },
    );

    return (result as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClientProviderDiscovery.fromMap)
        .toList(growable: false);
  }

  Future<List<ClientProviderService>> loadProviderServices(
    String providerId,
  ) async {
    final rows = await WantokBackend.client
        .from('provider_services')
        .select(
          'id, title, description, pricing_model, base_price, currency, unit_label, coverage_province, coverage_town, service_categories!inner(id, slug, name, is_active)',
        )
        .eq('provider_id', providerId)
        .eq('status', 'active')
        .eq('service_categories.is_active', true)
        .order('title');

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClientProviderService.fromMap)
        .toList(growable: false);
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return <String, dynamic>{};
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
