import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import 'feedback_detail_page.dart';
import 'feedback_submit_page.dart';
import '../widgets/feedback_card.dart';

class FeedMatterHomePage extends StatefulWidget {
  final FeedMatterUiOptions options;
  final bool embedded;

  const FeedMatterHomePage({
    super.key,
    this.options = const FeedMatterUiOptions(),
    this.embedded = false,
  });

  @override
  State<FeedMatterHomePage> createState() => _FeedMatterHomePageState();
}

class _FeedMatterHomePageState extends State<FeedMatterHomePage> {
  final _keywordController = TextEditingController();
  fm.ProjectConfig _config = fm.ProjectConfig.defaultConfig();
  List<fm.Feedback> _feedbacks = [];
  bool _loading = true;
  bool _loadingConfig = true;
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadConfig(), _loadFeedbacks()]);
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

  Future<void> _loadFeedbacks() async {
    setState(() => _loading = true);
    try {
      final keyword = _keywordController.text.trim();
      final feedbacks = _onlyMine
          ? await fm.FeedMatterClient.instance.getMyFeedbacks(
              size: 30,
              keyword: keyword.isEmpty ? null : keyword,
            )
          : await fm.FeedMatterClient.instance.getFeedbacks(
              size: 30,
              keyword: keyword.isEmpty ? null : keyword,
            );
      if (mounted) {
        setState(() => _feedbacks = feedbacks);
      }
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
      await _loadFeedbacks();
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
      await _loadFeedbacks();
    }
  }

  Future<void> _toggleLike(fm.Feedback feedback) async {
    try {
      final updated = await fm.FeedMatterClient.instance.toggleLike(
        feedback.id,
      );
      if (!mounted) return;
      setState(() {
        _feedbacks = _feedbacks
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '点赞失败：$e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户反馈'),
        actions: [
          IconButton(onPressed: _bootstrap, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingConfig ? null : _openSubmitPage,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('提交反馈'),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (widget.options.showProjectConfigDebugPanel)
          _ProjectConfigPanel(loading: _loadingConfig, config: _config),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _keywordController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadFeedbacks(),
            decoration: InputDecoration(
              hintText: '搜索反馈内容',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _keywordController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _keywordController.clear();
                        _loadFeedbacks();
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('全部反馈')),
              ButtonSegment(value: true, label: Text('我的反馈')),
            ],
            selected: {_onlyMine},
            onSelectionChanged: (value) {
              setState(() => _onlyMine = value.first);
              _loadFeedbacks();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFeedbacks,
            child: _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_feedbacks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inbox_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('暂无反馈')),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = _feedbacks[index];
        return FeedMatterFeedbackCard(
          feedback: feedback,
          onTap: () => _openDetailPage(feedback),
          onLike: () => _toggleLike(feedback),
        );
      },
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
