import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'wantok_category_ui.dart';

/// An honest backend catalogue landing for service verticals that have not
/// launched transactional functionality. Never creates requests or payments.
class CategoryInformationPage extends StatelessWidget {
  const CategoryInformationPage({
    super.key,
    required this.style,
    required this.description,
  });

  final WantokCategoryStyle style;
  final String description;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFD),
    appBar: AppBar(
      title: Text(style.title.replaceAll('\n', ' ')),
      backgroundColor: Colors.white,
      foregroundColor: WantokColors.ink,
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AspectRatio(
          aspectRatio: 1.85,
          child: WantokCategoryPicture(style: style, borderRadius: 22),
        ),
        const SizedBox(height: 18),
        Text(
          style.title.replaceAll('\n', ' '),
          style: const TextStyle(
            fontSize: 25,
            color: WantokColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: WantokColors.muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE4EAF3)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: WantokColors.primary,
                  size: 23,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider listings coming soon',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'This service category is available in the '
                        'Wantok catalogue. Provider verification and online '
                        'requests are not yet active. No booking or payment '
                        'can be made from this page.',
                        style: TextStyle(
                          color: WantokColors.muted,
                          height: 1.45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Browse other services'),
        ),
      ],
    ),
  );
}
