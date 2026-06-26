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
      theme: buildFeedMatterTheme(),
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

  @override
  Widget build(BuildContext context) {
    return FeedMatterFeedbackEntry(
      options: FeedMatterUiOptions(
        customInfo: const {
          'source': 'feedmatter_flutter_sdk_example',
          'ui': 'feedmatter_flutter_ui',
        },
        onHelpTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('帮助页面示例：请接入你的帮助文档')),
          );
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
      ),
    );
  }
}
