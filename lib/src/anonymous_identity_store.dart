import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'installation_marker.dart';

class AnonymousIdentityStore {
  static const String storageKeyPrefix = 'feedmatter.anonymous_install_id';
  static const String _claimedKeyPrefix = 'feedmatter.anonymous_claimed';
  static const String _claimedNamespacesKey =
      'feedmatter.anonymous_claimed_namespaces';
  static const String _installationMarkerKey = 'feedmatter.installation_marker';

  final Future<SharedPreferences> Function() _preferencesLoader;
  final Future<String> Function() _installationMarkerLoader;
  final Uuid _uuid;
  final Map<String, Future<String>> _pendingIdentities = {};
  final Map<String, Future<String>> _pendingAnonymousAccess = {};

  AnonymousIdentityStore({
    Future<SharedPreferences> Function()? preferencesLoader,
    Future<String> Function()? installationMarkerLoader,
    Uuid? uuid,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _installationMarkerLoader =
            installationMarkerLoader ?? loadFeedMatterInstallationMarker,
        _uuid = uuid ?? const Uuid();

  Future<String> getOrCreate(String namespace) {
    final storageKey = '$storageKeyPrefix.$namespace';
    final existing = _pendingIdentities[storageKey];
    if (existing != null) {
      return existing;
    }
    final pending = _loadOrCreateWithReset(storageKey);
    _pendingIdentities[storageKey] = pending;
    return pending;
  }

  Future<String> getForAnonymous(String namespace) {
    final existing = _pendingAnonymousAccess[namespace];
    if (existing != null) {
      return existing;
    }
    final pending = _getForAnonymousWithReset(namespace);
    _pendingAnonymousAccess[namespace] = pending;
    return pending;
  }

  Future<String?> getForRegistered(String namespace) async {
    final preferences = await _loadPreferences();
    if (preferences.getBool('$_claimedKeyPrefix.$namespace') == true) {
      return null;
    }
    return getOrCreate(namespace);
  }

  Future<String> _getForAnonymousWithReset(String namespace) async {
    try {
      final preferences = await _loadPreferences();
      if (preferences.getBool('$_claimedKeyPrefix.$namespace') == true) {
        return await rotate(namespace);
      }
      return await getOrCreate(namespace);
    } finally {
      _pendingAnonymousAccess.remove(namespace);
    }
  }

  Future<String> rotate(String namespace) {
    final storageKey = '$storageKeyPrefix.$namespace';
    final previous = _pendingIdentities[storageKey];
    final pending = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // 旧身份加载失败也应继续尝试创建新身份。
        }
      }
      return _createAndPersistWithReset(storageKey);
    }();
    _pendingIdentities[storageKey] = pending;
    return pending;
  }

  Future<void> markClaimed(String namespace) async {
    final preferences = await _loadPreferences();
    if (preferences.getBool('$_claimedKeyPrefix.$namespace') == true) {
      return;
    }
    final namespaces =
        preferences.getStringList(_claimedNamespacesKey)?.toSet() ?? {};
    namespaces.add(namespace);
    final namespacesPersisted = await preferences.setStringList(
        _claimedNamespacesKey, namespaces.toList());
    if (!namespacesPersisted) {
      throw StateError('无法持久化 FeedMatter 匿名身份关联状态');
    }
    final claimedPersisted =
        await preferences.setBool('$_claimedKeyPrefix.$namespace', true);
    if (!claimedPersisted) {
      throw StateError('无法持久化 FeedMatter 匿名身份关联状态');
    }
  }

  Future<void> rotateAllClaimed() async {
    final preferences = await _loadPreferences();
    final namespaces =
        preferences.getStringList(_claimedNamespacesKey)?.toSet() ?? {};
    for (final namespace in namespaces) {
      if (preferences.getBool('$_claimedKeyPrefix.$namespace') == true) {
        await rotate(namespace);
      }
    }
  }

  Future<void> invalidateIfCurrent(
    String namespace,
    String anonymousId,
  ) async {
    final preferences = await _loadPreferences();
    final storageKey = '$storageKeyPrefix.$namespace';
    if (preferences.getString(storageKey) == anonymousId) {
      await rotate(namespace);
    }
  }

  Future<String> _loadOrCreateWithReset(String storageKey) async {
    try {
      return await _loadOrCreate(storageKey);
    } catch (_) {
      _pendingIdentities.remove(storageKey);
      rethrow;
    }
  }

  Future<String> _loadOrCreate(String storageKey) async {
    final preferences = await _loadPreferences();
    final stored = preferences.getString(storageKey);
    if (stored != null && _isUuid(stored)) {
      return stored;
    }
    final generated = _uuid.v4();
    final persisted = await preferences.setString(storageKey, generated);
    if (!persisted) {
      throw StateError('无法持久化 FeedMatter 匿名安装 ID');
    }
    return generated;
  }

  Future<String> _createAndPersistWithReset(String storageKey) async {
    try {
      final preferences = await _loadPreferences();
      final generated = _uuid.v4();
      final persisted = await preferences.setString(storageKey, generated);
      if (!persisted) {
        throw StateError('无法持久化 FeedMatter 匿名安装 ID');
      }
      final namespace = storageKey.substring('$storageKeyPrefix.'.length);
      final claimCleared =
          await preferences.setBool('$_claimedKeyPrefix.$namespace', false);
      if (!claimCleared) {
        throw StateError('无法清除 FeedMatter 匿名身份关联状态');
      }
      return generated;
    } catch (_) {
      _pendingIdentities.remove(storageKey);
      rethrow;
    }
  }

  Future<SharedPreferences> _loadPreferences() async {
    final preferences = await _preferencesLoader();
    final installationMarker = await _installationMarkerLoader();
    final persistedMarker = preferences.getString(_installationMarkerKey);
    if (persistedMarker == installationMarker) {
      return preferences;
    }

    final identityKeys = preferences
        .getKeys()
        .where(
          (key) =>
              key.startsWith('$storageKeyPrefix.') ||
              key.startsWith('$_claimedKeyPrefix.'),
        )
        .toList();
    for (final key in identityKeys) {
      if (!await preferences.remove(key)) {
        throw StateError('无法清理已恢复的 FeedMatter 匿名身份');
      }
    }
    if (!await preferences.remove(_claimedNamespacesKey)) {
      throw StateError('无法清理已恢复的 FeedMatter 匿名身份');
    }
    _pendingIdentities.clear();
    _pendingAnonymousAccess.clear();

    if (!await preferences.setString(
      _installationMarkerKey,
      installationMarker,
    )) {
      throw StateError('无法持久化 FeedMatter 安装标识');
    }
    return preferences;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
