import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../widgets/feedback_tab_list.dart';

class FeedMatterMyFeedbacksTab extends StatefulWidget {
  final FeedMatterUiOptions options;
  final bool reserveFabSpace;
  final ValueChanged<fm.Feedback> onTap;
  final ValueChanged<fm.Feedback> onLike;

  const FeedMatterMyFeedbacksTab({
    super.key,
    required this.options,
    required this.reserveFabSpace,
    required this.onTap,
    required this.onLike,
  });

  @override
  FeedMatterMyFeedbacksTabState createState() => FeedMatterMyFeedbacksTabState();
}

class FeedMatterMyFeedbacksTabState extends State<FeedMatterMyFeedbacksTab>
    with AutomaticKeepAliveClientMixin {
  final List<fm.Feedback> _feedbacks = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() => _loadFeedbacks();

  void updateFeedback(fm.Feedback updated) {
    final index = _feedbacks.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      setState(() => _feedbacks[index] = updated);
    }
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _loading = true);
    try {
      final feedbacks = await fm.FeedMatterClient.instance.getMyFeedbacks(
        size: 30,
      );
      if (!mounted) return;
      setState(() {
        _feedbacks
          ..clear()
          ..addAll(feedbacks);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '反馈列表加载失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FeedMatterFeedbackTabList(
      feedbacks: _feedbacks,
      loading: _loading,
      reserveFabSpace: widget.reserveFabSpace,
      options: widget.options,
      onRefresh: _loadFeedbacks,
      onTap: widget.onTap,
      onLike: widget.onLike,
    );
  }
}
