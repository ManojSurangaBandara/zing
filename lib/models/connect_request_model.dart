class ConnectRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderPhoto;
  final List<String> senderPhotos;
  final String senderDistrict;
  final String senderTown;
  final int senderAge;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? message;
  final String? senderBio;
  final List<String> senderInterests;
  final DateTime createdAt;

  ConnectRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderPhoto,
    List<String>? senderPhotos,
    required this.senderDistrict,
    this.senderTown = '',
    required this.senderAge,
    this.status = 'pending',
    this.message,
    this.senderBio,
    this.senderInterests = const [],
    DateTime? createdAt,
  })  : senderPhotos = senderPhotos ?? (senderPhoto.isNotEmpty ? [senderPhoto] : const []),
        createdAt = createdAt ?? DateTime.now();

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
      'senderPhotos': senderPhotos,
      'senderDistrict': senderDistrict,
      'senderTown': senderTown,
      'senderAge': senderAge,
      'status': status,
      'message': message,
      'senderBio': senderBio,
      'senderInterests': senderInterests,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ConnectRequestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final photo = map['senderPhoto']?.toString() ?? '';
    final photosRaw = map['senderPhotos'];
    List<String> photos = [];
    if (photosRaw is List) {
      photos = photosRaw.map((e) => e.toString()).toList();
    } else if (photo.isNotEmpty) {
      photos = [photo];
    }

    final interestsRaw = map['senderInterests'];
    List<String> interests = [];
    if (interestsRaw is List) {
      interests = interestsRaw.map((e) => e.toString()).toList();
    }

    return ConnectRequestModel(
      id: docId ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhoto: photo,
      senderPhotos: photos,
      senderDistrict: map['senderDistrict'] ?? '',
      senderTown: map['senderTown'] ?? '',
      senderAge: (map['senderAge'] as num?)?.toInt() ?? 24,
      status: map['status'] ?? 'pending',
      message: map['message'],
      senderBio: map['senderBio'],
      senderInterests: interests,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
