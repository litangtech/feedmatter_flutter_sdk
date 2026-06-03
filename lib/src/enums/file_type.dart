import 'package:json_annotation/json_annotation.dart';

/// 文件类型
@JsonEnum(valueField: 'value')
enum FileType {
  /// 图片
  img('IMG'),

  /// 视频
  vid('VID'),

  /// 文档
  doc('DOC'),

  /// 文本
  txt('TXT'),

  /// 反馈引用
  fref('FREF'),

  /// 评论引用
  cref('CREF');

  final String value;
  const FileType(this.value);

  // Backend value aliases for callers that prefer API enum names.
  // ignore: constant_identifier_names
  static const FileType IMG = img;
  // ignore: constant_identifier_names
  static const FileType VID = vid;
  // ignore: constant_identifier_names
  static const FileType DOC = doc;
  // ignore: constant_identifier_names
  static const FileType TXT = txt;
  // ignore: constant_identifier_names
  static const FileType FREF = fref;
  // ignore: constant_identifier_names
  static const FileType CREF = cref;
}
