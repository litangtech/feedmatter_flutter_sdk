import 'package:feedmatter_flutter_ui/feedmatter_flutter_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedMatterUiTheme', () {
    test('forBrightness light uses light surface', () {
      const theme = FeedMatterUiTheme();
      final light = FeedMatterUiTheme.forBrightness(Brightness.light);
      expect(light.surfaceColor, theme.surfaceColor);
      expect(light.pageBackground, theme.pageBackground);
    });

    test('forBrightness dark uses dark palette', () {
      final dark = FeedMatterUiTheme.forBrightness(Brightness.dark);
      final light = FeedMatterUiTheme.forBrightness(Brightness.light);
      expect(dark.surfaceColor, isNot(equals(light.surfaceColor)));
      expect(dark.pageBackground, isNot(equals(light.pageBackground)));
      expect(dark.textPrimary, isNot(equals(light.textPrimary)));
    });

    test('forBrightness uses seedColor for primaryBlue', () {
      const seed = Color(0xFF6750A4);
      final theme = FeedMatterUiTheme.forBrightness(
        Brightness.light,
        seedColor: seed,
      );
      expect(theme.primaryBlue, seed);
    });
  });

  group('buildFeedMatterTheme', () {
    test('uses seedColor in color scheme', () {
      const seed = Color(0xFF6750A4);
      final theme = buildFeedMatterTheme(
        brightness: Brightness.light,
        seedColor: seed,
      );
      expect(theme.colorScheme.primary, isNotNull);
      final tokens = theme.extension<FeedMatterUiTheme>();
      expect(tokens?.primaryBlue, seed);
    });

    test('buildFeedMatterLightTheme defaults to light', () {
      final theme = buildFeedMatterLightTheme();
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('buildFeedMatterDarkTheme defaults to dark', () {
      final theme = buildFeedMatterDarkTheme();
      expect(theme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('FeedMatterThemeScope', () {
    testWidgets('applies dark tokens when mode is dark', (tester) async {
      Color? surfaceColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: FeedMatterThemeScope(
            options: const FeedMatterThemeOptions(
              mode: FeedMatterThemeMode.dark,
              seedColor: Color(0xFF6750A4),
            ),
            child: Builder(
              builder: (context) {
                surfaceColor = FeedMatterUiTheme.of(context).surfaceColor;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(surfaceColor, const Color(0xFF1E1E1E));
    });

    testWidgets('follows platform brightness when mode is system', (tester) async {
      Color? surfaceColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark),
            child: FeedMatterThemeScope(
              options: const FeedMatterThemeOptions(
                mode: FeedMatterThemeMode.system,
              ),
              child: Builder(
                builder: (context) {
                  surfaceColor = FeedMatterUiTheme.of(context).surfaceColor;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(surfaceColor, const Color(0xFF1E1E1E));
    });

    testWidgets('inherits host primary when seedColor is null', (tester) async {
      const hostPrimary = Color(0xFFFF5722);
      Color? primaryBlue;
      late Color expectedPrimary;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: hostPrimary),
          ),
          home: Builder(
            builder: (hostContext) {
              expectedPrimary = Theme.of(hostContext).colorScheme.primary;
              return FeedMatterThemeScope(
                options: const FeedMatterThemeOptions(
                  mode: FeedMatterThemeMode.light,
                ),
                child: Builder(
                  builder: (context) {
                    primaryBlue = FeedMatterUiTheme.of(context).primaryBlue;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(primaryBlue, expectedPrimary);
    });

    testWidgets('push wraps route with FeedMatter theme', (tester) async {
      Color? surfaceColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: FeedMatterThemeScope(
            options: const FeedMatterThemeOptions(
              mode: FeedMatterThemeMode.dark,
            ),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FeedMatterThemeScope.push<void>(
                      context,
                      theme: const FeedMatterThemeOptions(
                        mode: FeedMatterThemeMode.dark,
                      ),
                      child: Builder(
                        builder: (routeContext) {
                          surfaceColor =
                              FeedMatterUiTheme.of(routeContext).surfaceColor;
                          return const Scaffold(body: SizedBox());
                        },
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(surfaceColor, const Color(0xFF1E1E1E));
    });

    testWidgets('outer context misses scoped FeedMatter theme', (tester) async {
      Color? surfaceColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (outerContext) {
              return FeedMatterThemeScope(
                options: const FeedMatterThemeOptions(
                  mode: FeedMatterThemeMode.dark,
                ),
                child: Builder(
                  builder: (_) {
                    surfaceColor =
                        FeedMatterUiTheme.of(outerContext).surfaceColor;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(surfaceColor, Colors.white);
    });

    testWidgets('wrap paints page background immediately', (tester) async {
      Color? backgroundColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              return FeedMatterThemeScope.wrap(
                context: context,
                options: const FeedMatterThemeOptions(
                  mode: FeedMatterThemeMode.dark,
                ),
                child: Builder(
                  builder: (context) {
                    backgroundColor = FeedMatterUiTheme.of(context).pageBackground;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(backgroundColor, const Color(0xFF121212));
    });
  });
}
