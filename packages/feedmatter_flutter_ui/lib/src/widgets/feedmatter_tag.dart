import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

enum FeedMatterTagVariant { admin, pinned, notice, type, platform }

class FeedMatterTagData {
  final String label;
  final FeedMatterTagVariant variant;

  const FeedMatterTagData({
    required this.label,
    required this.variant,
  });
}

class FeedMatterTag extends StatelessWidget {
  final String label;
  final FeedMatterTagVariant variant;

  const FeedMatterTag({
    super.key,
    required this.label,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final colors = _colorsForVariant(theme, variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(theme.tagRadius),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }

  _TagColors _colorsForVariant(FeedMatterUiTheme theme, FeedMatterTagVariant v) {
    switch (v) {
      case FeedMatterTagVariant.admin:
      case FeedMatterTagVariant.pinned:
      case FeedMatterTagVariant.notice:
        return _TagColors(
          background: theme.primaryBlue.withAlpha(20),
          border: theme.primaryBlue.withAlpha(80),
          foreground: theme.primaryBlue,
        );
      case FeedMatterTagVariant.type:
        return _TagColors(
          background: theme.tagTypeTeal.withAlpha(20),
          border: theme.tagTypeTeal.withAlpha(80),
          foreground: theme.tagTypeTeal,
        );
      case FeedMatterTagVariant.platform:
        return _TagColors(
          background: Colors.transparent,
          border: theme.tagPlatformGreen,
          foreground: theme.tagPlatformGreen,
        );
    }
  }
}

class _TagColors {
  final Color background;
  final Color border;
  final Color foreground;

  const _TagColors({
    required this.background,
    required this.border,
    required this.foreground,
  });
}

class FeedMatterTagRow extends StatelessWidget {
  final List<FeedMatterTagData> tags;
  final double spacing;

  const FeedMatterTagRow({
    super.key,
    required this.tags,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final tag in tags)
          FeedMatterTag(label: tag.label, variant: tag.variant),
      ],
    );
  }
}
