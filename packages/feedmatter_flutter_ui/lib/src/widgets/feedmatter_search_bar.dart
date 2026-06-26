import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

class FeedMatterSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const FeedMatterSearchBar({
    super.key,
    required this.controller,
    this.hintText = '搜索反馈',
    this.onSubmitted,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: theme.textSecondary, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(Icons.clear, color: theme.textSecondary, size: 18),
              ),
        filled: true,
        fillColor: theme.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.searchRadius),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.searchRadius),
          borderSide: BorderSide(color: theme.primaryBlue.withAlpha(128)),
        ),
      ),
    );
  }
}
