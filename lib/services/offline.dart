import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a cache-aware fetch. [fromCache] is true when the network call
/// failed (offline) and we fell back to the last-good data on disk — the UI
/// uses it to show a "you're offline, showing saved data" banner.
class Fetched<T> {
  const Fetched(this.data, {this.fromCache = false});
  final T data;
  final bool fromCache;
}

/// True when [e] looks like a connectivity failure (no internet / DNS / reset)
/// rather than a real server or app error. Only these should fall back to cache.
bool isNetworkError(Object e) {
  if (e is SocketException || e is http.ClientException || e is TimeoutException) {
    return true;
  }
  final s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('clientexception') ||
      s.contains('connection closed') ||
      s.contains('connection refused') ||
      s.contains('network is unreachable') ||
      s.contains('software caused connection abort') ||
      s.contains('timed out') ||
      s.contains('timeoutexception');
}

/// A short, player-safe message for an error — never the raw exception text.
/// Use for snackbars/toasts where a banner/full view isn't appropriate.
String friendlyError(Object e, {String? action}) {
  final verb = action == null ? '' : ' $action';
  if (isNetworkError(e)) {
    return "You're offline — couldn't$verb. Reconnect and try again.";
  }
  return "Something went wrong${verb.isEmpty ? '' : ' while$verb'}. Please try again.";
}

/// Tiny JSON-on-disk cache (shared_preferences) for last-good API payloads.
/// Keys are namespaced per feature + user so different accounts don't collide.
class LocalCache {
  static Future<void> putJson(String key, Object value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, jsonEncode(value));
    } catch (_) {
      // Caching is best-effort — never let a cache write break a real fetch.
    }
  }

  /// Returns the decoded JSON for [key], or null if absent/unreadable.
  static Future<dynamic> getJson(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(key);
      if (s == null) return null;
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }
}
