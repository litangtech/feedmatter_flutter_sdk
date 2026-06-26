import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/feedmatter_pill_tab_bar.dart';
import '../widgets/feedmatter_submit_fab.dart';
import 'feedback_all_tab.dart';
import 'feedback_detail_page.dart';
import 'feedback_my_tab.dart';
import 'feedback_submit_page.dart';

class FeedMatterHomePage extends StatefulWidget {
  final FeedMatterUiOptions options;
  final bool embedded;
  final bool showFloatingSubmit;

  const FeedMatterHomePage({
    super.key,
    this.options = const FeedMatterUiOptions(),
    this.embedded = false,
    this.showFloatingSubmit = true,
  });

  @override
  State<FeedMatterHomePage> createState() => _FeedMatterHomePageState();
}

class _FeedMatterHomePageState extends State<FeedMatterHomePage>
    with SingleTickerProviderStateMixin {
  final _allTabKey = GlobalKey<FeedMatterAllFeedbacksTabState>();
  final _myTabKey = GlobalKey<FeedMatterMyFeedbacksTabState>();
  late final TabController _tabController;
  fm.ProjectConfig _config = fm.ProjectConfig.defaultConfig();
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _reloadAllTabs() async {
    await Future.wait([
      _allTabKey.currentState?.reload() ?? Future.value(),
      _myTabKey.currentState?.reload() ?? Future.value(),
    ]);
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
    if (created == true) {
      await _reloadAllTabs();
    }
  }

  Future<void> _openDetailPage(fm.Feedback feedback) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FeedMatterDetailPage(
          feedbackId: feedback.id,
          config: _config,
          options: widget.options,
        ),
      ),
    );
    if (changed == true) {
      await _reloadAllTabs();
    }
  }

  Future<void> _toggleLike(fm.Feedback feedback) async {
    try {
      final updated = await fm.FeedMatterClient.instance.toggleLike(
        feedback.id,
      );
      if (!mounted) return;
      _allTabKey.currentState?.updateFeedback(updated);
      _myTabKey.currentState?.updateFeedback(updated);
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '点赞失败：$e', isError: true);
      }
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
    final body = _buildBody();

    if (widget.embedded) {
      return body;
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
        rightAction: FeedMatterSubmitFab(
          onPressed: _loadingConfig ? null : _openSubmitPage,
        ),
        child: body,
      ),
    );
  }

  Widget _buildBody() {
    final theme = FeedMatterUiTheme.of(context);
    final reserveFabSpace = widget.showFloatingSubmit || widget.embedded;

    return ColoredBox(
      color: theme.pageBackground,
      child: Column(
        children: [
          if (shouldShowProjectConfigDebugPanel(widget.options))
            _ProjectConfigPanel(loading: _loadingConfig, config: _config),
          FeedMatterPillTabBar(
            controller: _tabController,
            onTap: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              _tabController.animateTo(index);
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FeedMatterAllFeedbacksTab(
                  key: _allTabKey,
                  options: widget.options,
                  reserveFabSpace: reserveFabSpace,
                  onTap: _openDetailPage,
                  onLike: _toggleLike,
                ),
                FeedMatterMyFeedbacksTab(
                  key: _myTabKey,
                  options: widget.options,
                  reserveFabSpace: reserveFabSpace,
                  onTap: _openDetailPage,
                  onLike: _toggleLike,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectConfigPanel extends StatelessWidget {
  final bool loading;
  final fm.ProjectConfig config;

  const _ProjectConfigPanel({required this.loading, required this.config});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SwitchBadge(label: '反馈', enabled: config.feedbackEnabled),
          _SwitchBadge(label: '评论', enabled: config.commentEnabled),
          _SwitchBadge(
            label: '反馈附件',
            enabled: config.feedbackAttachmentEnabled,
          ),
          _SwitchBadge(label: '评论附件', enabled: config.commentAttachmentEnabled),
          _SwitchBadge(label: 'FAQ', enabled: config.faqEnabled),
          _SwitchBadge(label: '游客反馈', enabled: config.guestFeedbackEnabled),
          _SwitchBadge(label: '游客评论', enabled: config.guestCommentEnabled),
        ],
      ),
    );
  }
}

class _SwitchBadge extends StatelessWidget {
  final String label;
  final bool enabled;

  const _SwitchBadge({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label：${enabled ? '开' : '关'}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
