import 'package:json_annotation/json_annotation.dart';

part 'client_info.g.dart';

@JsonSerializable()
class ClientInfo {
  //App 信息
  final int appVersionCode;
  final String appVersionName;
  final String appPackage;
  final String appType;
  final String? appMarket; // 应用渠道

  //设备信息
  final String? deviceModel;
  final String? deviceBrand;
  final String? deviceSysVersion;//版本名称
  final String? deviceSysVersionInt;//版本号

  const ClientInfo({
    required this.appVersionCode,
    required this.appVersionName,
    required this.appPackage,
    required this.appType,
    this.appMarket,
    this.deviceModel,
    this.deviceBrand,
    this.deviceSysVersion,
    this.deviceSysVersionInt,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) => _$ClientInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ClientInfoToJson(this);
} 