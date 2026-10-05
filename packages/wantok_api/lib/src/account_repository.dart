import 'package:supabase_flutter/supabase_flutter.dart';

import 'wantok_backend.dart';

class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.fullName,
    required this.preferredName,
    required this.phone,
    required this.addressText,
    required this.notifyBookingUpdates,
    required this.notifyMessages,
    required this.notifyPromotions,
  });

  final String id;
  final String fullName;
  final String? preferredName;
  final String? phone;
  final String? addressText;
  final bool notifyBookingUpdates;
  final bool notifyMessages;
  final bool notifyPromotions;

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
      notifyBookingUpdates: row['notify_booking_updates'] as bool? ?? true,
      notifyMessages: row['notify_messages'] as bool? ?? true,
      notifyPromotions: row['notify_promotions'] as bool? ?? false,
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
    final result = await _client.rpc('get_my_account_profile');
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
    required bool notifyBookingUpdates,
    required bool notifyMessages,
    required bool notifyPromotions,
  }) async {
    await _client.rpc(
      'update_my_account_profile',
      params: {
        'p_full_name': fullName,
        'p_preferred_name': preferredName,
        'p_phone': phone,
        'p_address_text': addressText,
        'p_notify_booking_updates': notifyBookingUpdates,
        'p_notify_messages': notifyMessages,
        'p_notify_promotions': notifyPromotions,
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
