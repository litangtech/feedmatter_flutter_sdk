import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

class FeedMatterAttachmentPickerGrid extends StatelessWidget {
  final List<fm.Attachment> attachments;
  final VoidCallback? onAdd;
  final ValueChanged<fm.Attachment>? onRemove;
  final bool picking;
  final bool enabled;

  const FeedMatterAttachmentPickerGrid({
    super.key,
    required this.attachments,
    this.onAdd,
    this.onRemove,
    this.picking = false,
    this.enabled = true,
  });

  static const _tileSize = 88.0;

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final items = <Widget>[
      for (final attachment in attachments)
        _AttachmentTile(
          attachment: attachment,
          onRemove: enabled && onRemove != null
              ? () => onRemove!(attachment)
              : null,
        ),
      if (onAdd != null)
        _AddTile(
          onTap: enabled && !picking ? onAdd : null,
          picking: picking,
          theme: theme,
        ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items,
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final fm.Attachment attachment;
  final VoidCallback? onRemove;

  const _AttachmentTile({
    required this.attachment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final url = attachment.fileUrl;
    return SizedBox(
      width: FeedMatterAttachmentPickerGrid._tileSize,
      height: FeedMatterAttachmentPickerGrid._tileSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: url != null
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _filePlaceholder(context),
                    )
                  : _filePlaceholder(context),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filePlaceholder(BuildContext context) {
    return ColoredBox(
      color: FeedMatterUiTheme.of(context).inputBackground,
      child: const Center(
        child: Icon(Icons.insert_drive_file_outlined, color: Colors.grey),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback? onTap;
  final bool picking;
  final FeedMatterUiTheme theme;

  const _AddTile({
    required this.onTap,
    required this.picking,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: FeedMatterAttachmentPickerGrid._tileSize,
          height: FeedMatterAttachmentPickerGrid._tileSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: picking
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: theme.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '选择相册',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
