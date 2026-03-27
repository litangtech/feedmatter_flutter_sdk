import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart'
    as feedmatter;
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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _feedbackController = TextEditingController();
  late feedmatter.FeedMatterClient client;
  List<feedmatter.Feedback> _feedbacks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化 SDK
    client = feedmatter.FeedMatterClient.instance;
    client.init(
      const feedmatter.FeedMatterConfig(
        baseUrl: 'https://fmapi.feedmatter.com',
        apiKey: 'your-api-key',
        timeout: 30,
        debug: true,
        apiSecret: '',
        appMarket: 'example',
      ),
      feedmatter.FeedMatterUser(
        userId: 'test-user-id',
        userName: 'Test User',
        userAvatar: 'https://example.com/avatar.png',
      ),
      onError: (error) {
        // 全局错误处理
        if (mounted) {
          _showError(error.toString());
        }
      },
    );

    // 加载反馈列表
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      // 获取所有反馈
      final feedbacks = await client.getFeedbacks();
      if (mounted) {
        setState(() {
          _feedbacks = feedbacks;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showError('请输入反馈内容');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await client.createFeedback(
        content: _feedbackController.text,
        customInfo: {'source': 'example_app'},
      );
      _feedbackController.clear();
      await _loadFeedbacks(); // 重新加载列表
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('反馈提交成功')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FeedMatter Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadFeedbacks,
          ),
        ],
      ),
      body: Column(
        children: [
          // 提交反馈区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feedbackController,
                    decoration: const InputDecoration(
                      hintText: '请输入反馈内容...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  child: const Text('提交'),
                ),
              ],
            ),
          ),

          // 反馈列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _feedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = _feedbacks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(feedback.content),
                          subtitle: Text(
                            '状态: ${feedback.status} · ${feedback.commentCount} 条评论 · ${feedback.likeCount} 个赞',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  feedback.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: feedback.isLiked ? Colors.red : null,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          await client.toggleLike(feedback.id);
                                          await _loadFeedbacks(); // 重新加载列表以更新状态
                                        } catch (e) {
                                          _showError(e.toString());
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      },
                              ),
                              Text(_formatDate(feedback.createdAt)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
