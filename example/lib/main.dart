import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart'
    as feedmatter;
import 'package:feedmatter_flutter_ui/feedmatter_flutter_ui.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeedMatter Demo',
      theme: buildFeedMatterLightTheme(),
      darkTheme: buildFeedMatterDarkTheme(),
      home: const FeedMatterExampleApp(),
    );
  }
}

class FeedMatterExampleApp extends StatefulWidget {
  const FeedMatterExampleApp({super.key});

  @override
  State<FeedMatterExampleApp> createState() => _FeedMatterExampleAppState();
}

class _FeedMatterExampleAppState extends State<FeedMatterExampleApp> {
  FeedMatterThemeMode _themeMode = FeedMatterThemeMode.system;
  Color _seedColor = const Color(0xFF3B82F6);

  static const _seedColorOptions = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF6750A4),
    Color(0xFF52C41A),
    Color(0xFFFF4D4F),
  ];

  @override
  void initState() {
    super.initState();
    feedmatter.FeedMatterClient.instance.init(
      // 下面的 apiKey 和 apiSecret 是 FeedMatter 测试项目的示例密钥，
      // 仅用于快速运行 example。接入正式项目时请替换为你的项目配置。
      const feedmatter.FeedMatterConfig(
        baseUrl: 'https://fmapi.litangkj.com',
        apiKey: '276947d1c9bd45eda07653b69cee88c0',
        timeout: 30,
        debug: false, // false 时隐藏列表页顶部的配置调试开关
        apiSecret: '5c7ce8c000ac4e9096241524096dd511',
        appMarket: 'example',
      ),
      feedmatter.FeedMatterUser(
        userId: 'test-user-id',
        userName: 'Test User',
        userAvatar: 'https://example.com/avatar.png',
      ),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  FeedMatterUiOptions get _uiOptions => FeedMatterUiOptions(
        theme: FeedMatterThemeOptions(
          mode: _themeMode,
          seedColor: _seedColor,
        ),
        customInfo: const {
          'source': 'feedmatter_flutter_sdk_example',
          'ui': 'feedmatter_flutter_ui',
        },
        onContentUrlTap: (url) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('链接点击：$url')),
          );
        },
        onFaqUrlTap: (url) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('FAQ 链接：$url')),
          );
        },
      );

  void _openFeedback() {
    FeedMatterThemeScope.push<void>(
      context,
      theme: FeedMatterThemeOptions(
        mode: _themeMode,
        seedColor: _seedColor,
      ),
      child: FeedMatterFeedbackEntry(options: _uiOptions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FeedMatter Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('主题设置', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '调整下方选项后，进入意见反馈页查看效果。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Text('主题模式', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<FeedMatterThemeMode>(
            segments: const [
              ButtonSegment(
                value: FeedMatterThemeMode.light,
                label: Text('浅色'),
              ),
              ButtonSegment(
                value: FeedMatterThemeMode.dark,
                label: Text('深色'),
              ),
              ButtonSegment(
                value: FeedMatterThemeMode.system,
                label: Text('跟随系统'),
              ),
            ],
            selected: {_themeMode},
            onSelectionChanged: (selection) {
              setState(() => _themeMode = selection.first);
            },
          ),
          const SizedBox(height: 24),
          Text('主题色', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in _seedColorOptions)
                ChoiceChip(
                  label: Text(
                    '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                    style: TextStyle(
                      color: _seedColor == color ? Colors.white : null,
                    ),
                  ),
                  selected: _seedColor == color,
                  selectedColor: color,
                  onSelected: (_) => setState(() => _seedColor = color),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _openFeedback,
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('进入意见反馈'),
          ),
        ],
      ),
    );
  }
}
