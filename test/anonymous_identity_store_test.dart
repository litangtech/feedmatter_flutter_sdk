import 'package:feedmatter_flutter_sdk/src/anonymous_identity_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'FeedMatter Test',
      packageName: 'com.feedmatter.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installTime: DateTime.fromMillisecondsSinceEpoch(1000),
      updateTime: DateTime.fromMillisecondsSinceEpoch(1000),
    );
  });

  test('generates and persists one anonymous installation id', () async {
    final store = AnonymousIdentityStore();

    final first = await store.getOrCreate('project-a');
    final second = await store.getOrCreate('project-a');
    final preferences = await SharedPreferences.getInstance();

    expect(first, second);
    expect(
      preferences
          .getString('${AnonymousIdentityStore.storageKeyPrefix}.project-a'),
      first,
    );
    expect(
      first,
      matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      )),
    );
  });

  test('reuses the persisted id across store instances', () async {
    const persisted = '5c24b090-5c5a-4cf7-8d28-fec836dd8548';
    SharedPreferences.setMockInitialValues({
      '${AnonymousIdentityStore.storageKeyPrefix}.project-a': persisted,
      'feedmatter.installation_marker': 'installation-a',
    });

    final value = await AnonymousIdentityStore(
      installationMarkerLoader: () async => 'installation-a',
    ).getOrCreate('project-a');

    expect(value, persisted);
  });

  test('concurrent reads resolve to the same id', () async {
    final store = AnonymousIdentityStore();

    final values = await Future.wait([
      store.getOrCreate('project-a'),
      store.getOrCreate('project-a'),
      store.getOrCreate('project-a'),
    ]);

    expect(values.toSet(), hasLength(1));
  });

  test('uses different anonymous ids for different projects', () async {
    final store = AnonymousIdentityStore();

    final projectA = await store.getOrCreate('project-a');
    final projectB = await store.getOrCreate('project-b');

    expect(projectA, isNot(projectB));
  });

  test('rotates the anonymous id after leaving a registered account', () async {
    final store = AnonymousIdentityStore();
    final original = await store.getOrCreate('project-a');

    final rotated = await store.rotate('project-a');
    final reused = await store.getOrCreate('project-a');

    expect(rotated, isNot(original));
    expect(reused, rotated);
  });

  test('rotates a claimed id when a later process starts anonymously',
      () async {
    final loggedInStore = AnonymousIdentityStore();
    final claimed = await loggedInStore.getOrCreate('project-a');
    await loggedInStore.markClaimed('project-a');

    final anonymousStore = AnonymousIdentityStore();
    final anonymous = await anonymousStore.getForAnonymous('project-a');

    expect(anonymous, isNot(claimed));
  });

  test('rotates all confirmed project claims on logout', () async {
    final store = AnonymousIdentityStore();
    final projectA = await store.getOrCreate('project-a');
    final projectB = await store.getOrCreate('project-b');
    await store.markClaimed('project-a');
    await store.markClaimed('project-b');

    await store.rotateAllClaimed();

    expect(await store.getForAnonymous('project-a'), isNot(projectA));
    expect(await store.getForAnonymous('project-b'), isNot(projectB));
  });

  test('stops sending a confirmed anonymous id while registered', () async {
    final store = AnonymousIdentityStore();
    await store.getOrCreate('project-a');
    await store.markClaimed('project-a');

    expect(await store.getForRegistered('project-a'), isNull);
  });

  test('does not invalidate an id rotated after an older request started',
      () async {
    final store = AnonymousIdentityStore();
    final oldId = await store.getOrCreate('project-a');
    final currentId = await store.rotate('project-a');

    await store.invalidateIfCurrent('project-a', oldId);

    expect(await store.getOrCreate('project-a'), currentId);
  });

  test('rotates restored identities from a different installation', () async {
    final originalStore = AnonymousIdentityStore(
      installationMarkerLoader: () async => 'installation-a',
    );
    final originalId = await originalStore.getOrCreate('project-a');
    await originalStore.markClaimed('project-a');

    final restoredStore = AnonymousIdentityStore(
      installationMarkerLoader: () async => 'installation-b',
    );
    final restoredId = await restoredStore.getForAnonymous('project-a');

    expect(restoredId, isNot(originalId));
    expect(await restoredStore.getForRegistered('project-a'), restoredId);
  });
}
