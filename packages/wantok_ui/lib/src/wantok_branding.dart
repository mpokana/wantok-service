import 'package:flutter/material.dart';

import 'wantok_theme.dart';

/// A read-only published appearance snapshot for all responsive surfaces.
class WantokBrandingScope extends InheritedWidget {
  const WantokBrandingScope({
    required this.document,
    required this.resolveMediaUrl,
    required super.child,
    super.key,
  });
  final Map<String, dynamic> document;
  final String Function(String path) resolveMediaUrl;

  static WantokBrandingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WantokBrandingScope>();

  String? mediaUrl(String slug, String slot) {
    final media = document['media'];
    if (media is! Map) return null;
    final record = media[slug];
    if (record is! Map) return null;
    final path = record[slot];
    if (path is! String ||
        !RegExp(
          r'^categories/[a-z0-9-]+/(homeIcon|cardImage|bannerImage)/[a-f0-9-]{36}[.](jpg|png|webp)$',
        ).hasMatch(path))
      return null;
    if (!path.startsWith('categories/$slug/$slot/')) return null;
    return resolveMediaUrl(path);
  }

  @override
  bool updateShouldNotify(WantokBrandingScope oldWidget) =>
      oldWidget.document != document ||
      oldWidget.resolveMediaUrl != resolveMediaUrl;
}

class WantokBrandingTheme {
  static Color parse(String? hex, Color fallback) {
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return fallback;
    }
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  static ThemeMode mode(Map<String, dynamic> document) {
    final settings = document['theme'];
    if (settings is! Map) return ThemeMode.light;
    return switch (settings['mode']) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  static ThemeData from(Map<String, dynamic> document, {bool dark = false}) {
    final settings = document['theme'];
    final theme = settings is Map ? settings : <String, dynamic>{};
    final base = dark
        ? ThemeData.dark(useMaterial3: true)
        : WantokTheme.light();
    final primary = parse(
      theme['primary']?.toString(),
      base.colorScheme.primary,
    );
    final secondary = parse(
      theme['secondary']?.toString(),
      base.colorScheme.secondary,
    );
    final radius =
        (theme['cardRadius'] is num
                ? (theme['cardRadius'] as num).toDouble()
                : 18.0)
            .clamp(8.0, 30.0);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: primary.withValues(alpha: .12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius * .8),
          ),
        ),
      ),
    );
  }
}
