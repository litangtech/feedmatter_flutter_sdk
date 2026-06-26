import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

class FeedMatterPillTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> tabs;

  const FeedMatterPillTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.tabs = const ['全部', '我的反馈'],
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            tabs[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selectedIndex == i
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selectedIndex == i
                                  ? theme.primaryBlue
                                  : theme.textSecondary,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: selectedIndex == i ? 32 : 0,
                          decoration: BoxDecoration(
                            color: theme.primaryBlue,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}
