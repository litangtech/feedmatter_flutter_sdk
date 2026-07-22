import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'anonymous_identity_store.dart';
import 'config.dart';
import 'constants.dart';
import 'enums/feedback_type.dart';
import 'exceptions/feedmatter_exception.dart';
import 'models/attachment.dart';
import 'models/client_info.dart';
import 'models/comment.dart';
import 'models/faq_list_response.dart';
import 'models/feedback.dart';
import 'models/main_comment_with_replies.dart';
import 'models/page.dart';
import 'models/paged_replies.dart';
import 'models/project_config.dart';

/// FeedMatter SDK 客户端
class FeedMatterClient {
  static const String _imageStyleSmall240 = '-small480.webp';
  static const String _imageStyleOriginal = '-original.webp';

  FeedMatterConfig? config;
  FeedMatterUser? _user;
  Dio? _dio;
  final AnonymousIdentityStore _anonymousIdentityStore =
      AnonymousIdentityStore();
  Future<void>? _identityResetFuture;
  int _identityVersion = 0;
  final Set<Future<void>> _registeredRequests = {};
  void Function(FeedMatterException)? onError;

  // 私有静态实例
  static FeedMatterClient? _instance;

  // 私有构造函数
  FeedMatterClient._();

  // 工厂构造方法
  factory FeedMatterClient() {
    _instance ??= FeedMatterClient._();
    return _instance!;
  }

  // 获取实例的静态方法
  static FeedMatterClient get instance {
    _instance ??= FeedMatterClient._();
    return _instance!;
  }

  void init(
    FeedMatterConfig config,
    FeedMatterUser user, {
    void Function(FeedMatterException)? onError,
  }) {
    final nextUser = user.userId.trim().isEmpty ? null : user;
    _identityVersion += 1;
    _rotateIfLeavingRegisteredIdentity(nextUser);
    this.config = config;
    _user = nextUser;
    this.onError = onError;
    _dio = null;

    if (config.debug) {
      //打印配置信息
      _debugLog('FeedMatterConfig: $config');
      _debugLog('FeedMatterUser: $_user');
    }
  }

  /// 初始化 SDK。省略 [user] 时使用持久化的匿名安装身份。
  Future<void> initialize(
    FeedMatterConfig config, {
    FeedMatterUser? user,
    void Function(FeedMatterException)? onError,
  }) async {
    final nextUser =
        user != null && user.userId.trim().isNotEmpty ? user : null;
    _identityVersion += 1;
    _rotateIfLeavingRegisteredIdentity(nextUser);
    this.config = config;
    _user = nextUser;
    this.onError = onError;
    _dio = null;
    if (_user == null) {
      await _getAnonymousId(config, registered: false);
    }
  }

  /// 设置登录用户；空白 userId 会恢复匿名身份。
  void setUser(FeedMatterUser user) {
    final nextUser = user.userId.trim().isEmpty ? null : user;
    _identityVersion += 1;
    _rotateIfLeavingRegisteredIdentity(nextUser);
    _user = nextUser;
  }

  Dio getDio() {
    _dio ??= _createDio();
    return _dio!;
  }

