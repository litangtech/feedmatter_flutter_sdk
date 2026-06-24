import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import 'feedmatter_ui_helpers.dart';

class FeedMatterSubmitPage extends StatefulWidget {
  final fm.ProjectConfig config;

  const FeedMatterSubmitPage({
    super.key,
    required this.config,
  });

  @override
  State<FeedMatterSubmitPage> createState() => _FeedMatterSubmitPageState();
}

class _FeedMatterSubmitPageState extends State<FeedMatterSubmitPage> {
  final _contentController = TextEditingController();
  fm.FeedbackType _selectedType = fm.FeedbackType.advice;
  bool _submitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      showFeedMatterSnackBar(context, '请输入反馈内容', isError: true);
      return;
    }
    if (content.length > widget.config.feedbackMaxContentLength) {
      showFeedMatterSnackBar(
        context,
        '反馈内容不能超过 ${widget.config.feedbackMaxContentLength} 字',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await fm.FeedMatterClient.instance.createFeedback(
        content: content,
        type: _selectedType,
        customInfo: {
          'source': 'feedmatter_flutter_sdk_example',
          'ui': 'copyable_example',
        },
      );
      if (!mounted) return;
      showFeedMatterSnackBar(context, '反馈提交成功');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Scaffold(
      appBar: AppBar(title: const Text('提交反馈')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ConfigNotice(config: config),
          const SizedBox(height: 16),
          Text(
            '反馈类型',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in [
                fm.FeedbackType.advice,
                fm.FeedbackType.error,
                fm.FeedbackType.ask,
                fm.FeedbackType.help,
                fm.FeedbackType.other,
              ])
                ChoiceChip(
                  label: Text(feedbackTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (_) => setState(() => _selectedType = type),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            minLines: 6,
            maxLines: 10,
            maxLength: config.feedbackMaxContentLength,
            decoration: InputDecoration(
              labelText: '反馈内容',
              hintText: config.feedbackPrompt ?? '请描述你的问题或建议...',
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          if (config.feedbackAttachmentEnabled) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                showFeedMatterSnackBar(
                  context,
                  '这里预留给业务 App 接入文件选择器，然后调用 uploadPublicFile() 上传。',
                );
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('添加附件（示例预留）'),
            ),
            const SizedBox(height: 8),
            Text(
              '最多 ${config.maxAttachments} 个附件，单个文件最大 ${(config.maxUploadFileSize / 1024 / 1024).round()}MB。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting || !config.feedbackEnabled ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('提交反馈'),
          ),
        ],
      ),
    );
  }
}

class _ConfigNotice extends StatelessWidget {
  final fm.ProjectConfig config;

  const _ConfigNotice({required this.config});

  @override
  Widget build(BuildContext context) {
    if (config.feedbackEnabled) {
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '示例会在进入提交页前检查项目配置。你可以复制这里的判断逻辑，用来控制反馈入口、附件入口和字数限制。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('当前项目已关闭反馈发布，客户端应隐藏提交入口或展示禁用提示。'),
      ),
    );
  }
}
