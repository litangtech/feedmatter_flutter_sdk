import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/feedmatter_ui_theme.dart';

final _urlPattern = RegExp(
  r'https?://[^\s<>"{}|\\^`\[\]]+',
  caseSensitive: false,
);

final _versionPattern = RegExp(r'\b\d+\.\d+\.\d+\b');

class FeedMatterLinkText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final void Function(String url)? onUrlTap;

  const FeedMatterLinkText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.onUrlTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedMatterUiTheme.of(context);
    final baseStyle = style ??
        TextStyle(
          color: theme.textPrimary,
          fontSize: 15,
          height: 1.5,
        );
    final linkStyle = baseStyle.copyWith(
      color: theme.primaryBlue,
      decoration: TextDecoration.underline,
      decorationColor: theme.primaryBlue,
    );

    final spans = _buildSpans(text, baseStyle, linkStyle, onUrlTap);

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans(
    String input,
    TextStyle baseStyle,
    TextStyle linkStyle,
    void Function(String url)? onUrlTap,
  ) {
    final matches = <_Match>[];
    for (final match in _urlPattern.allMatches(input)) {
      matches.add(_Match(match.start, match.end, match.group(0)!, true));
    }
    for (final match in _versionPattern.allMatches(input)) {
      final overlaps = matches.any(
        (m) => match.start >= m.start && match.start < m.end,
      );
      if (!overlaps) {
        matches.add(_Match(match.start, match.end, match.group(0)!, false));
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    if (matches.isEmpty) {
      return [TextSpan(text: input, style: baseStyle)];
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: input.substring(cursor, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.text,
        style: linkStyle,
        recognizer: match.isUrl && onUrlTap != null
            ? (TapGestureRecognizer()..onTap = () => onUrlTap(match.text))
            : null,
      ));
      cursor = match.end;
    }
    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor), style: baseStyle));
    }
    return spans;
  }
}

class _Match {
  final int start;
  final int end;
  final String text;
  final bool isUrl;

  _Match(this.start, this.end, this.text, this.isUrl);
}
