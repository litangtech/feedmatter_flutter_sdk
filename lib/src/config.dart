class FeedMatterConfig {
  /// API 服务器地址
  final String baseUrl;

  /// API Key
  final String apiKey;

  /// API Secret
  final String apiSecret;

  /// 应用渠道
  final String? appMarket;

  /// 是否启用调试模式
  final bool debug;

  /// 超时时间（秒）
  final int timeout;

  const FeedMatterConfig({
    this.baseUrl = 'https://fmapi.litangkj.com',
    required this.apiKey,
    required this.apiSecret,
    required this.appMarket,
    this.debug = false,
    this.timeout = 30,
  });

  @override
  String toString() {
    return 'FeedMatterConfig(baseUrl: $baseUrl, apiKey: $apiKey, apiSecret: $apiSecret, appMarket: $appMarket, debug: $debug, timeout: $timeout)';
  }
}

class FeedMatterUser {
  final String userId;
  final String userName;
  final String? userAvatar;

  FeedMatterUser({
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  String toString() {
    return 'FeedMatterUser(userId: $userId, userName: $userName, userAvatar: $userAvatar)';
  }
}
