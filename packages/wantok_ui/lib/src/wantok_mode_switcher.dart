import 'package:flutter/material.dart';
import 'package:wantok_core/wantok_core.dart';

class WantokModeSwitcher extends StatelessWidget {
  const WantokModeSwitcher({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AppMode value;
  final ValueChanged<AppMode> onChanged;

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
    );
  }
}
