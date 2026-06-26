import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import 'attachment_list.dart';

class FeedMatterCommentFloorCard extends StatelessWidget {
  final fm.MainCommentWithReplies comment;
  final List<fm.Comment> extraReplies;
  final bool isLoadingMore;
  final VoidCallback? onReply;
  final VoidCallback? onLoadMoreReplies;

  const FeedMatterCommentFloorCard({
    super.key,
    required this.comment,
    this.extraReplies = const [],
    this.isLoadingMore = false,
    this.onReply,
    this.onLoadMoreReplies,
  });

  @override
  Widget build(BuildContext context) {
    final replies = [...comment.replies.content, ...extraReplies];
    final loadedReplyCount = replies.length;
    final hasMoreReplies = loadedReplyCount < comment.replies.totalElements;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentHeader(
              author: comment.author,
              createdAt: comment.createdAt,
              pinned: comment.pinned,
              isOfficial: _isOfficialMark(comment.mark),
            ),
            const SizedBox(height: 8),
            Text(comment.content),
            if (comment.attachments != null &&
                comment.attachments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              FeedMatterAttachmentList(
                attachments: comment.attachments!,
                showTitle: false,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('回复'),
              ),
            ),
            if (replies.isNotEmpty) ...[
              const Divider(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final reply in replies)
                        _ReplyItem(reply: reply, onReply: onReply),
                      if (hasMoreReplies)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isLoadingMore ? null : onLoadMoreReplies,
                            child: Text(
                              isLoadingMore
                                  ? '加载中...'
                                  : '加载更多回复（$loadedReplyCount/${comment.replies.totalElements}）',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentHeader extends StatelessWidget {
  final fm.Author author;
  final DateTime createdAt;
  final bool pinned;
  final bool isOfficial;

  const _CommentHeader({
    required this.author,
    required this.createdAt,
    required this.pinned,
    this.isOfficial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: author.avatar == null
              ? null
              : NetworkImage(author.avatar!),
          child: author.avatar == null
              ? const Icon(Icons.person, size: 16)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            authorName(author),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (isOfficial) const _OfficialBadge(),
        if (pinned)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(31),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '置顶',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        Text(
          formatRelativeTime(createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ReplyItem extends StatelessWidget {
  final fm.Comment reply;
  final VoidCallback? onReply;

  const _ReplyItem({required this.reply, this.onReply});

  @override
  Widget build(BuildContext context) {
    final parentName = reply.parentUserName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: authorName(reply.author),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (_isOfficialMark(reply.mark)) ...[
                        const TextSpan(text: ' '),
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _OfficialBadge(compact: true),
                        ),
                      ],
                      if (parentName != null && parentName.isNotEmpty) ...[
                        const TextSpan(text: ' 回复 '),
                        TextSpan(
                          text: parentName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Text(
                formatRelativeTime(reply.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reply.content),
          if (reply.attachments != null && reply.attachments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            FeedMatterAttachmentList(
              attachments: reply.attachments!,
              showTitle: false,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onReply, child: const Text('回复')),
          ),
        ],
      ),
    );
  }
}

bool _isOfficialMark(fm.CommentMark? mark) {
  if (mark == null) return false;
  return mark.isAdmin || mark.isAdminReply;
}

class _OfficialBadge extends StatelessWidget {
  final bool compact;

  const _OfficialBadge({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: compact ? 0 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(31),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '官方',
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
