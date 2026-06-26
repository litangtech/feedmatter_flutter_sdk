import 'package:flutter/material.dart';

/// Official FeedMatter UI design tokens.
class FeedMatterUiTheme extends ThemeExtension<FeedMatterUiTheme> {
  final Color pageBackground;
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

  const FeedMatterUiTheme({
    this.pageBackground = const Color(0xFFF5F5F5),
    this.primaryBlue = const Color(0xFF3B82F6),
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

  static FeedMatterUiTheme of(BuildContext context) {
    return Theme.of(context).extension<FeedMatterUiTheme>() ??
        const FeedMatterUiTheme();
  }

  @override
  FeedMatterUiTheme copyWith({
    Color? pageBackground,
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
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      tagAdminBlue: Color.lerp(tagAdminBlue, other.tagAdminBlue, t)!,
      tagTypeTeal: Color.lerp(tagTypeTeal, other.tagTypeTeal, t)!,
      tagPlatformGreen: Color.lerp(tagPlatformGreen, other.tagPlatformGreen, t)!,
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
ThemeData buildFeedMatterTheme({ThemeData? base}) {
  const tokens = FeedMatterUiTheme();
  final theme = base ??
      ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: tokens.primaryBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: tokens.pageBackground,
      );
  return theme.copyWith(
    scaffoldBackgroundColor: tokens.pageBackground,
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
