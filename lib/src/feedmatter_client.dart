import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    this.config = config;
    _user = user;
    this.onError = onError;

    if (config.debug) {
      //打印配置信息
      print('FeedMatterConfig: $config');
      print('FeedMatterUser: $_user');
    }
  }

  Dio getDio() {
    _dio ??= _createDio();
    return _dio!;
  }

  Dio _createDio() {
    if (config == null) {
      throw FeedMatterConfigException(
        '请先调用 init 方法设置配置信息',
        code: 'CONFIG_NOT_SET',
      );
    }
    var dio = Dio(BaseOptions(
      baseUrl: config!.baseUrl,
      connectTimeout: Duration(seconds: config!.timeout),
      receiveTimeout: Duration(seconds: config!.timeout),
      headers: _headers,
    ));

    if (config!.debug) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
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
              code = errorBody['code'] as String?;
            } else if (response.data is String) {
              // 处理响应为普通字符串的情况（通常是服务器的错误堆栈）
              final String responseText = response.data as String;
              // 对于其他类型的错误，保存原始响应文本
              message = response.statusCode == 500 ? '服务器内部错误' : '请求失败';
              errorBody = {'message': message, 'rawResponse': responseText};
            }
          } catch (extractionError) {
            if (config?.debug ?? false) {
              print('Error extracting error details: $extractionError');
            }
            errorBody = {'message': message, 'originalError': e.toString()};
          }

          if (config?.debug ?? false) {
            print('FeedMatter API Error:');
            print('Status Code: ${response.statusCode}');
            print('Error Message: $message');
            print('Headers: ${response.requestOptions.headers}');
            print('URL: ${response.requestOptions.uri}');
            print('Method: ${response.requestOptions.method}');
            print('Error Body: $errorBody');
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
    _user = null;
    // 移除用户相关的 headers
    _dio?.options.headers.remove('X-User-Id');
    _dio?.options.headers.remove('X-User-Name');
    _dio?.options.headers.remove('X-User-Avatar');
  }

  String _getAppType() {
    var value = Platform.operatingSystem.toUpperCase();
    if (value == 'OHOS') {
      return 'HARMONY';
    }
    return value;
  }

  /// 获取设备和应用信息
  Future<ClientInfo> _getClientInfo() async {
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
      appMarket: config?.appMarket,
      deviceModel: deviceModel,
      deviceBrand: deviceBrand,
      deviceSysVersion: deviceSysVersion,
      deviceSysVersionInt: deviceSysVersionInt,
    );
  }

  Map<String, String> get _headers {
    if (_user == null || config == null) {
      throw FeedMatterConfigException(
        '请先调用 init 方法设置配置信息',
        code: 'CONFIG_NOT_SET',
      );
    }
    return {
      'X-API-Key': config!.apiKey,
      'X-User-Id': _user!.userId,
      'X-User-Name': Uri.encodeComponent(_user!.userName),
      if (_user!.userAvatar != null)
        'X-User-Avatar': Uri.encodeComponent(_user!.userAvatar!),
      'Content-Type': 'application/json',
    };
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
    final clientInfo = await _getClientInfo();
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
    final clientInfo = await _getClientInfo();
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
      print(
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
  Future<String> uploadPublicFile(File file) async {
    _validateFile(file);
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
          ));

      return response['url'];
    } finally {
      if (compressFile.path != file.path) {
        try {
          compressFile.deleteSync();
        } catch (e) {
          if (config?.debug == true) {
            print('Delete temp file failed: $e');
          }
        }
      }
    }
  }

  /// 上传私密文件
  Future<String> uploadPrivateFile(File file) async {
    _validateFile(file);
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
          ));

      return response['key'];
    } finally {
      if (compressFile.path != file.path) {
        try {
          compressFile.deleteSync();
        } catch (e) {
          if (config?.debug == true) {
            print('Delete temp file failed: $e');
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
  String _generateSignature(String timestamp, String method, String path,
      Map<String, dynamic>? params) {
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

    if (config?.debug == true) {
      print('String to sign: $stringToSign');
    }

    // 使用 apiSecret 进行 HMAC-SHA256 签名
    final hmac = Hmac(sha256, utf8.encode(config!.apiSecret));
    final digest = hmac.convert(utf8.encode(stringToSign));
    return base64.encode(digest.bytes);
  }

  Future<Response> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 根据请求类型选择要签名的参数
    Map<String, dynamic>? signParams;
    if (method == 'GET') {
      signParams = queryParameters;
    } else {
      // POST/PUT 等请求
      if (data is Map<String, dynamic>) {
        signParams = data;
      } else if (data is FormData) {
        // 对于文件上传，使用空对象进行签名
        signParams = {};
      }
    }

    final signature = _generateSignature(timestamp, method, path, signParams);

    var requestHeaders = _headers;
    requestHeaders['X-Timestamp'] = timestamp;
    requestHeaders['X-Signature'] = signature;

    if (config?.debug == true) {
      print('Request headers: $requestHeaders');
      print('Request sign params: $signParams');
      print('Request params: $data');
      print('Timestamp: $timestamp');
    }

    return getDio().request(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        method: method,
        headers: requestHeaders,
      ),
    );
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
