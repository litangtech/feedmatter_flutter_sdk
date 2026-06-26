import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

/// Horizontal attachment preview strip above the comment input bar.
class FeedMatterCommentAttachmentStrip extends StatelessWidget {
  final List<fm.Attachment> attachments;
  final int maxCount;
  final bool picking;
  final bool enabled;
  final VoidCallback? onAdd;
  final ValueChanged<fm.Attachment>? onRemove;

  const FeedMatterCommentAttachmentStrip({
    super.key,
    required this.attachments,
    required this.maxCount,
    this.picking = false,
    this.enabled = true,
    this.onAdd,
    this.onRemove,
  });

  static const tileSize = 56.0;
  static const stripHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = FeedMatterUiTheme.of(context);
    final canAdd = onAdd != null && attachments.length < maxCount;

    return SizedBox(
      height: stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: attachments.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (canAdd && index == attachments.length) {
            return _CompactAddTile(
              onTap: enabled && !picking ? onAdd : null,
              picking: picking,
              theme: theme,
            );
          }
          final attachment = attachments[index];
          return _StripAttachmentTile(
            attachment: attachment,
            onRemove: enabled && onRemove != null
                ? () => onRemove!(attachment)
                : null,
          );
        },
      ),
    );
  }
}

class _StripAttachmentTile extends StatelessWidget {
  final fm.Attachment attachment;
  final VoidCallback? onRemove;

  const _StripAttachmentTile({
    required this.attachment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final url = attachment.fileUrl;
    return SizedBox(
      width: FeedMatterCommentAttachmentStrip.tileSize,
      height: FeedMatterCommentAttachmentStrip.tileSize,
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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
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
        child: Icon(Icons.insert_drive_file_outlined, color: Colors.grey, size: 20),
      ),
    );
  }
}

class _CompactAddTile extends StatelessWidget {
  final VoidCallback? onTap;
  final bool picking;
  final FeedMatterUiTheme theme;

  const _CompactAddTile({
    required this.onTap,
    required this.picking,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: FeedMatterCommentAttachmentStrip.tileSize,
          height: FeedMatterCommentAttachmentStrip.tileSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: picking
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(
                  Icons.add_photo_alternate_outlined,
                  color: theme.textSecondary,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
