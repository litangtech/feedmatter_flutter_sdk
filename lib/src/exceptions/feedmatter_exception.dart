/// 常用错误码
class FeedMatterErrorCode {
  static const String userBanned = 'USER_BANNED';
}

/// FeedMatter SDK 异常基类
class FeedMatterException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  bool get isUserBanned => code == FeedMatterErrorCode.userBanned;

  FeedMatterException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'FeedMatterException: $message${code != null ? ' (code: $code)' : ''}';
}

/// API 请求异常
class FeedMatterApiException extends FeedMatterException {
  final int? statusCode;

  FeedMatterApiException(
    String message, {
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'FeedMatterApiException: $message (status: $statusCode${code != null ? ', code: $code' : ''})';
}

/// 配置错误异常
class FeedMatterConfigException extends FeedMatterException {
  FeedMatterConfigException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 认证错误异常
class FeedMatterAuthException extends FeedMatterException {
  FeedMatterAuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
} 