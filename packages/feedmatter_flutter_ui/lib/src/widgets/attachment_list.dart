import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter/material.dart';

class FeedMatterAttachmentList extends StatelessWidget {
  final List<fm.Attachment> attachments;

  const FeedMatterAttachmentList({
    super.key,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final images = attachments
        .where((item) => item.fileType == fm.FileType.IMG && item.fileUrl != null)
        .toList();
    final others = attachments
        .where((item) => item.fileType != fm.FileType.IMG || item.fileUrl == null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('附件', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (images.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final attachment = images[index];
              return _ImageAttachmentTile(
                attachment: attachment,
                onTap: () => _openImagePreview(context, attachment),
              );
            },
          ),
          if (others.isNotEmpty) const SizedBox(height: 8),
        ],
        for (final attachment in others) _FileAttachmentTile(attachment: attachment),
      ],
    );
  }

  void _openImagePreview(BuildContext context, fm.Attachment attachment) {
    final url = attachment.fileUrl;
    if (url == null) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('图片加载失败'),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageAttachmentTile extends StatelessWidget {
  final fm.Attachment attachment;
  final VoidCallback onTap;

  const _ImageAttachmentTile({
    required this.attachment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = attachment.fileUrl;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: url == null
            ? const Center(child: Icon(Icons.broken_image_outlined))
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
      ),
    );
  }
}

class _FileAttachmentTile extends StatelessWidget {
  final fm.Attachment attachment;

  const _FileAttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(_fileIcon(attachment.fileType), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(fm.FileType type) {
    switch (type) {
      case fm.FileType.VID:
        return Icons.videocam_outlined;
      case fm.FileType.TXT:
        return Icons.description_outlined;
      case fm.FileType.FREF:
      case fm.FileType.CREF:
        return Icons.link;
      case fm.FileType.DOC:
      case fm.FileType.IMG:
        return Icons.insert_drive_file_outlined;
    }
  }
}
