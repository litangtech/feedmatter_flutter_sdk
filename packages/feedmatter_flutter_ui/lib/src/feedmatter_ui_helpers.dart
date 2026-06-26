import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

String formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

String feedbackTypeLabel(fm.FeedbackType? type) {
  switch (type) {
    case fm.FeedbackType.advice:
      return '建议';
    case fm.FeedbackType.error:
      return '问题';
    case fm.FeedbackType.ask:
      return '咨询';
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
