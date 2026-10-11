import 'package:flutter/material.dart';

/// Canonical read-only category photographs shared by Client, Technical, Web and Android.
/// These are original existing curated Wantok category assets, not generic placeholder icons.
abstract final class WantokCategoryMedia {
  static const assets = <String, String>{
    'accommodation':
        'packages/wantok_ui/assets/images/categories/category_hotels.webp',
    'beauty-wellness':
        'packages/wantok_ui/assets/images/categories/category_beauty.webp',
    'boat-hire':
        'packages/wantok_ui/assets/images/categories/category_boat_hire.webp',
    'boat-ship-rides': 'packages/wantok_ui/assets/images/categories/category_water_transport.webp',
    'bus-coach':
        'packages/wantok_ui/assets/images/categories/category_bus_coach.webp',
    'delivery':
        'packages/wantok_ui/assets/images/categories/category_delivery.webp',
    'education-training':
        'packages/wantok_ui/assets/images/categories/category_education.webp',
    'errands':
        'packages/wantok_ui/assets/images/categories/category_errands.webp',
    'events':
        'packages/wantok_ui/assets/images/categories/category_events.webp',
    'financial-services':
        'packages/wantok_ui/assets/images/categories/category_financial.webp',
    'flights':
        'packages/wantok_ui/assets/images/categories/category_flights.webp',
    'food': 'packages/wantok_ui/assets/images/categories/category_food.webp',
    'general-labour':
        'packages/wantok_ui/assets/images/categories/category_labour.webp',
    'groceries':
        'packages/wantok_ui/assets/images/categories/category_groceries.webp',
    'health-medical':
        'packages/wantok_ui/assets/images/categories/category_health.webp',
    'home-services': 'packages/wantok_ui/assets/images/categories/category_home_services.webp',
    'more': 'packages/wantok_ui/assets/images/categories/category_more.webp',
    'public-services':
        'packages/wantok_ui/assets/images/reference/services_public_photo.jpg',
    'shopping-retail':
        'packages/wantok_ui/assets/images/categories/category_shopping.webp',
    'specialist-services': 'packages/wantok_ui/assets/images/categories/category_professional.webp',
    'taxi-ride':
        'packages/wantok_ui/assets/images/categories/category_taxi.webp',
    'travel-flights':
        'packages/wantok_ui/assets/images/categories/category_travel.webp',
    'vehicle-hire':
        'packages/wantok_ui/assets/images/categories/category_automotive.webp',
    'venue-booking':
        'packages/wantok_ui/assets/images/categories/category_venue.webp',
  };

  static String? assetForSlug(String slug) => assets[slug];

  static Widget picture(
    String slug, {
    String? uploadedUrl,
    BoxFit fit = BoxFit.cover,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(14)),
  }) {
    final asset = assetForSlug(slug);
    final fallback = asset == null
        ? const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFE5F1EC)),
            child: Center(
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFF37685A),
              ),
            ),
          )
        : Image.asset(
            asset,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
          );
    return ClipRRect(
      borderRadius: borderRadius,
      child: uploadedUrl == null
          ? fallback
          : Image.network(
              uploadedUrl,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
