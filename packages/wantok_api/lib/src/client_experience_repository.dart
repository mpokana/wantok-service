import 'package:supabase_flutter/supabase_flutter.dart';

import 'wantok_backend.dart';

class SavedClientItem {
  const SavedClientItem({
    required this.itemType,
    required this.entityId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.createdAt,
  });

  final String itemType;
  final String entityId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final DateTime? createdAt;

  factory SavedClientItem.fromMap(Map<String, dynamic> row) {
    return SavedClientItem(
      itemType: row['item_type'] as String? ?? 'item',
      entityId: row['entity_id'] as String,
      title: row['title'] as String? ?? 'Saved Wantok item',
      subtitle: row['subtitle'] as String?,
      imageUrl: row['image_url'] as String?,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
    );
  }
}

class TrustedPerson {
  const TrustedPerson({
    required this.id,
    required this.displayName,
    required this.relationship,
    required this.phone,
    required this.email,
    required this.notes,
    required this.isActive,
  });

  final String id;
  final String displayName;
  final String? relationship;
  final String? phone;
  final String? email;
  final String? notes;
  final bool isActive;

  factory TrustedPerson.fromMap(Map<String, dynamic> row) {
    return TrustedPerson(
      id: row['id'] as String,
      displayName: row['display_name'] as String? ?? 'Trusted person',
      relationship: row['relationship'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      notes: row['notes'] as String?,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

class ClientReview {
  const ClientReview({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.photoUrls,
    required this.visibility,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String providerId;
  final String providerName;
  final int rating;
  final String? title;
  final String? comment;
  final List<String> photoUrls;
  final String visibility;
  final DateTime? createdAt;

  factory ClientReview.fromMap(Map<String, dynamic> row) {
    final provider = _mapValue(row['provider_profiles']);
    final rawPhotos = row['photo_urls'];
    return ClientReview(
      id: row['id'] as String,
      bookingId: row['booking_id'] as String,
      providerId: row['provider_id'] as String,
      providerName: provider['display_name'] as String? ?? 'Wantok Provider',
      rating: row['rating'] as int? ?? 0,
      title: row['title'] as String?,
      comment: row['comment'] as String?,
      photoUrls: rawPhotos is List
          ? rawPhotos.map((value) => value.toString()).toList(growable: false)
          : const <String>[],
      visibility: row['visibility'] as String? ?? 'public',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
    );
  }
}

class ClientExperienceRepository {
  const ClientExperienceRepository();

  SupabaseClient get _client => WantokBackend.client;

  User get _user {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user;
  }

  List<UserIdentity> get linkedIdentities =>
      List<UserIdentity>.unmodifiable(_user.identities ?? const []);

  Future<bool> linkIdentity(OAuthProvider provider) {
    return _client.auth.linkIdentity(provider);
  }

  Future<void> unlinkIdentity(UserIdentity identity) {
    return _client.auth.unlinkIdentity(identity);
  }

  Future<List<SavedClientItem>> loadSavedItems() async {
    final result = await _client.rpc('list_my_saved_items');
    return (result as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(SavedClientItem.fromMap)
        .toList(growable: false);
  }

  Future<Set<String>> loadSavedIds(String itemType) async {
    final items = await loadSavedItems();
    return items
        .where((item) => item.itemType == itemType)
        .map((item) => item.entityId)
        .toSet();
  }

  Future<void> setSavedItem({
    required String itemType,
    required String entityId,
    required bool saved,
  }) {
    return _client.rpc(
      'set_client_saved_item',
      params: {
        'p_item_type': itemType,
        'p_entity_id': entityId,
        'p_saved': saved,
      },
    );
  }

  Future<List<TrustedPerson>> loadTrustedPeople({
    bool includeInactive = false,
  }) async {
    dynamic query = _client
        .from('trusted_people')
        .select(
          'id, display_name, relationship, phone, email, notes, is_active, created_at, updated_at',
        )
        .eq('owner_id', _user.id);

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    final rows = await query.order('display_name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TrustedPerson.fromMap)
        .toList(growable: false);
  }

  Future<void> addTrustedPerson({
    required String displayName,
    String? relationship,
    String? phone,
    String? email,
    String? notes,
  }) async {
    await _client.from('trusted_people').insert({
      'owner_id': _user.id,
      'display_name': displayName.trim(),
      'relationship': _emptyToNull(relationship),
      'phone': _emptyToNull(phone),
      'email': _emptyToNull(email),
      'notes': _emptyToNull(notes),
      'is_active': true,
    });
  }

  Future<void> updateTrustedPerson(
    TrustedPerson person, {
    required String displayName,
    String? relationship,
    String? phone,
    String? email,
    String? notes,
    required bool isActive,
  }) async {
    await _client
        .from('trusted_people')
        .update({
          'display_name': displayName.trim(),
          'relationship': _emptyToNull(relationship),
          'phone': _emptyToNull(phone),
          'email': _emptyToNull(email),
          'notes': _emptyToNull(notes),
          'is_active': isActive,
        })
        .eq('id', person.id)
        .eq('owner_id', _user.id);
  }

  Future<void> deleteTrustedPerson(String id) async {
    await _client
        .from('trusted_people')
        .delete()
        .eq('id', id)
        .eq('owner_id', _user.id);
  }

  Future<List<ClientReview>> loadMyReviews() async {
    final rows = await _client
        .from('service_reviews')
        .select(
          'id, booking_id, provider_id, rating, title, comment, photo_urls, visibility, created_at, provider_profiles(display_name)',
        )
        .eq('reviewer_id', _user.id)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClientReview.fromMap)
        .toList(growable: false);
  }

  Future<void> submitServiceReview({
    required String bookingId,
    required int rating,
    String? title,
    String? comment,
    List<String> photoUrls = const [],
    String? visibility,
  }) async {
    await _client.rpc(
      'submit_service_review',
      params: {
        'p_booking_id': bookingId,
        'p_rating': rating,
        'p_comment': _emptyToNull(comment),
        'p_title': _emptyToNull(title),
        'p_photo_urls': photoUrls,
        'p_visibility': _emptyToNull(visibility),
      },
    );
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return <String, dynamic>{};
}
