import 'package:json_annotation/json_annotation.dart';

part 'faq_item.g.dart';

@JsonSerializable()
class FaqItem {
  final String id;
  final String title;
  final String? answer;
  final String? url;
  final String? keywords;
  final List<String>? platforms;
  final int sortOrder;

  const FaqItem({
    required this.id,
    required this.title,
    this.answer,
    this.url,
    this.keywords,
    this.platforms,
    this.sortOrder = 0,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) =>
      _$FaqItemFromJson(json);

  Map<String, dynamic> toJson() => _$FaqItemToJson(this);
}
