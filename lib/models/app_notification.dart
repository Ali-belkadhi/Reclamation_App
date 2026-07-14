class AppNotification {
  final String id;
  final String reclamationId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.reclamationId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      reclamationId: json['reclamationId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
