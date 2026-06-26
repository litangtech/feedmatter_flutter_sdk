import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart';

abstract class FeedMatterFaqCache {
  Future<String?> getVersion();

  Future<List<FaqItem>?> getItems();

  Future<void> save(String version, List<FaqItem> items);
}

class InMemoryFeedMatterFaqCache implements FeedMatterFaqCache {
  String? _version;
  List<FaqItem>? _items;

  @override
  Future<String?> getVersion() async => _version;

  @override
  Future<List<FaqItem>?> getItems() async => _items;

  @override
  Future<void> save(String version, List<FaqItem> items) async {
    _version = version;
    _items = List<FaqItem>.from(items);
  }
}
