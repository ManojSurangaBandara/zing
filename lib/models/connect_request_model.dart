class ConnectRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderPhoto;
  final String senderDistrict;
  final String senderTown;
  final int senderAge;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? message;
  final DateTime createdAt;

  ConnectRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderPhoto,
    required this.senderDistrict,
    this.senderTown = '',
    required this.senderAge,
    this.status = 'pending',
    this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'senderDistrict': senderDistrict,
      'senderTown': senderTown,
      'senderAge': senderAge,
      'status': status,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ConnectRequestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ConnectRequestModel(
      id: docId ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhoto: map['senderPhoto'] ?? '',
      senderDistrict: map['senderDistrict'] ?? '',
      senderTown: map['senderTown'] ?? '',
      senderAge: (map['senderAge'] as num?)?.toInt() ?? 24,
      status: map['status'] ?? 'pending',
      message: map['message'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
