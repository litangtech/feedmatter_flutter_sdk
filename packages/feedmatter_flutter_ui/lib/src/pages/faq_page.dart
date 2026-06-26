import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../faq/faq_cache.dart';
import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import 'feedback_submit_page.dart';

class FeedMatterFaqPage extends StatefulWidget {
  final fm.ProjectConfig config;
  final FeedMatterUiOptions options;
  final bool embedded;
  final VoidCallback? onSubmitFeedback;

  const FeedMatterFaqPage({
    super.key,
    required this.config,
    this.options = const FeedMatterUiOptions(),
    this.embedded = false,
    this.onSubmitFeedback,
  });

  @override
  State<FeedMatterFaqPage> createState() => _FeedMatterFaqPageState();
}

class _FeedMatterFaqPageState extends State<FeedMatterFaqPage> {
  final _searchController = TextEditingController();
  List<fm.FaqItem> _items = [];
  bool _loading = true;
  String _searchQuery = '';

  FeedMatterFaqCache get _cache =>
      widget.options.faqCache ?? InMemoryFeedMatterFaqCache();

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() => _loading = true);
    try {
      final cachedVersion = await _cache.getVersion() ?? '0';
      final cachedItems = await _cache.getItems() ?? const <fm.FaqItem>[];

      final response = await fm.FeedMatterClient.instance.getFaqList(
        version: cachedVersion,
      );

      if (!mounted) return;
      if (response.hasUpdate) {
        await _cache.save(response.version, response.items);
        setState(() => _items = response.items);
      } else {
        setState(() => _items = cachedItems);
      }
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '常见问题加载失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openUrl(String url) {
    final onUrlTap = widget.options.onFaqUrlTap;
    if (onUrlTap != null) {
      onUrlTap(url);
      return;
    }
    showFeedMatterSnackBar(
      context,
      '请通过 FeedMatterUiOptions.onFaqUrlTap 处理链接：$url',
    );
  }

  Future<void> _openSubmitFeedback() async {
    if (widget.onSubmitFeedback != null) {
      widget.onSubmitFeedback!();
      return;
    }
    if (!widget.config.feedbackEnabled) {
      showFeedMatterSnackBar(context, '当前项目已关闭反馈发布', isError: true);
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FeedMatterSubmitPage(
          config: widget.config,
          options: widget.options,
        ),
      ),
    );
  }

  List<fm.FaqItem> get _visibleItems => filterFaqItems(
    _items,
    keyword: _searchQuery,
    platformFilter: widget.options.platformFilter,
  );

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '搜索常见问题',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(child: _buildList()),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.config.feedbackEnabled
                    ? _openSubmitFeedback
                    : null,
                child: const Text('没有解决？提交反馈'),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('常见问题'),
        actions: [
          IconButton(onPressed: _loadFaqs, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: content,
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _visibleItems;
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.quiz_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('暂无常见问题')),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFaqs,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ExpansionTile(
              title: Text(item.title),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.answer != null && item.answer!.isNotEmpty)
                        Text(item.answer!),
                      if (item.url != null && item.url!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _openUrl(item.url!),
                          child: const Text('查看详情'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
