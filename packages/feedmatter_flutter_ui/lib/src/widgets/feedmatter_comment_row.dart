import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import 'attachment_list.dart';
import 'feedmatter_link_text.dart';
import 'feedmatter_tag.dart';

class FeedMatterCommentRow extends StatelessWidget {
  final fm.Author author;
  final String content;
  final DateTime createdAt;
  final bool pinned;
  final fm.CommentMark? mark;
  final String? parentUserName;
  final List<fm.Attachment>? attachments;
  final VoidCallback? onTap;
  final FeedMatterUiOptions options;
  final bool showDivider;

  const FeedMatterCommentRow({
    super.key,
    required this.author,
    required this.content,
    required this.createdAt,
    this.pinned = false,
    this.mark,
    this.parentUserName,
    this.attachments,
    this.onTap,
    this.options = const FeedMatterUiOptions(),
    this.showDivider = true,
  });

  factory FeedMatterCommentRow.fromComment(
    fm.Comment comment, {
    VoidCallback? onTap,
    FeedMatterUiOptions options = const FeedMatterUiOptions(),
    bool showDivider = true,
  }) {
    return FeedMatterCommentRow(
      author: comment.author,
      content: comment.content,
      createdAt: comment.createdAt,
      pinned: comment.pinned,
      mark: comment.mark,
      parentUserName: comment.parentUserName,
      attachments: comment.attachments,
      onTap: onTap,
      options: options,
      showDivider: showDivider,
    );
  }

  factory FeedMatterCommentRow.fromMainComment(
    fm.MainCommentWithReplies comment, {
    VoidCallback? onTap,
    FeedMatterUiOptions options = const FeedMatterUiOptions(),
    bool showDivider = true,
  }) {
    return FeedMatterCommentRow(
      author: comment.author,
      content: comment.content,
      createdAt: comment.createdAt,
      pinned: comment.pinned,
      mark: comment.mark,
      attachments: comment.attachments,
      onTap: onTap,
      options: options,
      showDivider: showDivider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final isAdmin = isCommentAdmin(mark);
    final isReply =
        parentUserName != null && parentUserName!.trim().isNotEmpty;
    const avatarRadius = 16.0;
    const contentIndent = avatarRadius * 2 + 10;

    return Column(
      children: [
        Material(
          color: theme.surfaceColor,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        child: isReply
                            ? _ReplyHeader(
                                author: author,
                                parentUserName: parentUserName!,
                                isAdmin: isAdmin,
                                createdAt: createdAt,
                              )
                            : _MainHeader(
                                author: author,
                                isAdmin: isAdmin,
                                pinned: pinned,
                                createdAt: createdAt,
                              ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: contentIndent, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FeedMatterLinkText(
                          text: content,
                          onUrlTap: options.onContentUrlTap,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (attachments != null && attachments!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          FeedMatterAttachmentList(
                            attachments: attachments!,
                            showTitle: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
      ],
    );
  }
}

class _MainHeader extends StatelessWidget {
  final fm.Author author;
  final bool isAdmin;
  final bool pinned;
  final DateTime createdAt;

  const _MainHeader({
    required this.author,
    required this.isAdmin,
    required this.pinned,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                authorName(author),
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isAdmin) const _AdminBadge(),
              if (pinned)
                const FeedMatterTag(
                  label: '置顶',
                  variant: FeedMatterTagVariant.pinned,
                ),
            ],
          ),
        ),
        Text(
          formatAbsoluteTime(createdAt),
          style: TextStyle(color: theme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _ReplyHeader extends StatelessWidget {
  final fm.Author author;
  final String parentUserName;
  final bool isAdmin;
  final DateTime createdAt;

  const _ReplyHeader({
    required this.author,
    required this.parentUserName,
    required this.isAdmin,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
              children: [
                TextSpan(
                  text: authorName(author),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (isAdmin) ...[
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: _AdminBadge(),
                    ),
                  ),
                ],
                const TextSpan(text: ' 回复: '),
                TextSpan(
                  text: '@$parentUserName',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.tagAdminBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          formatAbsoluteTime(createdAt),
          style: TextStyle(color: theme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.tagAdminBlue.withAlpha(180)),
      ),
      child: Text(
        '管理员',
        style: TextStyle(
          color: theme.tagAdminBlue,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
