import 'package:flutter/material.dart';

import 'wantok_colors.dart';

class WantokServiceTile extends StatelessWidget {
  const WantokServiceTile({
    required this.label,
    required this.icon,
    this.onTap,
    this.badge,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F4ED),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: WantokColors.primaryDark, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: WantokColors.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: WantokColors.ink,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WantokColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
