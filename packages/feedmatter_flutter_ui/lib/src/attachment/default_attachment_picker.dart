import 'dart:io';

import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:file_picker/file_picker.dart' as fp;

/// 内置附件选择结果。
class PickAttachmentsResult {
  const PickAttachmentsResult({
    required this.attachments,
    this.warning,
  });

  final List<fm.Attachment> attachments;
  final String? warning;
}

/// 根据文件名推断 FeedMatter 文件类型。
fm.FileType inferFileType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  const imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
  };
  const videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
  };

  if (imageExtensions.contains(ext)) {
    return fm.FileType.IMG;
  }
  if (videoExtensions.contains(ext)) {
    return fm.FileType.VID;
  }
  if (ext == 'txt') {
    return fm.FileType.TXT;
  }
  return fm.FileType.DOC;
}

/// 使用系统文件选择器选文件，校验大小后上传至公开存储。
Future<PickAttachmentsResult> pickAndUploadAttachments({
  required fm.ProjectConfig config,
  required int remainingSlots,
}) async {
  if (remainingSlots <= 0) {
    return PickAttachmentsResult(
      attachments: const [],
      warning: '最多只能添加 ${config.maxAttachments} 个附件',
    );
  }

  final pickResult = await fp.FilePicker.pickFiles(
    type: fp.FileType.any,
  );
  if (pickResult == null || pickResult.files.isEmpty) {
    return const PickAttachmentsResult(attachments: []);
  }

  var platformFiles = pickResult.files;
  String? warning;
  if (platformFiles.length > remainingSlots) {
    platformFiles = platformFiles.take(remainingSlots).toList();
    warning = '最多还能添加 $remainingSlots 个附件，已忽略多余文件';
  }

  final attachments = <fm.Attachment>[];
  for (final platformFile in platformFiles) {
    final file = await _resolveUploadFile(platformFile);
    final isTempFile = platformFile.path == null;
    try {
      final size = platformFile.size > 0 ? platformFile.size : file.lengthSync();
      if (size > config.maxUploadFileSize) {
        final maxMb = (config.maxUploadFileSize / 1024 / 1024).round();
        throw Exception('${platformFile.name} 超过 ${maxMb}MB 大小限制');
      }

      final url = await fm.FeedMatterClient.instance.uploadPublicFile(
        file,
        maxSize: config.maxUploadFileSize,
      );
      attachments.add(
        fm.Attachment(
          fileName: platformFile.name,
          fileUrl: url,
          fileType: inferFileType(platformFile.name),
        ),
      );
    } finally {
      if (isTempFile) {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }
    }
  }

  return PickAttachmentsResult(
    attachments: attachments,
    warning: warning,
  );
}

Future<File> _resolveUploadFile(fp.PlatformFile platformFile) async {
  if (platformFile.path != null) {
    return File(platformFile.path!);
  }

  final bytes = await platformFile.readAsBytes();
  final tempFile = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}${platformFile.name}',
  );
  await tempFile.writeAsBytes(bytes, flush: true);
  return tempFile;
}
