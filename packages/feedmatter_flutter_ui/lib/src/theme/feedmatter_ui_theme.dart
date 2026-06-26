import 'package:flutter/material.dart';

/// Official FeedMatter UI design tokens.
class FeedMatterUiTheme extends ThemeExtension<FeedMatterUiTheme> {
  final Color pageBackground;
  final Color surfaceColor;
  final Color primaryBlue;
  final Color textPrimary;
  final Color textSecondary;
  final Color tagAdminBlue;
  final Color tagTypeTeal;
  final Color tagPlatformGreen;
  final Color inputBackground;
  final Color dividerColor;
  final Color sendButtonBackground;
  final Color sendButtonDisabledBackground;
  final double cardRadius;
  final double searchRadius;
  final double fabRadius;
  final double tagRadius;

  static const Color _defaultPrimaryBlue = Color(0xFF3B82F6);

  const FeedMatterUiTheme({
    this.pageBackground = const Color(0xFFF5F5F5),
    this.surfaceColor = Colors.white,
    this.primaryBlue = _defaultPrimaryBlue,
    this.textPrimary = const Color(0xFF333333),
    this.textSecondary = const Color(0xFF999999),
    this.tagAdminBlue = const Color(0xFF576B95),
    this.tagTypeTeal = const Color(0xFF13A8A8),
    this.tagPlatformGreen = const Color(0xFF52C41A),
    this.inputBackground = const Color(0xFFF2F3F5),
    this.dividerColor = const Color(0xFFEEEEEE),
    this.sendButtonBackground = const Color(0xFFBBBBBB),
    this.sendButtonDisabledBackground = const Color(0xFFDDDDDD),
    this.cardRadius = 12,
    this.searchRadius = 24,
    this.fabRadius = 28,
    this.tagRadius = 4,
  });

  factory FeedMatterUiTheme.forBrightness(
    Brightness brightness, {
    Color? seedColor,
  }) {
    final primary = seedColor ?? _defaultPrimaryBlue;
    if (brightness == Brightness.dark) {
      return FeedMatterUiTheme(
        pageBackground: const Color(0xFF121212),
        surfaceColor: const Color(0xFF1E1E1E),
        primaryBlue: primary,
        textPrimary: const Color(0xFFE5E5E5),
        textSecondary: const Color(0xFF999999),
        tagAdminBlue: const Color(0xFF8FA3C7),
        tagTypeTeal: const Color(0xFF13A8A8),
        tagPlatformGreen: const Color(0xFF52C41A),
        inputBackground: const Color(0xFF2C2C2C),
        dividerColor: const Color(0xFF333333),
        sendButtonBackground: const Color(0xFF666666),
        sendButtonDisabledBackground: const Color(0xFF444444),
      );
    }
    return FeedMatterUiTheme(primaryBlue: primary);
  }

  static FeedMatterUiTheme of(BuildContext context) {
    return Theme.of(context).extension<FeedMatterUiTheme>() ??
        const FeedMatterUiTheme();
  }

  @override
  FeedMatterUiTheme copyWith({
    Color? pageBackground,
    Color? surfaceColor,
    Color? primaryBlue,
    Color? textPrimary,
    Color? textSecondary,
    Color? tagAdminBlue,
    Color? tagTypeTeal,
    Color? tagPlatformGreen,
    Color? inputBackground,
    Color? dividerColor,
    Color? sendButtonBackground,
    Color? sendButtonDisabledBackground,
    double? cardRadius,
    double? searchRadius,
    double? fabRadius,
    double? tagRadius,
  }) {
    return FeedMatterUiTheme(
      pageBackground: pageBackground ?? this.pageBackground,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      tagAdminBlue: tagAdminBlue ?? this.tagAdminBlue,
      tagTypeTeal: tagTypeTeal ?? this.tagTypeTeal,
      tagPlatformGreen: tagPlatformGreen ?? this.tagPlatformGreen,
      inputBackground: inputBackground ?? this.inputBackground,
      dividerColor: dividerColor ?? this.dividerColor,
      sendButtonBackground: sendButtonBackground ?? this.sendButtonBackground,
      sendButtonDisabledBackground:
          sendButtonDisabledBackground ?? this.sendButtonDisabledBackground,
      cardRadius: cardRadius ?? this.cardRadius,
      searchRadius: searchRadius ?? this.searchRadius,
      fabRadius: fabRadius ?? this.fabRadius,
      tagRadius: tagRadius ?? this.tagRadius,
    );
  }

  @override
  FeedMatterUiTheme lerp(ThemeExtension<FeedMatterUiTheme>? other, double t) {
    if (other is! FeedMatterUiTheme) return this;
    return FeedMatterUiTheme(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      tagAdminBlue: Color.lerp(tagAdminBlue, other.tagAdminBlue, t)!,
      tagTypeTeal: Color.lerp(tagTypeTeal, other.tagTypeTeal, t)!,
      tagPlatformGreen:
          Color.lerp(tagPlatformGreen, other.tagPlatformGreen, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      sendButtonBackground:
          Color.lerp(sendButtonBackground, other.sendButtonBackground, t)!,
      sendButtonDisabledBackground: Color.lerp(
        sendButtonDisabledBackground,
        other.sendButtonDisabledBackground,
        t,
      )!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      searchRadius: searchRadius + (other.searchRadius - searchRadius) * t,
      fabRadius: fabRadius + (other.fabRadius - fabRadius) * t,
      tagRadius: tagRadius + (other.tagRadius - tagRadius) * t,
    );
  }
}

/// Builds a [ThemeData] with official FeedMatter tokens pre-applied.
ThemeData buildFeedMatterTheme({
  Brightness brightness = Brightness.light,
  Color? seedColor,
  ThemeData? base,
}) {
  final tokens = FeedMatterUiTheme.forBrightness(brightness, seedColor: seedColor);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.primaryBlue,
    brightness: brightness,
  ).copyWith(
    surface: tokens.surfaceColor,
    onSurface: tokens.textPrimary,
  );
  final theme = base ??
      ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: tokens.pageBackground,
      );
  return theme.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.pageBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.surfaceColor,
      foregroundColor: tokens.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: tokens.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}

/// Builds a light [ThemeData] with FeedMatter tokens.
ThemeData buildFeedMatterLightTheme({Color? seedColor, ThemeData? base}) {
  return buildFeedMatterTheme(
    brightness: Brightness.light,
    seedColor: seedColor,
    base: base,
  );
}

/// Builds a dark [ThemeData] with FeedMatter tokens.
ThemeData buildFeedMatterDarkTheme({Color? seedColor, ThemeData? base}) {
  return buildFeedMatterTheme(
    brightness: Brightness.dark,
    seedColor: seedColor,
    base: base,
  );
}
