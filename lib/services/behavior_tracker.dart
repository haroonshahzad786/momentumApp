import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Behavioral data capture (#33): screen views, skips, backtracks and errors,
/// batched to `flutterLogEvents` (→ `events/` + a per-visit session rollup).
///
/// Fire-and-forget: tracking must never block or break the app, so every
/// failure is swallowed and a failed batch is dropped after one retry.
class BehaviorTracker with WidgetsBindingObserver {
  BehaviorTracker._();
  static final BehaviorTracker instance = BehaviorTracker._();

  static const String _url =
      'https://us-central1-momentum-bce49.cloudfunctions.net/flutterLogEvents';
  static const int _flushAt = 20;
  static const Duration _flushEvery = Duration(seconds: 20);

  final String _sessionId = _newId();
  final List<Map<String, dynamic>> _buffer = [];
  final List<String> _trail = []; // screens visited, newest last
  Timer? _timer;
  bool _started = false;
  bool _sending = false;
  http.Client _client = http.Client();

  static String _newId() {
    final r = Random();
    final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '$t${List.generate(6, (_) => r.nextInt(36).toRadixString(36)).join()}';
  }

  /// Hooks the app lifecycle (flush when the tab is hidden/closed) and starts
  /// the periodic flush. Safe to call more than once.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_flushEvery, (_) => flush());
    track('session_start');
  }

  @visibleForTesting
  void debugReset({http.Client? client}) {
    _timer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _buffer.clear();
    _trail.clear();
    if (client != null) _client = client;
  }

  @visibleForTesting
  List<Map<String, dynamic>> get pending => List.unmodifiable(_buffer);

  void track(String type, {String? screen, Map<String, dynamic>? payload}) {
    _buffer.add({
      'type': type,
      if (screen != null) 'screen': screen,
      if (payload != null) 'payload': payload,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    if (_buffer.length >= _flushAt) flush();
  }

  /// A screen came into view. Returning to the screen you were on just before
  /// the current one (A→B→A) is logged as a backtrack.
  void screen(String key) {
    if (_trail.isNotEmpty && _trail.last == key) return;
    final back = _trail.length >= 2 && _trail[_trail.length - 2] == key;
    _trail.add(key);
    if (_trail.length > 6) _trail.removeAt(0);
    track('screen_view', screen: key);
    if (back) track('backtrack', screen: key);
  }

  /// The player skipped a step ([where] names it, e.g. `checkin_core`).
  void skip(String where, {String? screen}) =>
      track('skip', screen: screen, payload: {'where': where});

  Future<void> flush() async {
    if (_sending || _buffer.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return; // keep buffering until sign-in
    _sending = true;
    final batch = _buffer.take(50).toList();
    _buffer.removeRange(0, batch.length);
    try {
      final r = await _client.post(
        Uri.parse(_url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'secret': ApiConfig.secret,
          'userId': uid,
          'sessionId': _sessionId,
          'events': batch,
        }),
      );
      if (r.statusCode >= 500) _buffer.insertAll(0, batch); // one more try later
    } catch (_) {
      // Offline / blocked — drop; behavioral data is best-effort.
    } finally {
      _sending = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      track('session_pause', payload: {'state': state.name});
      flush();
    } else if (state == AppLifecycleState.resumed) {
      track('session_resume');
    }
  }
}
