class ReservableOffer {
  const ReservableOffer({
    required this.categoryId,
    required this.categorySlug,
    required this.categoryName,
    required this.serviceId,
    required this.providerId,
    required this.providerName,
    required this.serviceTitle,
    required this.pricingModel,
    required this.currency,
    required this.resourceId,
    required this.resourceType,
    required this.resourceName,
    this.serviceDescription,
    this.basePrice,
    this.unitLabel,
    this.serviceAddress,
    this.providerRating,
    this.providerRatingCount = 0,
    this.resourceDescription,
    this.capacity,
    this.resourceAddress,
    this.metadata = const <String, dynamic>{},
  });

  final String categoryId;
  final String categorySlug;
  final String categoryName;
  final String serviceId;
  final String providerId;
  final String providerName;
  final String serviceTitle;
  final String? serviceDescription;
  final String pricingModel;
  final double? basePrice;
  final String currency;
  final String? unitLabel;
  final String? serviceAddress;
  final double? providerRating;
  final int providerRatingCount;
  final String resourceId;
  final String resourceType;
  final String resourceName;
  final String? resourceDescription;
  final int? capacity;
  final String? resourceAddress;
  final Map<String, dynamic> metadata;

  String get priceLabel {
    if (pricingModel == 'free') return 'Free';
    if (basePrice == null) return 'Request quote';

    final amount = basePrice!.toStringAsFixed(basePrice! % 1 == 0 ? 0 : 2);

    final suffix = switch (pricingModel) {
      'hourly' => '/ hour',
      'daily' => '/ day',
      'per_person' => '/ person',
      'per_km' => '/ km',
      'per_job' => '/ job',
      _ =>
        unitLabel == null || unitLabel!.trim().isEmpty
            ? ''
            : '/ ${unitLabel!.trim()}',
    };

    return '$currency $amount${suffix.isEmpty ? '' : ' $suffix'}';
  }
}
