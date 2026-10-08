import 'package:flutter/material.dart';

/// Decorative imagery only. Text and actions stay in ordinary Flutter widgets.
class WantokPhotoHero extends StatelessWidget {
  const WantokPhotoHero({
    super.key,
    required this.image,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.minHeight = 0,
  });

  final String image;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xF208241C),
              Color(0xD108241C),
              Color(0x9A08241C),
              Color(0x2208241C),
            ],
            stops: [0, 0.4, 0.74, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}
