import 'wantok_backend.dart';

class ProviderApplicationRepository {
  const ProviderApplicationRepository();

  String get _userId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> loadMyApplications() async {
    final rows = await WantokBackend.client
        .from('provider_applications')
        .select(
          'id, service_type, company_name, vehicle_plate, vehicle_make, '
          'vehicle_model, vehicle_color, notes, status, reviewed_at, '
          'created_at',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> submitApplication({
    required String serviceType,
    String? companyName,
    String? vehiclePlate,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? notes,
  }) async {
    await WantokBackend.client.rpc(
      'submit_provider_application',
      params: {
        'p_service_type': serviceType,
        'p_company_name': _emptyToNull(companyName),
        'p_vehicle_plate': _emptyToNull(vehiclePlate),
        'p_vehicle_make': _emptyToNull(vehicleMake),
        'p_vehicle_model': _emptyToNull(vehicleModel),
        'p_vehicle_color': _emptyToNull(vehicleColor),
        'p_notes': _emptyToNull(notes),
      },
    );
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
