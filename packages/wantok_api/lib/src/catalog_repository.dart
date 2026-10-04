import 'package:wantok_core/wantok_core.dart';

import 'wantok_backend.dart';

class CatalogRepository {
  const CatalogRepository();

  Future<List<WantokServiceCategory>> loadActiveServices() async {
    final response = await WantokBackend.client
        .from('service_categories')
        .select(
          'id, slug, name, description, vertical, booking_mode, icon_key, is_active, sort_order',
        )
        .eq('is_active', true)
        .order('sort_order')
        .order('name');

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WantokServiceCategory.fromMap)
        .toList(growable: false);
  }
}
