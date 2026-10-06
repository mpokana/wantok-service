import 'wantok_backend.dart';

class OpenRequestRepository {
  const OpenRequestRepository();

  Future<void> createRequest({
    required String categorySlug,
    String? serviceAddress,
    String? originAddress,
    String? destinationAddress,
    DateTime? scheduledStart,
    String? notes,
    double? requestedAmount,
    double quantity = 1,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String? trustedPersonId,
  }) async {
    await WantokBackend.client.rpc(
      'create_open_service_request',
      params: {
        'p_category_slug': categorySlug,
        'p_service_address': _emptyToNull(serviceAddress),
        'p_origin_address': _emptyToNull(originAddress),
        'p_destination_address': _emptyToNull(destinationAddress),
        'p_scheduled_start': scheduledStart?.toUtc().toIso8601String(),
        'p_notes': _emptyToNull(notes),
        'p_requested_amount': requestedAmount,
        'p_quantity': quantity,
        'p_metadata': metadata,
        'p_trusted_person_id': trustedPersonId,
      },
    );
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
