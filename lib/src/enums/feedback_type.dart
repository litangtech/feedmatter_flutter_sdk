import 'package:json_annotation/json_annotation.dart';
/// 反馈类型
@JsonEnum(valueField: 'value')
enum FeedbackType {
  /// 建议
  advice('ADVICE'),

  /// 错误
  error('ERROR'),

  /// 咨询
  ask('ASK'),

  /// 紧急求助
  help('HELP'),

  /// 公告
  notice('NOTICE'),

  /// 其他
  other('OTHER');

  final String value;
  const FeedbackType(this.value);

  static FeedbackType? fromValue(String? value) {
    if (value == null) return null;
    return FeedbackType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FeedbackType.other,
    );
  }

  String toJson() => value;

  @override
  String toString() => value;
} 