import 'dart:typed_data';

import 'package:wantok_core/wantok_core.dart';
import 'branding_repository.dart';
import 'wantok_backend.dart';

/// Technical-only editing. Every write is re-authorised and audited in SQL.
/// Ordinary clients use CatalogRepository, never these RPC operations.
class CategoryManagementRepository {
  const CategoryManagementRepository();

  Future<List<ManagedServiceCategory>> loadAll() async {
    final result = await WantokBackend.client.rpc('list_managed_service_categories');
    return (result as List)
        .map((row) => ManagedServiceCategory.fromMap(
              Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<void> save(
    Map<String, dynamic> fields, {
    ManagedServiceCategory? existing,
  }) async {
    await WantokBackend.client.rpc(
      'manage_service_category',
      params: {
        'p_action': existing == null ? 'create' : 'update',
        'p_record': fields,
        'p_id': existing?.id,
        'p_expected_updated_at': existing?.updatedAt,
      },
    );
  }

  Future<void> archive(ManagedServiceCategory category) async {
    await WantokBackend.client.rpc('manage_service_category', params: {
      'p_action': 'archive',
      'p_record': <String, dynamic>{},
      'p_id': category.id,
      'p_expected_updated_at': category.updatedAt,
    });
  }

  Future<void> removeUnusedDraft(ManagedServiceCategory category) async {
    await WantokBackend.client.rpc('manage_service_category', params: {
      'p_action': 'remove',
      'p_record': <String, dynamic>{},
      'p_id': category.id,
      'p_expected_updated_at': category.updatedAt,
    });
  }

  Future<String> uploadPicture({
    required String slug,
    required String extension,
    required Uint8List bytes,
  }) => const BrandingRepository().upload(
    slug: slug,
    slot: 'cardImage',
    extension: extension,
    bytes: bytes,
  );
}

class ManagedServiceCategory extends WantokServiceCategory {
  const ManagedServiceCategory({
    required super.id,
    required super.slug,
    required super.name,
    required super.vertical,
    required super.bookingMode,
    super.description,
    super.iconKey,
    super.isActive,
    super.sortOrder,
    super.showOnHome,
    super.showInServices,
    super.imagePath,
    required this.updatedAt,
  });

  final String updatedAt;

  factory ManagedServiceCategory.fromMap(Map<String, dynamic> json) {
    return ManagedServiceCategory(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      vertical: json['vertical'] as String,
      bookingMode: json['booking_mode'] as String,
      iconKey: json['icon_key'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      showOnHome: json['show_on_home'] as bool? ?? false,
      showInServices: json['show_in_services'] as bool? ?? false,
      imagePath: json['image_path'] as String?,
      updatedAt: json['updated_at'] as String,
    );
  }
}
