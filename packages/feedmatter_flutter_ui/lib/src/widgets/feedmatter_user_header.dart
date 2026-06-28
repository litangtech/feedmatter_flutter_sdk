import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../theme/feedmatter_ui_theme.dart';

class FeedMatterUserHeader extends StatelessWidget {
  final fm.Author author;
  final DateTime createdAt;
  final bool useAbsoluteTime;
  final double avatarRadius;

  const FeedMatterUserHeader({
    super.key,
    required this.author,
    required this.createdAt,
    this.useAbsoluteTime = false,
    this.avatarRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final timeText =
        useAbsoluteTime ? formatAbsoluteTime(createdAt) : formatDisplayTime(createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: author.avatar == null
              ? null
              : NetworkImage(author.avatar!),
          child: author.avatar == null
              ? Icon(Icons.person, size: avatarRadius)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName(author),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeText,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
