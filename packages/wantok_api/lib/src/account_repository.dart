import 'package:supabase_flutter/supabase_flutter.dart';

import 'wantok_backend.dart';

class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.fullName,
    required this.preferredName,
    required this.phone,
    required this.addressText,
    required this.avatarUrl,
    required this.bio,
    required this.notifyBookingUpdates,
    required this.notifyMessages,
    required this.notifyPromotions,
    required this.profileVisibility,
    required this.reviewVisibility,
    required this.savedItemsPrivate,
    required this.allowRecommendations,
    required this.allowProfileSharing,
  });

  final String id;
  final String fullName;
  final String? preferredName;
  final String? phone;
  final String? addressText;
  final String? avatarUrl;
  final String? bio;
  final bool notifyBookingUpdates;
  final bool notifyMessages;
  final bool notifyPromotions;
  final String profileVisibility;
  final String reviewVisibility;
  final bool savedItemsPrivate;
  final bool allowRecommendations;
  final bool allowProfileSharing;

  String get displayName {
    final preferred = preferredName?.trim();
    if (preferred != null && preferred.isNotEmpty) return preferred;
    return fullName;
  }

  factory AccountProfile.fromMap(Map<String, dynamic> row) {
    return AccountProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String? ?? 'Wantok user',
      preferredName: row['preferred_name'] as String?,
      phone: row['phone'] as String?,
      addressText: row['address_text'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      notifyBookingUpdates: row['notify_booking_updates'] as bool? ?? true,
      notifyMessages: row['notify_messages'] as bool? ?? true,
      notifyPromotions: row['notify_promotions'] as bool? ?? false,
      profileVisibility: row['profile_visibility'] as String? ?? 'private',
      reviewVisibility: row['review_visibility'] as String? ?? 'public',
      savedItemsPrivate: row['saved_items_private'] as bool? ?? true,
      allowRecommendations: row['allow_recommendations'] as bool? ?? true,
      allowProfileSharing: row['allow_profile_sharing'] as bool? ?? true,
    );
  }
}

class ProviderAccountProfile {
  const ProviderAccountProfile({
    required this.providerId,
    required this.displayName,
    required this.providerType,
    required this.bio,
    required this.verificationStatus,
    required this.isActive,
    required this.baseAddress,
    required this.serviceRadiusKm,
  });

  final String providerId;
  final String displayName;
  final String providerType;
  final String? bio;
  final String verificationStatus;
  final bool isActive;
  final String? baseAddress;
  final double? serviceRadiusKm;

  factory ProviderAccountProfile.fromMap(Map<String, dynamic> row) {
    return ProviderAccountProfile(
      providerId: row['provider_id'] as String,
      displayName: row['display_name'] as String? ?? 'Wantok Provider',
      providerType: row['provider_type'] as String? ?? 'individual',
      bio: row['bio'] as String?,
      verificationStatus: row['verification_status'] as String? ?? 'pending',
      isActive: row['is_active'] as bool? ?? false,
      baseAddress: row['base_address'] as String?,
      serviceRadiusKm: _toDouble(row['service_radius_km']),
    );
  }
}

class AccountRepository {
  const AccountRepository();

  SupabaseClient get _client => WantokBackend.client;

  User get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user;
  }

  String? get email => currentUser.email;

  Future<AccountProfile> loadAccountProfile() async {
    final result = await _client.rpc('get_my_account_profile_v2');
    final rows = (result as List<dynamic>).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      throw StateError('Account profile not found.');
    }
    return AccountProfile.fromMap(rows.first);
  }

  Future<ProviderAccountProfile?> loadProviderProfile() async {
    final result = await _client.rpc('get_my_provider_profile');
    final rows = (result as List<dynamic>).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return null;
    return ProviderAccountProfile.fromMap(rows.first);
  }

  Future<void> updateAccountProfile({
    required String fullName,
    String? preferredName,
    String? phone,
    String? addressText,
    String? avatarUrl,
    String? bio,
    required bool notifyBookingUpdates,
    required bool notifyMessages,
    required bool notifyPromotions,
    String? profileVisibility,
    String? reviewVisibility,
    bool? savedItemsPrivate,
    bool? allowRecommendations,
    bool? allowProfileSharing,
  }) async {
    final current = await loadAccountProfile();

    await _client.rpc(
      'update_my_account_profile_v2',
      params: {
        'p_full_name': fullName,
        'p_preferred_name': preferredName,
        'p_phone': phone,
        'p_address_text': addressText,
        'p_avatar_url': avatarUrl ?? current.avatarUrl,
        'p_bio': bio ?? current.bio,
        'p_notify_booking_updates': notifyBookingUpdates,
        'p_notify_messages': notifyMessages,
        'p_notify_promotions': notifyPromotions,
        'p_profile_visibility': profileVisibility ?? current.profileVisibility,
        'p_review_visibility': reviewVisibility ?? current.reviewVisibility,
        'p_saved_items_private': savedItemsPrivate ?? current.savedItemsPrivate,
        'p_allow_recommendations':
            allowRecommendations ?? current.allowRecommendations,
        'p_allow_profile_sharing':
            allowProfileSharing ?? current.allowProfileSharing,
      },
    );
  }

  Future<void> updateProviderProfile({
    required String displayName,
    required String providerType,
    String? bio,
    String? baseAddress,
    double? serviceRadiusKm,
  }) async {
    await _client.rpc(
      'update_my_provider_profile',
      params: {
        'p_display_name': displayName,
        'p_provider_type': providerType,
        'p_bio': bio,
        'p_base_address': baseAddress,
        'p_service_radius_km': serviceRadiusKm,
      },
    );
  }

  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw ArgumentError('Password must contain at least 8 characters.');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
