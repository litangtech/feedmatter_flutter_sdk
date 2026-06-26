import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart';

import 'faq/faq_cache.dart';

class FeedMatterUiOptions {
  const FeedMatterUiOptions({
    this.customInfo = const {},
    this.onPickAttachments,
    this.faqCache,
    this.showProjectConfigDebugPanel = false,
    this.platformFilter,
    this.onFaqUrlTap,
  });

  final Map<String, dynamic> customInfo;
  final Future<List<Attachment>> Function()? onPickAttachments;
  final FeedMatterFaqCache? faqCache;
  final bool showProjectConfigDebugPanel;
  final String? platformFilter;
  final void Function(String url)? onFaqUrlTap;
}
