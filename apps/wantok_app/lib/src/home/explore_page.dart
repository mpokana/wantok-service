import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'reference_services_gallery.dart';
import 'smoke_data.dart';

/// PNG exploration entry point. Reference previews are opt-in development
/// fixtures and are NEVER treated as live offers, providers or advertisements.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, this.onBrowseServices});

  final VoidCallback? onBrowseServices;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('wantok-explore-page'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        const Text(
          'Explore',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: WantokColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Discover PNG and beyond — places, local experiences and services.',
          style: TextStyle(fontSize: 13, color: WantokColors.muted),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/hero_water.png',
                  alignment: Alignment.centerRight,
                  fit: BoxFit.cover,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xDB06452D), Color(0x2506452D)],
                    ),
                  ),
                ),
                const Positioned(
                  left: 18,
                  bottom: 18,
                  right: 86,
                  child: Text(
                    'Our communities. Our journeys.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (onBrowseServices != null)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const ValueKey('explore-browse-services'),
              onPressed: onBrowseServices,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Browse services'),
            ),
          ),
        if (WantokSmokeData.enabled) ...[
          const SizedBox(height: 20),
          const ReferenceScreenSamplesSection(),
        ] else ...[
          const SizedBox(height: 24),
          const Text(
            'Explore more of PNG',
            style: TextStyle(
              color: WantokColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New local experiences will appear here as they become available. '
            'Browse current services to find providers in your community.',
            style: TextStyle(color: WantokColors.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
