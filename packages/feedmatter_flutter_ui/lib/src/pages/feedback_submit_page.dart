import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../attachment/default_attachment_picker.dart';
import '../feedmatter_ui_helpers.dart';
import '../feedmatter_ui_options.dart';
import '../theme/feedmatter_ui_theme.dart';
import '../widgets/feedmatter_attachment_picker_grid.dart';

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

  static const _types = [
    fm.FeedbackType.advice,
    fm.FeedbackType.error,
    fm.FeedbackType.ask,
    fm.FeedbackType.help,
    fm.FeedbackType.other,
  ];

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
    final theme = FeedMatterUiTheme.of(context);
    final canPickAttachments = config.feedbackAttachmentEnabled &&
        (widget.options.onPickAttachments != null ||
            widget.options.useDefaultAttachmentPicker);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '提交反馈',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (!config.feedbackEnabled)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('当前项目已关闭反馈发布'),
            ),
          _SectionLabel(text: '反馈类型'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _types)
                _TypePill(
                  label: feedbackTypeLabel(type),
                  selected: _selectedType == type,
                  onTap: () => setState(() => _selectedType = type),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(text: '文字描述'),
          const SizedBox(height: 10),
          TextField(
            controller: _contentController,
            minLines: 6,
            maxLines: 10,
            maxLength: config.feedbackMaxContentLength,
            style: TextStyle(color: theme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: config.feedbackPrompt ?? '请描述你的问题或建议...',
              hintStyle: TextStyle(color: theme.textSecondary),
              filled: true,
              fillColor: theme.surfaceColor,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primaryBlue, width: 1.5),
              ),
            ),
          ),
          if (canPickAttachments) ...[
            const SizedBox(height: 24),
            _SectionLabel(text: '添加附件'),
            const SizedBox(height: 10),
            FeedMatterAttachmentPickerGrid(
              attachments: _attachments,
              picking: _pickingAttachments,
              enabled: !_submitting,
              onAdd: _pickAttachments,
              onRemove: _submitting
                  ? null
                  : (attachment) {
                      setState(() {
                        _attachments = _attachments
                            .where((item) => item != attachment)
                            .toList();
                      });
                    },
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting || !config.feedbackEnabled ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryBlue,
                disabledBackgroundColor: theme.primaryBlue.withAlpha(128),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '提交反馈',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Text(
      text,
      style: TextStyle(
        color: theme.textSecondary,
        fontSize: 14,
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    return Material(
      color: selected
          ? theme.primaryBlue.withAlpha(31)
          : theme.inputBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? theme.primaryBlue : theme.textPrimary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
