import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> loadFeedMatterInstallationMarker() async {
  final packageInfo = await PackageInfo.fromPlatform();
  if (!Platform.isAndroid && !Platform.isIOS) {
    return sha256.convert(packageInfo.packageName.codeUnits).toString();
  }
  final installTime = packageInfo.installTime?.toUtc().microsecondsSinceEpoch;
  if (installTime == null) {
    throw StateError('无法获取应用安装时间');
  }

  String platformIdentity = '';
  if (Platform.isIOS) {
    platformIdentity =
        (await DeviceInfoPlugin().iosInfo).identifierForVendor ?? '';
  }

  final source = '${packageInfo.packageName}:$installTime:$platformIdentity';
  return sha256.convert(source.codeUnits).toString();
}
