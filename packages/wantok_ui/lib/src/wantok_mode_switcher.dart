import 'package:flutter/material.dart';
import 'package:wantok_core/wantok_core.dart';

import 'wantok_colors.dart';

class WantokModeSwitcher extends StatelessWidget {
  const WantokModeSwitcher({
    required this.value,
    required this.onChanged,
    this.inverted = false,
    super.key,
  });

  final AppMode value;
  final ValueChanged<AppMode> onChanged;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppMode>(
      segments: const [
        ButtonSegment(
          value: AppMode.client,
          label: Text('Client'),
          icon: Icon(Icons.person_outline),
        ),
        ButtonSegment(
          value: AppMode.vendor,
          label: Text('Vendor'),
          icon: Icon(Icons.storefront_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return WantokColors.primaryDark;
          }
          return inverted ? Colors.white : WantokColors.ink;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE2F3E9);
          }
          return inverted
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(
            color: inverted
                ? Colors.white.withValues(alpha: 0.42)
                : const Color(0xFFBFCAC4),
          ),
        ),
      ),
    );
  }
}
