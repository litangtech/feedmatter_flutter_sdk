import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/feedmatter_submit_fab.dart';
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

class _FeedMatterFeedbackEntryState extends State<FeedMatterFeedbackEntry>
    with SingleTickerProviderStateMixin {
  fm.ProjectConfig _config = fm.ProjectConfig.defaultConfig();
  bool _loadingConfig = true;
  int _homeRefreshKey = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _onHelpTap() {
    final handler = widget.options.onHelpTap;
    if (handler != null) {
      handler();
      return;
    }
    showFeedMatterSnackBar(context, '请通过 FeedMatterUiOptions.onHelpTap 配置帮助页');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);

    if (_loadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_config.faqEnabled) {
      return FeedMatterHomePage(options: widget.options);
    }

    final showFeedbackFab = _tabController.index == 1;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '帮助与反馈',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _onHelpTap,
            icon: const Icon(Icons.help_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryBlue,
          unselectedLabelColor: theme.textSecondary,
          indicatorColor: theme.primaryBlue,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '常见问题'),
            Tab(text: '反馈列表'),
          ],
        ),
      ),
      body: FeedMatterSubmitFabOverlay(
        visible: showFeedbackFab,
        onPressed: _openSubmitPage,
        child: TabBarView(
          controller: _tabController,
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
              showFloatingSubmit: false,
            ),
          ],
        ),
      ),
    );
  }
}
