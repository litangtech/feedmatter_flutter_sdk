import 'package:json_annotation/json_annotation.dart';
import 'faq_item.dart';

part 'faq_list_response.g.dart';

@JsonSerializable()
class FaqListResponse {
  final String version;
  final List<FaqItem> items;

  const FaqListResponse({
    required this.version,
    required this.items,
  });

  factory FaqListResponse.fromJson(Map<String, dynamic> json) =>
      _$FaqListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FaqListResponseToJson(this);

  bool get hasUpdate => items.isNotEmpty;
}
