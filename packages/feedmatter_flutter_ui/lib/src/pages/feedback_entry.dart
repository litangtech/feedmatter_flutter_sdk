import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/feedmatter_help_tips_sheet.dart';
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

  Future<void> _openFaqPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FeedMatterFaqPage(
          config: _config,
          options: widget.options,
          onSubmitFeedback: _openSubmitPage,
        ),
      ),
    );
  }

  void _onHelpTap() {
    final handler = widget.options.onHelpTap;
    if (handler != null) {
      handler();
      return;
    }
    showFeedMatterHelpTipsSheet(context);
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

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '意见反馈',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _onHelpTap,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: FeedMatterBottomActionOverlay(
        leftAction: FeedMatterBottomPill(
          onPressed: _openFaqPage,
          label: '常见问题',
          icon: Icons.quiz_outlined,
        ),
        rightAction: FeedMatterSubmitFab(
          onPressed: _loadingConfig ? null : _openSubmitPage,
        ),
        child: FeedMatterHomePage(
          key: ValueKey(_homeRefreshKey),
          options: widget.options,
          embedded: true,
          showFloatingSubmit: false,
        ),
      ),
    );
  }
}
