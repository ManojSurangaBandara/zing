class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MessageModel(
      id: docId ?? map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}

class MatchModel {
  final String id; // usually composite or unique chatId
  final List<String> users; // user IDs
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, dynamic> userDetails; // cached names and photos for quick chat preview

  MatchModel({
    required this.id,
    required this.users,
    this.lastMessage = 'Connected! Say hi 👋',
    DateTime? lastMessageTime,
    this.userDetails = const {},
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  String getOtherUserId(String myId) {
    return users.firstWhere((id) => id != myId, orElse: () => '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'userDetails': userDetails,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MatchModel(
      id: docId ?? map['id'] ?? '',
      users: (map['users'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: map['lastMessage'] ?? 'Connected! Say hi 👋',
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.tryParse(map['lastMessageTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userDetails: (map['userDetails'] as Map<String, dynamic>?) ?? {},
    );
  }
}
