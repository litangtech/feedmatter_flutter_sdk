import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../attachment/default_attachment_picker.dart';
import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/attachment_list.dart';
import '../widgets/feedmatter_comment_attachment_strip.dart';
import '../widgets/feedmatter_comment_row.dart';
import '../widgets/feedmatter_link_text.dart';
import '../widgets/feedmatter_tag.dart';
import '../widgets/feedmatter_user_header.dart';

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
  bool _pickingAttachments = false;
  bool _commentsExpanded = true;
  String? _replyToCommentId;
  String? _replyToName;
  List<fm.Attachment> _commentAttachments = [];
  final Map<String, List<fm.Comment>> _extraRepliesByComment = {};
  final Map<String, int> _replyPageByComment = {};
  final Set<String> _loadingReplyCommentIds = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _commentController.addListener(() => setState(() {}));
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

  Future<void> _pickCommentAttachments() async {
    if (!widget.config.commentAttachmentEnabled) return;

    final customPick = widget.options.onPickAttachments;
    final useDefaultPicker = widget.options.useDefaultAttachmentPicker;
    if (customPick == null && !useDefaultPicker) return;

    final maxCount = widget.config.maxAttachments;
    if (_commentAttachments.length >= maxCount) {
      showFeedMatterSnackBar(context, '最多只能添加 $maxCount 个附件', isError: true);
      return;
    }

    setState(() => _pickingAttachments = true);
    try {
      final List<fm.Attachment> picked;
      if (customPick != null) {
        picked = await customPick();
      } else {
        final result = await pickAndUploadAttachments(
          config: widget.config,
          remainingSlots: maxCount - _commentAttachments.length,
        );
        if (result.warning != null && mounted) {
          showFeedMatterSnackBar(context, result.warning!, isError: true);
        }
        picked = result.attachments;
      }

      if (!mounted) return;
      final merged = [..._commentAttachments, ...picked];
      setState(() {
        _commentAttachments = merged.length > maxCount
            ? merged.take(maxCount).toList()
            : merged;
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '附件选择失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _pickingAttachments = false);
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
    if (content.isEmpty && _commentAttachments.isEmpty) {
      showFeedMatterSnackBar(context, '请输入评论内容或添加图片', isError: true);
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
        attachments:
            _commentAttachments.isEmpty ? null : _commentAttachments,
      );
      _commentController.clear();
      _commentAttachments = [];
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
    final theme = FeedMatterUiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '反馈详情',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
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
                          children: [
                            _FeedbackDetailCard(
                              feedback: feedback,
                              options: widget.options,
                            ),
                            _CommentListHeader(
                              expanded: _commentsExpanded,
                              onToggle: () => setState(
                                () => _commentsExpanded = !_commentsExpanded,
                              ),
                            ),
                            if (_commentsExpanded) ..._buildCommentRows(),
                          ],
                        ),
                      ),
                    ),
                    _CommentInputBar(
                      controller: _commentController,
                      enabled: widget.config.commentEnabled &&
                          feedback.allowComment,
                      sending: _sending,
                      pickingAttachments: _pickingAttachments,
                      replyToName: _replyToName,
                      maxLength: widget.config.commentMaxContentLength,
                      hintText: widget.config.commentPrompt,
                      attachments: _commentAttachments,
                      maxAttachments: widget.config.maxAttachments,
                      showAttachmentButton:
                          widget.config.commentAttachmentEnabled &&
                              (widget.options.onPickAttachments != null ||
                                  widget.options
                                      .useDefaultAttachmentPicker),
                      onCancelReply: _clearReplyTarget,
                      onPickAttachment: _pickCommentAttachments,
                      onRemoveAttachment: (attachment) {
                        setState(() {
                          _commentAttachments = _commentAttachments
                              .where((item) => item != attachment)
                              .toList();
                        });
                      },
                      onSend: _sendComment,
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildCommentRows() {
    final comments = _commentPage?.content ?? [];
    if (comments.isEmpty) {
      return const [
        SizedBox(height: 48),
        Center(child: Text('暂无评论，来发布第一条评论吧')),
        SizedBox(height: 48),
      ];
    }

    final rows = <Widget>[];
    for (final comment in comments) {
      final replies = [...comment.replies.content, ..._extraRepliesByComment[comment.id] ?? const []];
      final loadedReplyCount = replies.length;
      final hasMoreReplies = loadedReplyCount < comment.replies.totalElements;
      final isLastMain = comment == comments.last && !hasMoreReplies;

      rows.add(
        FeedMatterCommentRow.fromMainComment(
          comment,
          options: widget.options,
          showDivider: !isLastMain || replies.isNotEmpty || hasMoreReplies,
          onTap: () => _setReplyTarget(
            comment.id,
            authorName(comment.author),
          ),
        ),
      );

      for (var i = 0; i < replies.length; i++) {
        final reply = replies[i];
        final isLastReply = i == replies.length - 1;
        rows.add(
          FeedMatterCommentRow.fromComment(
            reply,
            options: widget.options,
            showDivider: !isLastReply || hasMoreReplies || !isLastMain,
            onTap: () => _setReplyTarget(
              reply.id,
              authorName(reply.author),
            ),
          ),
        );
      }

      if (hasMoreReplies) {
        rows.add(
          _LoadMoreRepliesButton(
            loading: _loadingReplyCommentIds.contains(comment.id),
            loaded: loadedReplyCount,
            total: comment.replies.totalElements,
            onTap: () => _loadMoreReplies(comment),
          ),
        );
      }
    }
    return rows;
  }
}

class _FeedbackDetailCard extends StatelessWidget {
  final fm.Feedback feedback;
  final FeedMatterUiOptions options;

  const _FeedbackDetailCard({
    required this.feedback,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final tags = feedbackTags(feedback);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedMatterUserHeader(
            author: feedback.author,
            createdAt: feedback.createdAt,
            useAbsoluteTime: true,
          ),
          const SizedBox(height: 12),
          FeedMatterLinkText(
            text: feedback.content,
            onUrlTap: options.onContentUrlTap,
          ),
          if (feedback.attachments != null &&
              feedback.attachments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            FeedMatterAttachmentList(attachments: feedback.attachments!),
          ],
          if (tags.isNotEmpty || feedback.commentCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: FeedMatterTagRow(tags: tags)),
                Text(
                  '${feedback.commentCount}评论',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentListHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _CommentListHeader({
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Material(
      color: theme.surfaceColor,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text(
                '评论列表',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreRepliesButton extends StatelessWidget {
  final bool loading;
  final int loaded;
  final int total;
  final VoidCallback onTap;

  const _LoadMoreRepliesButton({
    required this.loading,
    required this.loaded,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Material(
      color: theme.surfaceColor,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              loading ? '加载中...' : '加载更多回复（$loaded/$total）',
              style: TextStyle(
                color: theme.primaryBlue,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final bool pickingAttachments;
  final String? replyToName;
  final int maxLength;
  final String? hintText;
  final List<fm.Attachment> attachments;
  final int maxAttachments;
  final bool showAttachmentButton;
  final VoidCallback onCancelReply;
  final VoidCallback onPickAttachment;
  final ValueChanged<fm.Attachment> onRemoveAttachment;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.pickingAttachments,
    required this.replyToName,
    required this.maxLength,
    required this.hintText,
    required this.attachments,
    required this.maxAttachments,
    required this.showAttachmentButton,
    required this.onCancelReply,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final hasContent = controller.text.trim().isNotEmpty;
    final canSend = (hasContent || attachments.isNotEmpty) && enabled && !sending;
    final placeholder = replyToName != null
        ? '回复 @$replyToName'
        : (enabled ? (hintText ?? '写下你的评论...') : '评论功能已关闭');

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showAttachmentButton && attachments.isNotEmpty)
              FeedMatterCommentAttachmentStrip(
                attachments: attachments,
                maxCount: maxAttachments,
                picking: pickingAttachments,
                enabled: enabled && !sending,
                onAdd: onPickAttachment,
                onRemove: onRemoveAttachment,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled && !sending,
                    maxLength: maxLength,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle:
                          TextStyle(color: theme.textSecondary, fontSize: 14),
                      counterText: '',
                      filled: true,
                      fillColor: theme.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: replyToName != null
                          ? IconButton(
                              onPressed: onCancelReply,
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: theme.textSecondary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (showAttachmentButton) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: enabled && !sending && !pickingAttachments
                        ? onPickAttachment
                        : null,
                    icon: pickingAttachments
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.textSecondary,
                            ),
                          )
                        : Icon(
                            Icons.add_photo_alternate_outlined,
                            color: theme.textSecondary,
                          ),
                  ),
                ],
                const SizedBox(width: 4),
                Material(
                  color: canSend
                      ? theme.sendButtonBackground
                      : theme.sendButtonDisabledBackground,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: canSend ? onSend : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '发送',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
