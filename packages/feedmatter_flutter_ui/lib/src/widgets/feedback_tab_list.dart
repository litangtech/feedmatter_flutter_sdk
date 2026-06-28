import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_options.dart';
import '../widgets/feedmatter_submit_fab.dart';
import 'feedback_card.dart';

class FeedMatterFeedbackTabList extends StatelessWidget {
  final List<fm.Feedback> feedbacks;
  final bool loading;
  final bool reserveFabSpace;
  final FeedMatterUiOptions options;
  final Future<void> Function() onRefresh;
  final ValueChanged<fm.Feedback> onTap;
  final ValueChanged<fm.Feedback> onLike;

  const FeedMatterFeedbackTabList({
    super.key,
    required this.feedbacks,
    required this.loading,
    required this.reserveFabSpace,
    required this.options,
    required this.onRefresh,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = reserveFabSpace
        ? FeedMatterBottomActionOverlay.actionClearance
        : 16.0;

    if (loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120 + bottomPadding),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (feedbacks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 12),
            const Center(child: Text('暂无反馈')),
            SizedBox(height: bottomPadding),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 4, bottom: bottomPadding),
        itemCount: feedbacks.length,
        itemBuilder: (context, index) {
          final feedback = feedbacks[index];
          return FeedMatterFeedbackCard(
            feedback: feedback,
            options: options,
            onTap: () => onTap(feedback),
            onLike: () => onLike(feedback),
          );
        },
      ),
    );
  }
}
