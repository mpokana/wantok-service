import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'wantok_backend.dart';

/// Public reads receive published appearance only. Every write uses server-side
/// technical-platform-admin RBAC with optimistic revision protection.
class BrandingRepository {
  const BrandingRepository();

  static const bucket = 'wantok-branding';
  static const defaultDocument = <String, dynamic>{
    'theme': <String, dynamic>{
      'mode': 'light',
      'primary': '#006747',
      'secondary': '#F3C846',
      'cardRadius': 18,
    },
    'media': <String, dynamic>{},
  };

  Future<Map<String, dynamic>> getPublished() async {
    final response = await WantokBackend.client.rpc(
      'get_published_wantok_branding',
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<BrandingWorkspace> getWorkspace() async {
    final response = await WantokBackend.client.rpc(
      'get_wantok_branding_workspace',
    );
    final doc = Map<String, dynamic>.from(response as Map);
    return BrandingWorkspace(
      draft: Map<String, dynamic>.from(doc['draft'] as Map),
      published: Map<String, dynamic>.from(doc['published'] as Map),
      version: (doc['version'] as num).toInt(),
      draftRevision: (doc['draftRevision'] as num).toInt(),
    );
  }

  Future<int> saveDraft(Map<String, dynamic> config, int revision) async {
    final result = await WantokBackend.client.rpc(
      'save_wantok_branding_draft',
      params: {'p_config': config, 'p_draft_revision': revision},
    );
    return (result as num).toInt();
  }

  Future<int> publish(int version, int revision) async {
    final result = await WantokBackend.client.rpc(
      'publish_wantok_branding_draft',
      params: {'p_version': version, 'p_draft_revision': revision},
    );
    return (result as num).toInt();
  }

  Future<int> restore(int historyVersion, int currentVersion) async {
    final result = await WantokBackend.client.rpc(
      'restore_wantok_branding_version',
      params: {
        'p_history_version': historyVersion,
        'p_current_version': currentVersion,
      },
    );
    return (result as num).toInt();
  }

  /// Immutable paths ensure old versions continue to resolve after rollback.
  Future<String> upload({
    required String slug,
    required String slot,
    required String extension,
    required Uint8List bytes,
  }) async {
    if (!RegExp(r'^[a-z0-9-]{2,65}$').hasMatch(slug) ||
        !const {'homeIcon', 'cardImage', 'bannerImage'}.contains(slot) ||
        !const {'jpg', 'png', 'webp'}.contains(extension)) {
      throw ArgumentError('Invalid category, media slot or image type.');
    }
    if (bytes.isEmpty || bytes.length > 3 * 1024 * 1024) {
      throw ArgumentError('Images must be under 3 MB.');
    }
    final mime = switch (extension) {
      'jpg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
    final path = 'categories/$slug/$slot/${const Uuid().v4()}.$extension';
    await WantokBackend.client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    return path;
  }

  static String imageUrl(String path) {
    return WantokBackend.client.storage.from(bucket).getPublicUrl(path);
  }
}

class BrandingWorkspace {
  const BrandingWorkspace({
    required this.draft,
    required this.published,
    required this.version,
    required this.draftRevision,
  });

  final Map<String, dynamic> draft;
  final Map<String, dynamic> published;
  final int version;
  final int draftRevision;
}
