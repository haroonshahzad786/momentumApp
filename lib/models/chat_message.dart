class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.imageUrls,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final List<String> imageUrls;
  final DateTime createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  String? get firstImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrls: (json['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is Map && raw['_seconds'] != null) {
      final seconds = (raw['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return DateTime.now();
  }
}
