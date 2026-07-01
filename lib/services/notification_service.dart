import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Background message handler — must be a top-level function.
/// Notification messages are auto-displayed by the OS when the app is
/// backgrounded/terminated, so there's nothing to do here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Owns Firebase Cloud Messaging: permission, device-token storage, and
/// routing a notification tap into the right chat thread.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Set to a threadId (e.g. 'dm:{uid}') when a notification is tapped.
  /// `MomentumHome` listens and navigates to the matching thread.
  final ValueNotifier<String?> pendingThread = ValueNotifier<String?>(null);

  /// Lets the service show an in-app banner from outside the widget tree.
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _wired = false;

  /// Requests permission and wires the foreground / tap listeners. Idempotent.
  Future<void> init() async {
    if (_wired) return;
    _wired = true;
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission();
    } catch (e) {
      debugPrint('FCM requestPermission failed: $e');
    }

    // Launched from terminated state via a notification tap.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);

    // Tapped while the app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Arrived while the app is in the foreground → in-app banner.
    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  /// Stores this device's token at users/{uid}/fcmTokens/{token} so the
  /// Cloud Function can target it. Re-saves on refresh.
  Future<void> saveTokenForUser(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) await _writeToken(uid, token);
      messaging.onTokenRefresh.listen((t) => _writeToken(uid, t));
    } catch (e) {
      debugPrint('saveTokenForUser failed: $e');
    }
  }

  Future<void> _writeToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? _threadIdOf(RemoteMessage m) {
    final tid = m.data['threadId'];
    return (tid is String && tid.isNotEmpty) ? tid : null;
  }

  void _handleTap(RemoteMessage m) {
    final tid = _threadIdOf(m);
    if (tid != null) pendingThread.value = tid;
  }

  void _handleForeground(RemoteMessage m) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    final tid = _threadIdOf(m);
    final title = m.notification?.title ?? 'New message';
    final body = m.notification?.body ?? '';
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(
        body.isEmpty ? title : '$title: $body',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      duration: const Duration(seconds: 4),
      action: tid == null
          ? null
          : SnackBarAction(
              label: 'OPEN',
              onPressed: () => pendingThread.value = tid,
            ),
    ));
  }
}
