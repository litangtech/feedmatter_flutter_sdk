import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../faq/faq_cache.dart';
import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/feedmatter_link_text.dart';
import '../widgets/feedmatter_search_bar.dart';
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
    final theme = FeedMatterUiTheme.of(context);
    final body = _buildBody(theme);

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
          '常见问题',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody(FeedMatterUiTheme theme) {
    return ColoredBox(
      color: theme.pageBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FeedMatterSearchBar(
              controller: _searchController,
              hintText: '搜索常见问题',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          Expanded(child: _buildList(theme)),
          if (!widget.embedded) _FaqSubmitFooter(
            theme: theme,
            enabled: widget.config.feedbackEnabled,
            onPressed: _openSubmitFeedback,
          ),
        ],
      ),
    );
  }

  Widget _buildList(FeedMatterUiTheme theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _visibleItems;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFaqs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF999999)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '暂无常见问题',
                style: TextStyle(color: theme.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFaqs,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _FaqListCard(
            item: item,
            theme: theme,
            options: widget.options,
            onOpenUrl: _openUrl,
          );
        },
      ),
    );
  }
}

class _FaqListCard extends StatelessWidget {
  final fm.FaqItem item;
  final FeedMatterUiTheme theme;
  final FeedMatterUiOptions options;
  final ValueChanged<String> onOpenUrl;

  const _FaqListCard({
    required this.item,
    required this.theme,
    required this.options,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: theme.primaryBlue.withAlpha(20),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: theme.textSecondary,
          collapsedIconColor: theme.textSecondary,
          title: Text(
            item.title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          children: [
            if (item.answer != null && item.answer!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: FeedMatterLinkText(
                  text: item.answer!,
                  onUrlTap: options.onContentUrlTap ?? onOpenUrl,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            if (item.url != null && item.url!.isNotEmpty) ...[
              if (item.answer != null && item.answer!.isNotEmpty)
                const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => onOpenUrl(item.url!),
                  child: Text(
                    '查看详情',
                    style: TextStyle(
                      color: theme.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqSubmitFooter extends StatelessWidget {
  final FeedMatterUiTheme theme;
  final bool enabled;
  final VoidCallback onPressed;

  const _FaqSubmitFooter({
    required this.theme,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryBlue,
              disabledBackgroundColor: theme.primaryBlue.withAlpha(128),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '没有解决？提交反馈',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
