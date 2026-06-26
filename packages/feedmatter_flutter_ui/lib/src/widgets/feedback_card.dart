import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';

class FeedMatterFeedbackCard extends StatelessWidget {
  final fm.Feedback feedback;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const FeedMatterFeedbackCard({
    super.key,
    required this.feedback,
    this.onTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = feedbackStatusColor(feedback.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(
                    label: feedbackTypeLabel(feedback.type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: feedbackStatusLabel(feedback.status),
                    color: statusColor,
                  ),
                  const Spacer(),
                  Text(
                    formatRelativeTime(feedback.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                feedback.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: feedback.author.avatar == null
                        ? null
                        : NetworkImage(feedback.author.avatar!),
                    child: feedback.author.avatar == null
                        ? const Icon(Icons.person, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authorName(feedback.author),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onLike,
                    icon: Icon(
                      feedback.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border_outlined,
                      color: feedback.isLiked ? Colors.red : null,
                    ),
                  ),
                  Text('${feedback.likeCount}'),
                  const SizedBox(width: 12),
                  const Icon(Icons.mode_comment_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text('${feedback.commentCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
