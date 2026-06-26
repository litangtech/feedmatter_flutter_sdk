import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import 'faq_page.dart';
import 'feedback_home_page.dart';
import 'feedback_submit_page.dart';

class FeedMatterFeedbackEntry extends StatefulWidget {
  final FeedMatterUiOptions options;

  const FeedMatterFeedbackEntry({
    super.key,
    this.options = const FeedMatterUiOptions(),
  });

  @override
  State<FeedMatterFeedbackEntry> createState() =>
      _FeedMatterFeedbackEntryState();
}

class _FeedMatterFeedbackEntryState extends State<FeedMatterFeedbackEntry> {
  fm.ProjectConfig _config = fm.ProjectConfig.defaultConfig();
  bool _loadingConfig = true;
  int _homeRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _loadingConfig = true);
    try {
      final config = await fm.FeedMatterClient.instance.getProjectConfig();
      if (mounted) {
        setState(() => _config = config);
      }
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '项目配置加载失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingConfig = false);
      }
    }
  }

  Future<void> _openSubmitPage() async {
    if (!_config.feedbackEnabled) {
      showFeedMatterSnackBar(context, '当前项目已关闭反馈发布', isError: true);
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FeedMatterSubmitPage(config: _config, options: widget.options),
      ),
    );
    if (created == true && mounted) {
      setState(() => _homeRefreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_config.faqEnabled) {
      return FeedMatterHomePage(options: widget.options);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('帮助与反馈'),
          actions: [
            IconButton(onPressed: _loadConfig, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '常见问题'),
              Tab(text: '反馈列表'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openSubmitPage,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('提交反馈'),
        ),
        body: TabBarView(
          children: [
            FeedMatterFaqPage(
              config: _config,
              options: widget.options,
              embedded: true,
              onSubmitFeedback: _openSubmitPage,
            ),
            FeedMatterHomePage(
              key: ValueKey(_homeRefreshKey),
              options: widget.options,
              embedded: true,
            ),
          ],
        ),
      ),
    );
  }
}