  Dio _createDio() {
    final currentConfig = config;
    if (currentConfig == null) {
      throw FeedMatterConfigException(
        '请先调用 init 方法设置配置信息',
        code: 'CONFIG_NOT_SET',
      );
    }
    var dio = Dio(BaseOptions(
      baseUrl: currentConfig.baseUrl,
      connectTimeout: Duration(seconds: currentConfig.timeout),
      receiveTimeout: Duration(seconds: currentConfig.timeout),
      headers: _baseHeadersFor(currentConfig),
    ));

    if (currentConfig.debug) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: true,
        logPrint: (object) =>
            developer.log(object.toString(), name: 'FeedMatter'),
      ));
    }
    // 添加错误处理拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        if (e.response != null) {
          final response = e.response!;
          Map<String, dynamic> errorBody = {};
          String message = '请求失败';
          String? code;

          try {
            // 尝试将响应解析为 JSON
            if (response.data is Map) {
              errorBody = response.data as Map<String, dynamic>;
              message = errorBody['message'] as String? ?? '请求失败';
              final rawCode = errorBody['code'];
              code = rawCode?.toString();
            } else if (response.data is String) {
              // 处理响应为普通字符串的情况（通常是服务器的错误堆栈）
              final String responseText = response.data as String;
              // 对于其他类型的错误，保存原始响应文本
              message = response.statusCode == 500 ? '服务器内部错误' : '请求失败';
              errorBody = {'message': message, 'rawResponse': responseText};
            }
          } catch (extractionError) {
            if (config?.debug ?? false) {
              _debugLog('Error extracting error details: $extractionError');
            }
            errorBody = {'message': message, 'originalError': e.toString()};
          }

          if (config?.debug ?? false) {
            _debugLog('FeedMatter API Error:');
            _debugLog('Status Code: ${response.statusCode}');
            _debugLog('Error Message: $message');
            _debugLog(
                'Headers: ${_redactHeaders(response.requestOptions.headers)}');
            _debugLog('URL: ${response.requestOptions.uri}');
            _debugLog('Method: ${response.requestOptions.method}');
            _debugLog('Error Body: $errorBody');
          }

          final error = response.statusCode == 401 || response.statusCode == 403
              ? FeedMatterAuthException(
                  message,
                  code: code,
                  originalError: errorBody,
                )
              : FeedMatterApiException(
                  message,
                  statusCode: response.statusCode,
                  code: code,
                  originalError: errorBody,
                );

          onError?.call(error);
          handler.reject(DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: error,
          ));
          return;
        }

        final error = FeedMatterApiException(
          '网络请求失败',
          statusCode: 0,
          code: 'NETWORK_ERROR',
          originalError: e,
        );
        onError?.call(error);
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: error,
        ));
      },
    ));
    return dio;
  }

  /// 清除用户信息
  void clearUser() {
    _identityVersion += 1;
    _rotateIfLeavingRegisteredIdentity(null);
    _user = null;
  }

  void _rotateIfLeavingRegisteredIdentity(FeedMatterUser? nextUser) {
    final previousUser = _user;
    if (previousUser == null ||
        previousUser.userId.trim().isEmpty ||
        previousUser.userId == nextUser?.userId) {
      return;
    }
    final previousReset = _identityResetFuture;
    final registeredRequests = List<Future<void>>.of(_registeredRequests);
    late final Future<void> pending;
    pending = _resetClaimedAnonymousIdentities(
      previousReset,
      registeredRequests,
    );
    _identityResetFuture = pending;
    pending.whenComplete(() {
      if (identical(_identityResetFuture, pending)) {
        _identityResetFuture = null;
      }
    }).catchError((Object _) {});
    pending.catchError((Object _) {});
  }

  Future<void> _resetClaimedAnonymousIdentities(
    Future<void>? previousReset,
    List<Future<void>> registeredRequests,
  ) async {
    if (previousReset != null) {
      try {
        await previousReset;
      } catch (_) {
        // 上一次轮换失败时仍允许重试。
      }
    }
    await Future.wait(registeredRequests);
    await _anonymousIdentityStore.rotateAllClaimed();
  }

  String _getAppType() {
    var value = Platform.operatingSystem.toUpperCase();
    if (Platform.operatingSystem == 'ohos') {
      return 'Harmony'.toUpperCase();
    }
    return value;
  }

  /// 获取设备和应用信息
  Future<ClientInfo> _getClientInfo([FeedMatterConfig? configSnapshot]) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();

    String? deviceModel;
    String? deviceBrand;
    String? deviceSysVersion; //版本名称
    String? deviceSysVersionInt; //版本号

    // 获取设备信息
    if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceModel = iosInfo.model;
      deviceBrand = iosInfo.name;
      deviceSysVersion = iosInfo.systemName;
      deviceSysVersionInt = iosInfo.systemVersion;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceModel = androidInfo.model;
      deviceBrand = androidInfo.brand;
      deviceSysVersion = androidInfo.version.release;
      deviceSysVersionInt = androidInfo.version.sdkInt.toString();
    } else if (Platform.isMacOS) {
      final macOsInfo = await deviceInfoPlugin.macOsInfo;
      deviceModel = macOsInfo.model;
      deviceBrand = 'Apple';
      deviceSysVersion = macOsInfo.osRelease;
      deviceSysVersionInt = macOsInfo.majorVersion.toString();
    } else if (Platform.operatingSystem == 'ohos') {
    } else if (Platform.isWindows) {
      final winInfo = await deviceInfoPlugin.windowsInfo;
      deviceModel = winInfo.productName;
      deviceSysVersion = '${winInfo.displayVersion} ${winInfo.csdVersion}';
      deviceSysVersionInt = '${winInfo.majorVersion}';
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfoPlugin.linuxInfo;
      deviceModel = linuxInfo.prettyName;
      deviceBrand = linuxInfo.name;
      deviceSysVersion = linuxInfo.version;
      deviceSysVersionInt = linuxInfo.versionCodename;
    }

    return ClientInfo(
      appVersionCode: int.tryParse(packageInfo.buildNumber) ?? 0,
      appVersionName: packageInfo.version,
      appPackage: packageInfo.packageName,
      appType: _getAppType(),
      appMarket: (configSnapshot ?? config)?.appMarket,
      deviceModel: deviceModel,
      deviceBrand: deviceBrand,
      deviceSysVersion: deviceSysVersion,
      deviceSysVersionInt: deviceSysVersionInt,
    );
  }

  Map<String, String> _baseHeadersFor(FeedMatterConfig currentConfig) {
    return {
      'X-API-Key': currentConfig.apiKey,
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _identityHeaders(
    FeedMatterUser? initialUser,
    FeedMatterConfig requestConfig,
  ) async {
    final user = initialUser;
    String? anonymousId;
    try {
      anonymousId = await _getAnonymousId(
        requestConfig,
        registered: user != null && user.userId.trim().isNotEmpty,
      );
    } catch (_) {
      if (user != null && user.userId.trim().isNotEmpty) {
        return _userHeaders(user);
      }
      rethrow;
    }
    if (user != null && user.userId.trim().isNotEmpty) {
      return {
        ..._userHeaders(user),
        if (anonymousId != null) 'X-Anonymous-Id': anonymousId,
      };
    }
    return {
      // 兼容仍强制要求 X-User-Id Header 的旧服务端。
      'X-User-Id': '',
      'X-Anonymous-Id': anonymousId!,
    };
  }

  Map<String, dynamic> _userHeaders(FeedMatterUser user) {
    return {
      'X-User-Id': user.userId,
      'X-User-Name': Uri.encodeComponent(user.userName),
      if (user.userAvatar != null)
        'X-User-Avatar': Uri.encodeComponent(user.userAvatar!),
    };
  }

  Future<String?> _getAnonymousId(
    FeedMatterConfig currentConfig, {
    required bool registered,
  }) async {
    final reset = _identityResetFuture;
    if (reset != null) {
      await reset;
    }
    final namespace = _anonymousNamespace(currentConfig);
    return registered
        ? _anonymousIdentityStore.getForRegistered(namespace)
        : _anonymousIdentityStore.getForAnonymous(namespace);
  }

  String _anonymousNamespace(FeedMatterConfig currentConfig) {
    return sha256
        .convert(utf8.encode(currentConfig.apiKey))
        .toString()
        .substring(0, 32);
  }

  Future<T> _handleResponse<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      // 处理新的响应格式
      if (response.data is Map) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        // 检查是否是新的统一响应格式
        if (data.containsKey('code') && data.containsKey('data')) {
          // 检查状态码
          final int code = data['code'] as int;
          if (code != 200) {
            final String message = data['message'] as String? ?? '未知错误';
            throw FeedMatterApiException(
              message,
              statusCode: code,
              code: code.toString(),
            );
          }
          // 返回 data 字段的内容
          return data['data'] as T;
        }
      }
      // 如果不是新格式，直接返回原始数据
      return response.data as T;
    } on DioException catch (e) {
      if (e.error is FeedMatterException) {
        throw e.error!;
      }
      rethrow;
    }
  }

  /// 创建反馈
  Future<Feedback> createFeedback({
    required String content,
    FeedbackType? type,
    Map<String, dynamic>? customInfo,
    List<Attachment>? attachments,
  }) async {
    final requestUser = _user;
    final requestConfig = config;
    final requestDio = getDio();
    final requestIdentityVersion = _identityVersion;
    final clientInfo = await _getClientInfo(requestConfig);
    final response = await _handleResponse(
      () => _request(
        'POST',
        '/api/v2/feedbacks',
        data: {
          'content': content,
          if (type != null) 'type': type.value,
          'clientInfo': clientInfo.toJson(),
          if (customInfo != null) 'customInfo': customInfo,
          if (attachments != null && attachments.isNotEmpty)
            'attachments': attachments.map((a) => a.toJson()).toList(),
        },
        identityUser: requestUser,
        configSnapshot: requestConfig,
        dioSnapshot: requestDio,
        identityVersion: requestIdentityVersion,
        identityCaptured: true,
      ),
    );

    return Feedback.fromJson(response);
  }

  Future<List<Feedback>> getFeedbacks({
    int page = 0,
    int size = 20,
    String? keyword,
  }) async {
    final response = await _handleResponse(
      () => _request(
        'GET',
        '/api/v2/feedbacks',
        queryParameters: {
          'page': page,
          'size': size,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        },
      ),
    );
    return (response as List).map((item) => Feedback.fromJson(item)).toList();
  }

  Future<List<Feedback>> getMyFeedbacks({
    int page = 0,
    int size = 20,
    String? keyword,
  }) async {
    final response = await _handleResponse(() => _request(
          'GET',
          '/api/v2/feedbacks/my',
          queryParameters: {
            'page': page,
            'size': size,
            if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          },
        ));

    return (response as List).map((item) => Feedback.fromJson(item)).toList();
  }

  /// 获取指定用户的反馈列表
  Future<List<Feedback>> getUserFeedbacks(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _handleResponse(() => _request(
          'GET',
          '/api/v2/feedbacks/user/$userId',
          queryParameters: {
            'page': page,
            'size': size,
          },
        ));
    return (response as List).map((item) => Feedback.fromJson(item)).toList();
  }

  /// 获取反馈详情
  Future<Feedback> getFeedback(String id) async {
    return _handleResponse(() => _request(
          'GET',
          '/api/v2/feedbacks/$id',
        )).then((json) => Feedback.fromJson(json));
  }

  Future<Comment> createComment(
    String feedbackId,
    String content, {
    List<Attachment>? attachments,
    String? parentCommentId,
  }) async {
    final requestUser = _user;
    final requestConfig = config;
    final requestDio = getDio();
    final requestIdentityVersion = _identityVersion;
    final clientInfo = await _getClientInfo(requestConfig);
    final Map<String, dynamic> data = {
      'content': content,
      'clientInfo': clientInfo.toJson(),
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toJson()).toList(),
      if (parentCommentId?.isNotEmpty ?? false) 'parentId': parentCommentId!,
    };

    return _handleResponse(() => _request(
          'POST',
          '/api/v2/feedbacks/$feedbackId/comments',
          data: data,
          identityUser: requestUser,
          configSnapshot: requestConfig,
          dioSnapshot: requestDio,
          identityVersion: requestIdentityVersion,
          identityCaptured: true,
        )).then((json) => Comment.fromJson(json));
  }

  /// 获取评论列表（楼中楼格式）
  ///
  /// [feedbackId] 反馈ID
  /// [page] 页码，从0开始
  /// [size] 每页数量
  /// [sort] 排序方式：created_asc(默认)、created_desc、reply_desc
  ///
  /// 返回分页结果，包含评论列表和分页信息
  Future<Page<MainCommentWithReplies>> getCommentsFloor(
    String feedbackId, {
    int page = 0,
    int size = 20,
    String sort = CommentSort.createdAsc,
  }) async {
    final response = await _handleResponse(() => _request(
          'GET',
          '/api/v2/feedbacks/$feedbackId/comments/floor',
          queryParameters: {
            'page': page,
            'size': size,
            'sort': sort,
          },
        ));

    return Page.fromJson(
      response,
      (json) => MainCommentWithReplies.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取主评论的回复列表（分页）
  ///
  /// [mainCommentId] 主评论ID
  /// [page] 页码，从0开始
  /// [size] 每页数量
  Future<PagedReplies> getCommentReplies(
    String mainCommentId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _handleResponse(() => _request(
          'GET',
          '/api/v2/feedbacks/comments/$mainCommentId/replies',
          queryParameters: {
            'page': page,
            'size': size,
          },
        ));

    return PagedReplies.fromJson(response);
  }

  Future<File> _compressFile(File file) async {
    final lowerPath = file.path.toLowerCase();
    if (lowerPath.endsWith(".jpg") ||
        lowerPath.endsWith(".jpeg") ||
        lowerPath.endsWith(".png") ||
        lowerPath.endsWith(".bmp") ||
        lowerPath.endsWith(".heic") ||
        lowerPath.endsWith(".heif") ||
        lowerPath.endsWith(".webp")) {
      return _compressImage(file);
    }
    return file;
  }

  Future<File> _compressImage(File sourceFile) async {
    final newPath = "${sourceFile.path}_compress.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      sourceFile.absolute.path,
      newPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      return sourceFile;
    }

    final newFile = File(result.path);
    if (config?.debug == true) {
      _debugLog(
          "FeedMatter compress image : before=${sourceFile.lengthSync()}  after=${newFile.lengthSync()}");
    }
    return newFile;
  }

  /// 验证文件
  void _validateFile(File file, {int maxSize = 40 * 1024 * 1024}) {
    // 检查文件大小（默认最大40MB）
    final size = file.lengthSync();
    if (size > maxSize) {
      throw FeedMatterApiException(
        '文件大小超过限制',
        statusCode: 0,
        code: 'FILE_TOO_LARGE',
        originalError: {'maxSize': maxSize, 'actualSize': size},
      );
    }

    // 检查文件是否存在
    if (!file.existsSync()) {
      throw FeedMatterApiException(
        '文件不存在',
        statusCode: 0,
        code: 'FILE_NOT_FOUND',
      );
    }
  }

  /// 获取安全的文件名
  String _getSafeFileName(String fileName) {
    // 移除路径分隔符和特殊字符
    final name = fileName
        .split(Platform.pathSeparator)
        .last
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '');

    // 如果文件名为空，生成随机文件名
    if (name.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'file_$timestamp';
    }

    return name;
  }

  /// 上传公开文件
  Future<String> uploadPublicFile(
    File file, {
    int? maxSize,
  }) async {
    final requestUser = _user;
    final requestConfig = config;
    final requestDio = getDio();
    final requestIdentityVersion = _identityVersion;
    _validateFile(file, maxSize: maxSize ?? 40 * 1024 * 1024);
    final compressFile = await _compressFile(file);

    try {
      final fileName = _getSafeFileName(file.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressFile.path,
          filename: fileName,
        ),
      });

      final response = await _handleResponse(() => _request(
            'POST',
            '/api/v2/upload/public',
            data: formData,
            identityUser: requestUser,
            configSnapshot: requestConfig,
            dioSnapshot: requestDio,
            identityVersion: requestIdentityVersion,
            identityCaptured: true,
          ));

      return response['url'];
    } finally {
      if (compressFile.path != file.path) {
        try {
          compressFile.deleteSync();
        } catch (e) {
          if (config?.debug == true) {
            _debugLog('Delete temp file failed: $e');
          }
        }
      }
    }
  }

  /// 上传私密文件
  Future<String> uploadPrivateFile(
    File file, {
    int? maxSize,
  }) async {
    final requestUser = _user;
    final requestConfig = config;
    final requestDio = getDio();
    final requestIdentityVersion = _identityVersion;
    _validateFile(file, maxSize: maxSize ?? 40 * 1024 * 1024);
    final compressFile = await _compressFile(file);

    try {
      final fileName = _getSafeFileName(file.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressFile.path,
          filename: fileName,
        ),
      });

      final response = await _handleResponse(() => _request(
            'POST',
            '/api/v2/upload/private',
            data: formData,
            identityUser: requestUser,
            configSnapshot: requestConfig,
            dioSnapshot: requestDio,
            identityVersion: requestIdentityVersion,
            identityCaptured: true,
          ));

      return response['url'];
    } finally {
      if (compressFile.path != file.path) {
        try {
          compressFile.deleteSync();
        } catch (e) {
          if (config?.debug == true) {
            _debugLog('Delete temp file failed: $e');
          }
        }
      }
    }
  }

  /// 获取私密文件的签名URL
  Future<String> getSignedUrl(String key) async {
    final response = await _handleResponse(() => _request(
          'GET',
          '/api/v2/upload/private/$key',
        ));
    return response['url'];
  }

  /// 切换点赞状态
  /// 返回更新后的反馈信息
  Future<Feedback> toggleLike(String feedbackId) async {
    final response = await _handleResponse(
      () => _request('POST', '/api/v2/feedbacks/$feedbackId/like'),
    );
    return Feedback.fromJson(response);
  }

  /// Get project configuration
  Future<ProjectConfig> getProjectConfig() async {
    final response = await _handleResponse(
      () => _request(
        'GET',
        '/api/v2/projects/config',
      ),
    );
    return ProjectConfig.fromJson(response);
  }

  // 每次请求生成签名
  String _generateSignature(
    String timestamp,
    String method,
    String path,
    Map<String, dynamic>? params,
    FeedMatterConfig requestConfig,
  ) {
    // 如果没有参数，使用空 Map
    final signParams = params ?? {};

    Map<String, dynamic> convertedParams;
    if (method == 'GET') {
      // 对于 GET 请求，确保所有值都是字符串类型
      convertedParams =
          signParams.map((key, value) => MapEntry(key, value.toString()));
    } else {
      convertedParams = signParams;
    }
    // 参数排序
    final Map<String, dynamic> sortedParams = Map.fromEntries(
        convertedParams.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)));
    //记得 json encode，这样后端的读取也一致
    final paramsJson = json.encode(sortedParams);

    // 确保路径以 / 开头
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // 按照固定规则拼接字符串
    final String stringToSign =
        '$method\n$normalizedPath\n$timestamp\n$paramsJson';

    if (requestConfig.debug) {
      _debugLog('String to sign: $stringToSign');
    }

    // 使用 apiSecret 进行 HMAC-SHA256 签名
    final hmac = Hmac(sha256, utf8.encode(requestConfig.apiSecret));
    final digest = hmac.convert(utf8.encode(stringToSign));
    return base64.encode(digest.bytes);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'x-api-key' ||
          lowerKey == 'x-signature' ||
          lowerKey == 'x-anonymous-id' ||
          lowerKey == 'authorization') {
        return MapEntry(key, _maskHeaderValue(value));
      }
      return MapEntry(key, value);
    });
  }

  String _maskHeaderValue(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      return '';
    }
    if (text.length <= 8) {
      return '****';
    }
    return '${text.substring(0, 4)}****${text.substring(text.length - 4)}';
  }

  void _debugLog(String message) {
    if (config?.debug == true) {
      developer.log(message, name: 'FeedMatter');
    }
  }

  Future<Response> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    FeedMatterUser? identityUser,
    FeedMatterConfig? configSnapshot,
    Dio? dioSnapshot,
    int? identityVersion,
    bool identityCaptured = false,
  }) async {
    final requestConfig = identityCaptured ? configSnapshot : config;
    if (requestConfig == null) {
      throw FeedMatterConfigException(
        '请先调用 init 方法设置配置信息',
        code: 'CONFIG_NOT_SET',
      );
    }
    final requestDio = identityCaptured ? dioSnapshot! : getDio();
    final requestUser = identityCaptured ? identityUser : _user;
    final requestIdentityVersion =
        identityCaptured ? identityVersion! : _identityVersion;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    Map<String, dynamic>? signParams;
    if (method == 'GET') {
      signParams = queryParameters;
    } else {
      if (data is Map<String, dynamic>) {
        signParams = data;
      } else if (data is FormData) {
        signParams = {};
      }
    }

    final signature =
        _generateSignature(timestamp, method, path, signParams, requestConfig);

    final identityAwareRequest = _usesClientIdentity(path);
    var requestHeaders =
        Map<String, dynamic>.from(_baseHeadersFor(requestConfig));
    if (identityAwareRequest) {
      requestHeaders.addAll(
        await _identityHeaders(requestUser, requestConfig),
      );
    }
    if (requestIdentityVersion != _identityVersion) {
      throw FeedMatterConfigException(
        '请求准备期间用户或项目已切换，请重试',
        code: 'IDENTITY_CHANGED',
      );
    }
    requestHeaders['X-Timestamp'] = timestamp;
    requestHeaders['X-Signature'] = signature;

    if (requestConfig.debug) {
      _debugLog('Request headers: ${_redactHeaders(requestHeaders)}');
      _debugLog('Request sign params: $signParams');
      _debugLog('Request params: $data');
      _debugLog('Timestamp: $timestamp');
    }

    final registeredRequest = identityAwareRequest &&
        requestUser != null &&
        requestUser.userId.trim().isNotEmpty;
    Completer<void>? requestCompleted;
    Future<void>? requestCompletion;
    if (registeredRequest) {
      requestCompleted = Completer<void>();
      requestCompletion = requestCompleted.future;
      _registeredRequests.add(requestCompletion);
    }
    try {
      final response = await requestDio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: requestHeaders,
        ),
      );
      await _handleAnonymousClaimResponse(
        response,
        registeredRequest,
        requestHeaders,
        requestConfig,
      );
      return response;
    } on DioException catch (error) {
      final response = error.response;
      if (response != null && !registeredRequest) {
        await _handleAnonymousClaimResponse(
          response,
          registeredRequest,
          requestHeaders,
          requestConfig,
        );
      }
      rethrow;
    } finally {
      if (registeredRequest) {
        requestCompleted!.complete();
        _registeredRequests.remove(requestCompletion);
      }
    }
  }

  bool _usesClientIdentity(String path) {
    return path.startsWith('/api/v1/feedbacks') ||
        path.startsWith('/api/v2/feedbacks');
  }

  Future<void> _handleAnonymousClaimResponse(
    Response response,
    bool registeredRequest,
    Map<String, dynamic> requestHeaders,
    FeedMatterConfig requestConfig,
  ) async {
    if (response.headers.value('X-Anonymous-Claimed') != 'true') {
      return;
    }
    final namespace = _anonymousNamespace(requestConfig);
    if (registeredRequest) {
      await _anonymousIdentityStore.markClaimed(namespace);
      return;
    }
    final anonymousId = requestHeaders['X-Anonymous-Id']?.toString();
    if (anonymousId != null) {
      await _anonymousIdentityStore.invalidateIfCurrent(namespace, anonymousId);
    }
  }

  /// 获取常见问题列表（带版本检查）
  ///
  /// [version] 客户端缓存的版本号，首次传 "0"
  /// 若服务端版本与 [version] 一致，返回的 items 为空列表
  Future<FaqListResponse> getFaqList({String version = '0'}) async {
    final response = await _handleResponse(
      () => _request(
        'GET',
        '/api/v1/faq',
        queryParameters: {
          'version': version,
        },
      ),
    );
    return FaqListResponse.fromJson(response);
  }

  //根据传入的图片 url，获取缩略图 url
  static String getImageThumbnailUrl(String url,
      {String style = _imageStyleSmall240}) {
    final index = url.indexOf('?');
    if (index != -1) {
      final baseUrl = url.substring(0, index);
      final query = url.substring(index + 1);
      return '$baseUrl$style?$query';
    }
    return "$url$style";
  }

  static String getImageOriginalUrl(String url) =>
      getImageThumbnailUrl(url, style: _imageStyleOriginal);
}
