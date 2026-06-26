import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

class FeedMatterBottomPill extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? shadowColor;

  const FeedMatterBottomPill({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final bg = backgroundColor ?? Colors.white;
    final fg = foregroundColor ?? theme.textPrimary;
    final enabled = onPressed != null;

    return Material(
      elevation: 4,
      shadowColor: shadowColor ?? Colors.black26,
      borderRadius: BorderRadius.circular(theme.fabRadius),
      color: enabled ? bg : bg.withAlpha(180),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.fabRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
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

/// Bottom floating submit button.
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

    return FeedMatterBottomPill(
      onPressed: onPressed,
      label: label,
      icon: Icons.add,
      backgroundColor: onPressed == null
          ? theme.primaryBlue.withAlpha(128)
          : theme.primaryBlue,
      foregroundColor: Colors.white,
      shadowColor: theme.primaryBlue.withAlpha(80),
    );
  }
}

/// Wraps [child] with optional left/right bottom floating actions.
class FeedMatterBottomActionOverlay extends StatelessWidget {
  final Widget child;
  final Widget? leftAction;
  final Widget? rightAction;

  const FeedMatterBottomActionOverlay({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
  });

  static const actionClearance = 88.0;

  @override
  Widget build(BuildContext context) {
    final hasActions = leftAction != null || rightAction != null;
    if (!hasActions) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (leftAction != null) leftAction!,
                const Spacer(),
                if (rightAction != null) rightAction!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@Deprecated('Use FeedMatterBottomActionOverlay with rightAction instead')
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

  static const fabClearance = FeedMatterBottomActionOverlay.actionClearance;

  @override
  Widget build(BuildContext context) {
    return FeedMatterBottomActionOverlay(
      rightAction: visible
          ? FeedMatterSubmitFab(onPressed: onPressed, label: label)
          : null,
      child: child,
    );
  }
}
