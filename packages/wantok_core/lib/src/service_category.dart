class WantokServiceCategory {
  const WantokServiceCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.vertical,
    required this.bookingMode,
    this.description,
    this.iconKey,
    this.isActive = true,
    this.sortOrder = 0,
    this.showOnHome = true,
    this.showInServices = true,
    this.imagePath,
  });

  final String id;
  final String slug;
  final String name;
  final String vertical;
  final String bookingMode;
  final String? description;
  final String? iconKey;
  final bool isActive;
  final int sortOrder;
  final bool showOnHome;
  final bool showInServices;
  final String? imagePath;

  factory WantokServiceCategory.fromMap(Map<String, dynamic> map) {
    return WantokServiceCategory(
      id: map['id'] as String,
      slug: map['slug'] as String,
      name: map['name'] as String,
      vertical: map['vertical'] as String,
      bookingMode: map['booking_mode'] as String,
      description: map['description'] as String?,
      iconKey: map['icon_key'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 0,
      showOnHome: map['show_on_home'] as bool? ?? true,
      showInServices: map['show_in_services'] as bool? ?? true,
      imagePath: map['image_path'] as String?,
    );
  }
}
