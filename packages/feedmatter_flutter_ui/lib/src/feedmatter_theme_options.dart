import 'package:flutter/material.dart';

/// FeedMatter UI theme mode.
enum FeedMatterThemeMode {
  /// Always use light theme.
  light,

  /// Always use dark theme.
  dark,

  /// Follow system platform brightness.
  system,
}

/// Theme options for FeedMatter UI.
class FeedMatterThemeOptions {
  const FeedMatterThemeOptions({
    this.mode = FeedMatterThemeMode.system,
    this.seedColor,
  });

  /// Theme mode: light, dark, or follow system.
  final FeedMatterThemeMode mode;

  /// Seed color for generating the color scheme.
  /// When null, inherits [ColorScheme.primary] from the host theme.
  final Color? seedColor;
}
