import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

/// Bottom-center floating submit button overlay.
class FeedMatterSubmitFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const FeedMatterSubmitFab({
    super.key,
    required this.onPressed,
    this.label = '提交反馈',
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);

    return Material(
      elevation: 4,
      shadowColor: theme.primaryBlue.withAlpha(80),
      borderRadius: BorderRadius.circular(theme.fabRadius),
      color: onPressed == null
          ? theme.primaryBlue.withAlpha(128)
          : theme.primaryBlue,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.fabRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] with a bottom-center floating submit button.
class FeedMatterSubmitFabOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool visible;
  final String label;

  const FeedMatterSubmitFabOverlay({
    super.key,
    required this.child,
    required this.onPressed,
    this.visible = true,
    this.label = '提交反馈',
  });

  static const fabClearance = 88.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (visible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: FeedMatterSubmitFab(
                  onPressed: onPressed,
                  label: label,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
