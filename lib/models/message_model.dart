import 'reclamation.dart';

class ReclamationMessage {
  final int id;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final ReclamationSender sender;

  const ReclamationMessage({
    required this.id,
    required this.content,
    required this.messageType,
    required this.createdAt,
    required this.sender,
  });

  factory ReclamationMessage.fromJson(Map<String, dynamic> json) {
    return ReclamationMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      sender: ReclamationSender.fromJson(json['sender'] as Map<String, dynamic>? ?? {}),
    );
  }
}
