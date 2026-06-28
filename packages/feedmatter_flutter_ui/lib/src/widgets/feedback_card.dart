import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import 'attachment_list.dart';
import 'feedmatter_link_text.dart';
import 'feedmatter_tag.dart';
import 'feedmatter_user_header.dart';

class FeedMatterFeedbackCard extends StatelessWidget {
  final fm.Feedback feedback;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final FeedMatterUiOptions options;

  const FeedMatterFeedbackCard({
    super.key,
    required this.feedback,
    this.onTap,
    this.onLike,
    this.options = const FeedMatterUiOptions(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final tags = feedbackTags(feedback);
    final hasImageAttachment = feedback.attachments?.any(
          (a) => a.fileType == fm.FileType.IMG && a.fileUrl != null,
        ) ??
        false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: theme.surfaceColor,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeedMatterUserHeader(
                  author: feedback.author,
                  createdAt: feedback.createdAt,
                ),
                const SizedBox(height: 12),
                FeedMatterLinkText(
                  text: feedback.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  onUrlTap: options.onContentUrlTap,
                ),
                if (hasImageAttachment) ...[
                  const SizedBox(height: 10),
                  FeedMatterAttachmentList(
                    attachments: feedback.attachments!,
                    showTitle: false,
                    compact: true,
                  ),
                ],
                if (tags.isNotEmpty || onLike != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: FeedMatterTagRow(tags: tags)),
                      if (onLike != null) ...[
                        InkWell(
                          onTap: onLike,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              feedback.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border_outlined,
                              size: 18,
                              color: feedback.isLiked
                                  ? Colors.red
                                  : theme.textSecondary,
                            ),
                          ),
                        ),
                        if (feedback.likeCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            '${feedback.likeCount}',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 18,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${feedback.commentCount}',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
