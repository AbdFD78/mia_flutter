// lib/models/activity.dart

class Activity {
  final int id;
  final String type; // 'suivie' ou 'event'
  final String typeLabel; // 'Suivi' ou 'Événement'
  final String clientName;
  final int? clientId;
  final String authorName;
  final int? authorId;
  final String? title;
  final String? content;
  final DateTime? createdAt;

  Activity({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.clientName,
    this.clientId,
    required this.authorName,
    this.authorId,
    this.title,
    this.content,
    this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      typeLabel: json['type_label'] ?? '',
      clientName: json['client_name'] ?? 'N/A',
      clientId: json['client_id'],
      authorName: json['author_name'] ?? 'N/A',
      authorId: json['author_id'],
      title: json['title'],
      content: json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'type_label': typeLabel,
      'client_name': clientName,
      'client_id': clientId,
      'author_name': authorName,
      'author_id': authorId,
      'title': title,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
