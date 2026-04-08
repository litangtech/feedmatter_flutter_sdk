// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientInfo _$ClientInfoFromJson(Map<String, dynamic> json) => ClientInfo(
      appVersionCode: (json['appVersionCode'] as num).toInt(),
      appVersionName: json['appVersionName'] as String,
      appPackage: json['appPackage'] as String,
      appType: json['appType'] as String,
      appMarket: json['appMarket'] as String?,
      deviceModel: json['deviceModel'] as String?,
      deviceBrand: json['deviceBrand'] as String?,
      deviceSysVersion: json['deviceSysVersion'] as String?,
      deviceSysVersionInt: json['deviceSysVersionInt'] as String?,
    );

Map<String, dynamic> _$ClientInfoToJson(ClientInfo instance) =>
    <String, dynamic>{
      'appVersionCode': instance.appVersionCode,
      'appVersionName': instance.appVersionName,
      'appPackage': instance.appPackage,
      'appType': instance.appType,
      'appMarket': instance.appMarket,
      'deviceModel': instance.deviceModel,
      'deviceBrand': instance.deviceBrand,
      'deviceSysVersion': instance.deviceSysVersion,
      'deviceSysVersionInt': instance.deviceSysVersionInt,
    };
