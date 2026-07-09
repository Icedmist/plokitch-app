import 'dart:async';

class DataCacheService {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _timestamps = {};
  static const Duration _ttl = Duration(minutes: 5);

  static void set(String key, dynamic value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  static dynamic get(String key) {
    if (!_cache.containsKey(key)) return null;
    final timestamp = _timestamps[key]!;
    if (DateTime.now().difference(timestamp) > _ttl) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }
    return _cache[key];
  }

  static void invalidate(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  static void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}
