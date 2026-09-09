// TEMP layout preview target — delete after checking the animation take-over.
// Run with: flutter run -t lib/dev_copilot_preview.dart -d chrome
import 'package:flutter/material.dart';

import 'models/chat_message.dart';
import 'screens/copilot_console_page.dart';
import 'theme/momentum_tokens.dart';

void main() {
  final now = DateTime.now();
  ChatMessage m(String role, String text) => ChatMessage(
        id: '$role-$text',
        role: role,
        text: text,
        imageUrls: const [],
        createdAt: now,
      );

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: MM.pageBg),
    home: CopilotConsolePage(previewAnimation: const [
      'http://localhost:5711/assets/assets/images/earth.png',
      'http://localhost:5711/assets/assets/images/trophy.png',
      'http://localhost:5711/assets/assets/images/rocket.png',
    ], previewMessages: [
      m('assistant',
          'Welcome aboard, Player One. I am Nova, your co-pilot. Ready to run the pre-flight check?'),
      m('user', 'Ready when you are.'),
      m('assistant',
          'Good. First: which of the 5 Cores feels weakest this week — Mindset, Career, Relationships, Physical Health or Emotional Health?'),
      m('user', 'Physical health, definitely.'),
      m('assistant',
          'Noted. We will build one keystone habit there. Small enough that you cannot fail it on your worst day.'),
    ]),
  ));
}
