import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> loadFeedMatterInstallationMarker() async {
  final packageInfo = await PackageInfo.fromPlatform();
  if (!Platform.isAndroid && !Platform.isIOS) {
    return sha256.convert(packageInfo.packageName.codeUnits).toString();
  }

  final installTime = _readInstallTimeMicros(packageInfo);
  String platformIdentity = '';
  if (Platform.isIOS) {
    platformIdentity =
        (await DeviceInfoPlugin().iosInfo).identifierForVendor ?? '';
  }

  // 已上线版本用 packageName:installTime:platformIdentity。
  // installTime 可读时必须保持原公式，避免安装标识变化导致匿名身份被重置。
  final source = installTime != null
      ? '${packageInfo.packageName}:$installTime:$platformIdentity'
      : '${packageInfo.packageName}:$platformIdentity';
  return sha256.convert(source.codeUnits).toString();
}

/// 旧版 package_info_plus 没有 [PackageInfo.installTime]，用动态读取避免编译失败。
int? _readInstallTimeMicros(PackageInfo packageInfo) {
  try {
    final value = (packageInfo as dynamic).installTime;
    if (value is DateTime) {
      return value.toUtc().microsecondsSinceEpoch;
    }
  } catch (_) {
    // 旧插件无此字段，或平台未返回安装时间。
  }
  return null;
}
