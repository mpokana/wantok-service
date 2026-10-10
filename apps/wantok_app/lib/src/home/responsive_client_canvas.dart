import 'package:flutter/material.dart';

/// Keeps the signed-in Client pages aligned on widescreen browsers without
/// affecting narrow phones or tablet layouts. This is presentation-only:
/// authentication, routes, records and business state remain in each page.
class ResponsiveClientCanvas extends StatelessWidget {
  const ResponsiveClientCanvas({
    required this.child,
    this.maxWidth = 1480,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      if (viewport.maxWidth < 700) return child;
      final width = viewport.maxWidth < maxWidth ? viewport.maxWidth : maxWidth;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          key: const ValueKey('client-responsive-canvas'),
          width: width,
          height: viewport.maxHeight,
          child: child,
        ),
      );
    },
  );
}
