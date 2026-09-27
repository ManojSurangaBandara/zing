class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'verification_approved', 'verification_rejected', 'connect_request', 'connect_accepted', 'message'
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppNotificationModel(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
