import 'package:flutter/material.dart';

import 'wantok_colors.dart';

class WantokServiceTile extends StatelessWidget {
  const WantokServiceTile({
    required this.label,
    required this.icon,
    this.onTap,
    this.badge,
    this.accentColor,
    this.surfaceColor,
    this.badgeColor,
    this.isSaved = false,
    this.onSavedToggle,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;
  final Color? accentColor;
  final Color? surfaceColor;
  final Color? badgeColor;
  final bool isSaved;
  final VoidCallback? onSavedToggle;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? WantokColors.primaryDark;
    final surface = surfaceColor ?? const Color(0xFFE7F4ED);
    final badgeSurface = badgeColor ?? WantokColors.gold;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(surface, Colors.white, 0.08)!,
                        surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          width: 22,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(icon, color: accent, size: 29),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSavedToggle != null)
                  Positioned(
                    left: -8,
                    top: -8,
                    child: Semantics(
                      button: true,
                      label: isSaved ? 'Remove from saved' : 'Save service',
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onSavedToggle,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 16,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: badgeSurface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: badgeSurface.withValues(alpha: 0.22),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.15,
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
                fontSize: 11.8,
                height: 1.16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
