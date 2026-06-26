import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../widgets/comment_floor_card.dart';

class FeedMatterDetailPage extends StatefulWidget {
  final String feedbackId;
  final fm.ProjectConfig config;
  final FeedMatterUiOptions options;

  const FeedMatterDetailPage({
    super.key,
    required this.feedbackId,
    required this.config,
    this.options = const FeedMatterUiOptions(),
  });

  @override
  State<FeedMatterDetailPage> createState() => _FeedMatterDetailPageState();
}

class _FeedMatterDetailPageState extends State<FeedMatterDetailPage> {
  final _commentController = TextEditingController();
  fm.Feedback? _feedback;
  fm.Page<fm.MainCommentWithReplies>? _commentPage;
  bool _loading = true;
  bool _sending = false;
  String? _replyToCommentId;
  String? _replyToName;
  final Map<String, List<fm.Comment>> _extraRepliesByComment = {};
  final Map<String, int> _replyPageByComment = {};
  final Set<String> _loadingReplyCommentIds = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        fm.FeedMatterClient.instance.getFeedback(widget.feedbackId),
        fm.FeedMatterClient.instance.getCommentsFloor(
          widget.feedbackId,
          size: 20,
          sort: fm.CommentSort.createdAsc,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _feedback = results[0] as fm.Feedback;
        _commentPage = results[1] as fm.Page<fm.MainCommentWithReplies>;
        _extraRepliesByComment.clear();
        _replyPageByComment.clear();
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '详情加载失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendComment() async {
    final feedback = _feedback;
    if (feedback == null) return;
    if (!widget.config.commentEnabled || !feedback.allowComment) {
      showFeedMatterSnackBar(context, '当前反馈不允许评论', isError: true);
      return;
    }
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      showFeedMatterSnackBar(context, '请输入评论内容', isError: true);
      return;
    }
    if (content.length > widget.config.commentMaxContentLength) {
      showFeedMatterSnackBar(
        context,
        '评论内容不能超过 ${widget.config.commentMaxContentLength} 字',
        isError: true,
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await fm.FeedMatterClient.instance.createComment(
        feedback.id,
        content,
        parentCommentId: _replyToCommentId,
      );
      _commentController.clear();
      _clearReplyTarget();
      await _loadDetail();
      if (mounted) {
        showFeedMatterSnackBar(context, '评论已发布');
      }
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '评论发布失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _loadMoreReplies(fm.MainCommentWithReplies comment) async {
    if (_loadingReplyCommentIds.contains(comment.id)) return;
    setState(() => _loadingReplyCommentIds.add(comment.id));
    try {
      final nextPage =
          (_replyPageByComment[comment.id] ?? comment.replies.currentPage) + 1;
      final result = await fm.FeedMatterClient.instance.getCommentReplies(
        comment.id,
        page: nextPage,
        size: 10,
      );
      if (!mounted) return;
      setState(() {
        _replyPageByComment[comment.id] = result.currentPage;
        _extraRepliesByComment.update(
          comment.id,
          (items) => [...items, ...result.content],
          ifAbsent: () => result.content,
        );
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '回复加载失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingReplyCommentIds.remove(comment.id));
      }
    }
  }

  void _setReplyTarget(String commentId, String authorDisplayName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToName = authorDisplayName;
    });
  }

  void _clearReplyTarget() {
    setState(() {
      _replyToCommentId = null;
      _replyToName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈详情'),
        actions: [
          IconButton(onPressed: _loadDetail, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : feedback == null
          ? const Center(child: Text('反馈不存在'))
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadDetail,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _FeedbackDetailCard(feedback: feedback),
                        _CommentHeader(config: widget.config),
                        ..._buildCommentCards(),
                      ],
                    ),
                  ),
                ),
                _CommentInputBar(
                  controller: _commentController,
                  enabled:
                      widget.config.commentEnabled && feedback.allowComment,
                  sending: _sending,
                  replyToName: _replyToName,
                  maxLength: widget.config.commentMaxContentLength,
                  hintText: widget.config.commentPrompt,
                  onCancelReply: _clearReplyTarget,
                  onSend: _sendComment,
                ),
              ],
            ),
    );
  }

  List<Widget> _buildCommentCards() {
    final comments = _commentPage?.content ?? [];
    if (comments.isEmpty) {
      return const [
        SizedBox(height: 48),
        Center(child: Text('暂无评论，来发布第一条评论吧')),
      ];
    }
    return [
      for (final comment in comments)
        FeedMatterCommentFloorCard(
          comment: comment,
          extraReplies: _extraRepliesByComment[comment.id] ?? const [],
          isLoadingMore: _loadingReplyCommentIds.contains(comment.id),
          onReply: () =>
              _setReplyTarget(comment.id, authorName(comment.author)),
          onLoadMoreReplies: () => _loadMoreReplies(comment),
        ),
    ];
  }
}

class _FeedbackDetailCard extends StatelessWidget {
  final fm.Feedback feedback;

  const _FeedbackDetailCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final statusColor = feedbackStatusColor(feedback.status);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  feedbackTypeLabel(feedback.type),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  feedbackStatusLabel(feedback.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(formatRelativeTime(feedback.createdAt)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              feedback.content,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: feedback.author.avatar == null
                      ? null
                      : NetworkImage(feedback.author.avatar!),
                  child: feedback.author.avatar == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(authorName(feedback.author))),
                const Icon(Icons.favorite_border, size: 18),
                const SizedBox(width: 4),
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
    );
  }
}

class _CommentHeader extends StatelessWidget {
  final fm.ProjectConfig config;

  const _CommentHeader({required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text('评论', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text(
            config.commentEnabled ? '评论已开启' : '评论已关闭',
            style: TextStyle(
              color: config.commentEnabled ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final String? replyToName;
  final int maxLength;
  final String? hintText;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.replyToName,
    required this.maxLength,
    required this.hintText,
    required this.onCancelReply,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToName != null)
              Row(
                children: [
                  Expanded(child: Text('正在回复 $replyToName')),
                  TextButton(onPressed: onCancelReply, child: const Text('取消')),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled && !sending,
                    maxLength: maxLength,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: enabled ? (hintText ?? '写下你的评论...') : '评论功能已关闭',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: enabled && !sending ? onSend : null,
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('发送'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
