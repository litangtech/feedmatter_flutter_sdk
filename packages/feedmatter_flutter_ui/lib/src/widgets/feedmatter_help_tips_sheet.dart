import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

class _HelpTipItem {
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String description;

  const _HelpTipItem({
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _helpTips = [
  _HelpTipItem(
    iconBackground: Color(0xFFFF4D4F),
    icon: Icons.warning_amber_rounded,
    title: '违规内容',
    description: '请勿发布违规内容（如广告、色情、政治等），否则将会被封号',
  ),
  _HelpTipItem(
    iconBackground: Color(0xFF9254DE),
    icon: Icons.person_outline,
    title: '反馈审核',
    description: '反馈提交后，处于审核中状态，仅发布者自己可见，经管理员处理后的反馈会公开显示',
  ),
];

void showFeedMatterHelpTipsSheet(BuildContext context) {
  final theme = FeedMatterUiTheme.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _FeedMatterHelpTipsSheet(),
  );
}

class _FeedMatterHelpTipsSheet extends StatelessWidget {
  const _FeedMatterHelpTipsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '提示',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < _helpTips.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              _HelpTipRow(item: _helpTips[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpTipRow extends StatelessWidget {
  final _HelpTipItem item;

  const _HelpTipRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
