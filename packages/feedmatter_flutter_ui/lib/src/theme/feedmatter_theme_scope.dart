import 'package:flutter/material.dart';

import '../feedmatter_theme_options.dart';
import 'feedmatter_ui_theme.dart';

/// Resolves [FeedMatterThemeOptions] and applies FeedMatter theme to [child].
class FeedMatterThemeScope extends StatelessWidget {
  const FeedMatterThemeScope({
    super.key,
    required this.options,
    required this.child,
  });

  final FeedMatterThemeOptions options;
  final Widget child;

  static Brightness resolveBrightness(
    BuildContext context,
    FeedMatterThemeMode mode,
  ) {
    switch (mode) {
      case FeedMatterThemeMode.light:
        return Brightness.light;
      case FeedMatterThemeMode.dark:
        return Brightness.dark;
      case FeedMatterThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }

  static Color resolveSeedColor(BuildContext context, Color? seedColor) {
    return seedColor ?? Theme.of(context).colorScheme.primary;
  }

  /// Pushes [child] wrapped in a FeedMatter theme scope.
  ///
  /// Required because routes pushed onto the root [Navigator] sit outside
  /// an ancestor [FeedMatterThemeScope] and would otherwise lose theme tokens.
  static Future<T?> push<T extends Object?>(
    BuildContext context, {
    required FeedMatterThemeOptions theme,
    required Widget child,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => FeedMatterThemeScope(
          options: theme,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = resolveBrightness(context, options.mode);
    final seedColor = resolveSeedColor(context, options.seedColor);
    final themeData = buildFeedMatterTheme(
      brightness: brightness,
      seedColor: seedColor,
    );
    return Theme(data: themeData, child: child);
  }
}
