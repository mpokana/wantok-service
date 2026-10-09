import 'package:flutter/material.dart';

/// Shared layout preference for photo/icon grids within one client session.
class AdaptiveGridDensityScope extends InheritedNotifier<ValueNotifier<int?>> {
  const AdaptiveGridDensityScope({
    required ValueNotifier<int?> density,
    required super.child,
    super.key,
  }) : super(notifier: density);

  static ValueNotifier<int?>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AdaptiveGridDensityScope>()
      ?.notifier;
}

/// Two/three-column photo and icon catalogue grid.
///
/// A two-finger spread enlarges cards (two columns); a pinch makes cards
/// smaller (three columns). Single-finger scrolling and taps remain native
/// because pointer listening does NOT compete with Scrollable recognisers.
/// Layout also reacts to usable width and accessibility text scaling.
class AdaptiveCategoryGrid extends StatefulWidget {
  const AdaptiveCategoryGrid({
    required this.itemCount,
    required this.itemBuilder,
    required this.tileHeight,
    this.columnSpacing = 10,
    this.rowSpacing = 10,
    this.gridKey,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double tileHeight;
  final double columnSpacing;
  final double rowSpacing;
  final Key? gridKey;

  @override
  State<AdaptiveCategoryGrid> createState() => _AdaptiveCategoryGridState();
}

class _AdaptiveCategoryGridState extends State<AdaptiveCategoryGrid> {
  final Map<int, Offset> _touches = {};
  int? _overrideColumns;
  ValueNotifier<int?>? _sharedDensity;
  double? _pinchStartDistance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sharedDensity = AdaptiveGridDensityScope.maybeOf(context);
  }

  int? get _selectedDensity => _sharedDensity?.value ?? _overrideColumns;

  void _chooseDensity(int columns) {
    final shared = _sharedDensity;
    if (shared != null) {
      shared.value = columns;
    } else {
      setState(() => _overrideColumns = columns);
    }
  }

  double? get _distance {
    if (_touches.length < 2) return null;
    final points = _touches.values.take(2).toList(growable: false);
    return (points.first - points.last).distance;
  }

  void _pointerDown(PointerDownEvent event) {
    _touches[event.pointer] = event.position;
    if (_touches.length == 2) _pinchStartDistance = _distance;
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_touches.containsKey(event.pointer)) return;
    _touches[event.pointer] = event.position;
    final start = _pinchStartDistance;
    final current = _distance;
    if (start == null || current == null || start < 12) return;
    // Use a fresh gesture baseline following a density change to prevent
    // flicker around the threshold while the user holds two fingers down.
    if (current > start * 1.18 && _selectedDensity != 2) {
      _chooseDensity(2);
      _pinchStartDistance = current;
    } else if (current < start * 0.82 && _selectedDensity != 3) {
      _chooseDensity(3);
      _pinchStartDistance = current;
    }
  }

  void _pointerUp(PointerEvent event) {
    _touches.remove(event.pointer);
    if (_touches.length < 2) _pinchStartDistance = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScaler = MediaQuery.textScalerOf(context);
      final expandedText = textScaler.scale(14) > 17;
      final suggested = constraints.maxWidth >= 420 && !expandedText ? 3 : 2;
      final columns = _selectedDensity ?? suggested;
      return Listener(
        key: const ValueKey('adaptive-category-gesture-surface'),
        behavior: HitTestBehavior.translucent,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerUp,
        onPointerCancel: _pointerUp,
        child: GridView.builder(
          key: widget.gridKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: widget.tileHeight + (expandedText ? 18 : 0),
            crossAxisSpacing: widget.columnSpacing,
            mainAxisSpacing: widget.rowSpacing,
          ),
          itemBuilder: widget.itemBuilder,
        ),
      );
    },
  );
}
