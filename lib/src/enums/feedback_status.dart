import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum FeedbackStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED'),
  hidden('HIDDEN'),
  deleted('DELETED');

  final String value;

  const FeedbackStatus(this.value);

  bool get isPublic => this != hidden && this != deleted && this != pending;
} 