import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../attachment/default_attachment_picker.dart';
import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';

class FeedMatterSubmitPage extends StatefulWidget {
  final fm.ProjectConfig config;
  final FeedMatterUiOptions options;

  const FeedMatterSubmitPage({
    super.key,
    required this.config,
    this.options = const FeedMatterUiOptions(),
  });

  @override
  State<FeedMatterSubmitPage> createState() => _FeedMatterSubmitPageState();
}

class _FeedMatterSubmitPageState extends State<FeedMatterSubmitPage> {
  final _contentController = TextEditingController();
  fm.FeedbackType _selectedType = fm.FeedbackType.advice;
  bool _submitting = false;
  bool _pickingAttachments = false;
  List<fm.Attachment> _attachments = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final customPick = widget.options.onPickAttachments;
    final useDefaultPicker = widget.options.useDefaultAttachmentPicker;
    if (customPick == null && !useDefaultPicker) return;

    final maxCount = widget.config.maxAttachments;
    if (_attachments.length >= maxCount) {
      showFeedMatterSnackBar(context, '最多只能添加 $maxCount 个附件', isError: true);
      return;
    }

    setState(() => _pickingAttachments = true);
    try {
      final List<fm.Attachment> picked;
      if (customPick != null) {
        picked = await customPick();
      } else {
        final result = await pickAndUploadAttachments(
          config: widget.config,
          remainingSlots: maxCount - _attachments.length,
        );
        if (result.warning != null && mounted) {
          showFeedMatterSnackBar(context, result.warning!, isError: true);
        }
        picked = result.attachments;
      }

      if (!mounted) return;
      final merged = [..._attachments, ...picked];
      if (merged.length > maxCount) {
        showFeedMatterSnackBar(context, '最多只能添加 $maxCount 个附件', isError: true);
        setState(() => _attachments = merged.take(maxCount).toList());
      } else {
        setState(() => _attachments = merged);
      }
    } catch (e) {
      if (mounted) {
        showFeedMatterSnackBar(context, '附件选择失败：$e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _pickingAttachments = false);
      }
    }
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
        customInfo: widget.options.customInfo,
        attachments: _attachments.isEmpty ? null : _attachments,
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
          if (!config.feedbackEnabled)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('当前项目已关闭反馈发布'),
              ),
            ),
          if (!config.feedbackEnabled) const SizedBox(height: 16),
          Text('反馈类型', style: Theme.of(context).textTheme.titleMedium),
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
            if (widget.options.onPickAttachments != null ||
                widget.options.useDefaultAttachmentPicker)
              OutlinedButton.icon(
                onPressed: _pickingAttachments ||
                        _submitting ||
                        _attachments.length >= config.maxAttachments
                    ? null
                    : _pickAttachments,
                icon: _pickingAttachments
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file),
                label: const Text('添加附件'),
              ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final attachment in _attachments)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(attachment.fileName),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _submitting
                        ? null
                        : () {
                            setState(() {
                              _attachments = _attachments
                                  .where((item) => item != attachment)
                                  .toList();
                            });
                          },
                  ),
                ),
            ],
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
