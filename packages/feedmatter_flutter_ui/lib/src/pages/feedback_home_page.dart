import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/feedmatter_pill_tab_bar.dart';
import '../widgets/feedmatter_search_bar.dart';
import '../widgets/feedmatter_submit_fab.dart';
import 'feedback_detail_page.dart';
import 'feedback_submit_page.dart';
import '../widgets/feedback_card.dart';

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
  final _keywordController = TextEditingController();
  late final TabController _tabController;
  fm.ProjectConfig _config = fm.ProjectConfig.defaultConfig();
  final List<fm.Feedback> _allFeedbacks = [];
  final List<fm.Feedback> _myFeedbacks = [];
  bool _allLoading = true;
  bool _myLoading = true;
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    _loadFeedbacks(forMine: _tabController.index == 1);
  }

  Future<void> _bootstrap() async {
    await _loadConfig();
    await Future.wait([
      _loadFeedbacks(forMine: false),
      _loadFeedbacks(forMine: true),
    ]);
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

  Future<void> _loadFeedbacks({required bool forMine}) async {
    setState(() {
      if (forMine) {
        _myLoading = true;
      } else {
        _allLoading = true;
      }
    });
    try {
      final trimmedKeyword = _keywordController.text.trim();
      final keyword = forMine
          ? null
          : (trimmedKeyword.isEmpty ? null : trimmedKeyword);
      final feedbacks = forMine
          ? await fm.FeedMatterClient.instance.getMyFeedbacks(
              size: 30,
              keyword: keyword.isEmpty ? null : keyword,
            )
          : await fm.FeedMatterClient.instance.getFeedbacks(
              size: 30,
              keyword: keyword.isEmpty ? null : keyword,
            );
      if (!mounted) return;
      setState(() {
        if (forMine) {
          _myFeedbacks
            ..clear()
            ..addAll(feedbacks);
          _myLoading = false;
        } else {
          _allFeedbacks
            ..clear()
            ..addAll(feedbacks);
          _allLoading = false;
        }
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '反馈列表加载失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          if (forMine) {
            _myLoading = false;
          } else {
            _allLoading = false;
          }
        });
      }
    }
  }

  Future<void> _reloadAllTabs() async {
    await Future.wait([
      _loadFeedbacks(forMine: false),
      _loadFeedbacks(forMine: true),
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
      setState(() {
        _replaceFeedback(_allFeedbacks, updated);
        _replaceFeedback(_myFeedbacks, updated);
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '点赞失败：$e', isError: true);
      }
    }
  }

  void _replaceFeedback(List<fm.Feedback> list, fm.Feedback updated) {
    final index = list.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      list[index] = updated;
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
            onTap: (index) => _tabController.animateTo(index),
          ),
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: FeedMatterSearchBar(
                controller: _keywordController,
                onSubmitted: (_) => _loadFeedbacks(forMine: false),
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _keywordController.clear();
                  setState(() {});
                  _loadFeedbacks(forMine: false);
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabList(
                  feedbacks: _allFeedbacks,
                  loading: _allLoading,
                  reserveFabSpace: reserveFabSpace,
                  onRefresh: () => _loadFeedbacks(forMine: false),
                ),
                _buildTabList(
                  feedbacks: _myFeedbacks,
                  loading: _myLoading,
                  reserveFabSpace: reserveFabSpace,
                  onRefresh: () => _loadFeedbacks(forMine: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabList({
    required List<fm.Feedback> feedbacks,
    required bool loading,
    required bool reserveFabSpace,
    required Future<void> Function() onRefresh,
  }) {
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
            options: widget.options,
            onTap: () => _openDetailPage(feedback),
            onLike: () => _toggleLike(feedback),
          );
        },
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
