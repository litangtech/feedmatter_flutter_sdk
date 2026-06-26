import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import 'widgets/feedmatter_tag.dart';

String formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return formatAbsoluteTime(time);
}

String formatDisplayTime(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inDays < 7) {
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
  return formatAbsoluteTime(time);
}

String formatAbsoluteTime(DateTime time) {
  final local = time.toLocal();
  final year = local.year;
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String feedbackTypeLabel(fm.FeedbackType? type) {
  switch (type) {
    case fm.FeedbackType.advice:
      return '建议';
    case fm.FeedbackType.error:
      return '错误';
    case fm.FeedbackType.ask:
      return '提问';
    case fm.FeedbackType.help:
      return '求助';
    case fm.FeedbackType.notice:
      return '公告';
    case fm.FeedbackType.other:
    case null:
      return '其他';
  }
}

String feedbackStatusLabel(fm.FeedbackStatus status) {
  switch (status) {
    case fm.FeedbackStatus.pending:
      return '待处理';
    case fm.FeedbackStatus.inProgress:
      return '处理中';
    case fm.FeedbackStatus.resolved:
      return '已解决';
    case fm.FeedbackStatus.hidden:
      return '已隐藏';
    case fm.FeedbackStatus.deleted:
      return '已删除';
  }
}

Color feedbackStatusColor(fm.FeedbackStatus status) {
  switch (status) {
    case fm.FeedbackStatus.pending:
      return Colors.orange;
    case fm.FeedbackStatus.inProgress:
      return Colors.blue;
    case fm.FeedbackStatus.resolved:
      return Colors.green;
    case fm.FeedbackStatus.hidden:
    case fm.FeedbackStatus.deleted:
      return Colors.grey;
  }
}

String authorName(fm.Author author) {
  final username = author.username;
  if (username != null && username.trim().isNotEmpty) {
    return username;
  }
  return '匿名用户';
}

String? platformLabel(fm.ClientInfo? clientInfo) {
  final appType = clientInfo?.appType;
  if (appType == null || appType.trim().isEmpty) return null;
  return appType.toUpperCase();
}

bool isFeedbackAdmin(fm.FeedbackMark? mark) {
  if (mark == null) return false;
  return mark.isAdmin || mark.isAdminReply;
}

bool isCommentAdmin(fm.CommentMark? mark) {
  if (mark == null) return false;
  return mark.isAdmin || mark.isAdminReply;
}

List<FeedMatterTagData> feedbackTags(fm.Feedback feedback) {
  final tags = <FeedMatterTagData>[];
  if (isFeedbackAdmin(feedback.mark)) {
    tags.add(const FeedMatterTagData(label: '管理员', variant: FeedMatterTagVariant.admin));
  }
  if (feedback.isPinned) {
    tags.add(const FeedMatterTagData(label: '置顶', variant: FeedMatterTagVariant.pinned));
  }
  if (feedback.type == fm.FeedbackType.notice) {
    tags.add(const FeedMatterTagData(label: '公告', variant: FeedMatterTagVariant.notice));
  }
  if (feedback.type != null && feedback.type != fm.FeedbackType.notice) {
    tags.add(FeedMatterTagData(
      label: feedbackTypeLabel(feedback.type),
      variant: FeedMatterTagVariant.type,
    ));
  }
  final platform = platformLabel(feedback.clientInfo);
  if (platform != null) {
    tags.add(FeedMatterTagData(label: platform, variant: FeedMatterTagVariant.platform));
  }
  return tags;
}

void showFeedMatterSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}

List<fm.FaqItem> filterFaqItems(
  List<fm.FaqItem> items, {
  String? keyword,
  String? platformFilter,
}) {
  return items.where((item) {
    if (platformFilter != null &&
        platformFilter.isNotEmpty &&
        item.platforms != null &&
        item.platforms!.isNotEmpty &&
        !item.platforms!.contains(platformFilter)) {
      return false;
    }
    if (keyword == null || keyword.trim().isEmpty) {
      return true;
    }
    final query = keyword.trim().toLowerCase();
    final title = item.title.toLowerCase();
    final answer = (item.answer ?? '').toLowerCase();
    final keywords = (item.keywords ?? '').toLowerCase();
    return title.contains(query) ||
        answer.contains(query) ||
        keywords.contains(query);
  }).toList();
}
