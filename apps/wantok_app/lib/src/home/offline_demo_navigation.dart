import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'reference_services_gallery.dart';
import 'smoke_data.dart';

/// Only called from screens explicitly instantiated for the offline visual
/// review. No APIs, payment, sign-in, booking or vendor mutations are possible.
abstract final class OfflineDemoNavigation {
  static void category(BuildContext context, String slug) {
    final scene = switch (slug) {
      'food' || 'groceries' => ReferenceScene.foodListing,
      'taxi-ride' || 'vehicle-hire' || 'delivery' => ReferenceScene.taxi,
      'boat-ship-rides' ||
      'travel-flights' ||
      'accommodation' => ReferenceScene.travel,
      'events' || 'venue-booking' => ReferenceScene.bookings,
      _ => ReferenceScene.services,
    };
    final item = ReferenceScreenGallery.items.firstWhere(
      (value) => value.scene == scene,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReferenceSampleScenePage(item: item),
      ),
    );
  }

  static void account(BuildContext context) {
    final item = ReferenceScreenGallery.items.firstWhere(
      (value) => value.scene == ReferenceScene.account,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReferenceSampleScenePage(item: item),
      ),
    );
  }

  static void providers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Provider discovery · Demo')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
            children: const [
              _DemoDisclaimer(),
              SizedBox(height: 12),
              Text(
                'Discover local providers',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
              ),
              SizedBox(height: 8),
              Text(
                'Illustrative provider cards and photographs only. '
                'No providers here are verified or accepting bookings.',
                style: TextStyle(color: WantokColors.muted),
              ),
              SizedBox(height: 12),
              SmokePreviewSection(
                scene: SmokeScene.providers,
                heading: 'Example provider listings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void notice(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(22),
              children: [
                _DemoDisclaimer(),
                SizedBox(height: 20),
                Icon(Icons.lock_outline, color: WantokColors.primary, size: 44),
                SizedBox(height: 10),
                Text(
                  'This is an interactive design preview, not a live service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
                SizedBox(height: 8),
                Text(
                  'Live search, bookings, account records, provider approvals, '
                  'products, advertisements and money movement require an '
                  'authorised staging backend and are disabled here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WantokColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoDisclaimer extends StatelessWidget {
  const _DemoDisclaimer();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3D7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        SmokeMarker(),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'DEMONSTRATION DATA ONLY · No actual providers, accounts, '
            'bookings, payments or approval',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}
