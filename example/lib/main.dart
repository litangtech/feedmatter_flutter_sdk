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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
        apiKey: '501fd22890ee44de9e4f3ca1007315b6',
        timeout: 30,
        debug: true,
        apiSecret: '57a24150121247d5beb95f2ddb0218ac',
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
        showProjectConfigDebugPanel: true,
        customInfo: const {
          'source': 'feedmatter_flutter_sdk_example',
          'ui': 'feedmatter_flutter_ui',
        },
      ),
    );
  }
}
