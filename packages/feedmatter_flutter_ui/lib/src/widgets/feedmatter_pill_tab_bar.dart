import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

class FeedMatterPillTabBar extends StatelessWidget {
  final TabController controller;
  final ValueChanged<int>? onTap;
  final List<String> tabs;

  const FeedMatterPillTabBar({
    super.key,
    required this.controller,
    this.onTap,
    this.tabs = const ['全部', '我的反馈'],
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: controller.animation!,
            builder: (context, _) {
              final animationValue = controller.animation!.value;
              final selectedIndex =
                  animationValue.round().clamp(0, tabs.length - 1);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / tabs.length;
                  const indicatorWidth = 32.0;
                  final indicatorLeft =
                      tabWidth * animationValue + (tabWidth - indicatorWidth) / 2;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Expanded(
                              child: GestureDetector(
                                onTap: onTap == null
                                    ? null
                                    : () => onTap!(i),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    tabs[i],
                                    textAlign: TextAlign.center,
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
                              ),
                            ),
                        ],
                      ),
                      Positioned(
                        left: indicatorLeft,
                        bottom: 0,
                        child: Container(
                          height: 2,
                          width: indicatorWidth,
                          decoration: BoxDecoration(
                            color: theme.primaryBlue,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}
