class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final DateTime? dob;
  final String gender; // 'Male', 'Female', 'Other'
  final String preference; // 'Women', 'Men', 'Everyone'
  final String district;
  final String town;
  final String bio;
  final List<String> interests;
  final List<String> photos; // up to 10 photos
  final String selfieUrl;
  final String nicFrontUrl;
  final String nicBackUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final String role; // 'user', 'super_admin'
  final double? latitude;
  final double? longitude;
  final String? height;
  final String? occupation;
  final String? education;
  final String? relationshipGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    this.dob,
    required this.gender,
    required this.preference,
    required this.district,
    required this.town,
    required this.bio,
    this.interests = const [],
    this.photos = const [],
    this.selfieUrl = '',
    this.nicFrontUrl = '',
    this.nicBackUrl = '',
    this.status = 'pending',
    this.rejectionReason,
    this.role = 'user',
    this.latitude,
    this.longitude,
    this.height,
    this.occupation,
    this.education,
    this.relationshipGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuperAdmin => role == 'super_admin';

  String get primaryPhoto {
    if (photos.isNotEmpty) {
      return photos.first;
    }
    if (selfieUrl.isNotEmpty) {
      return selfieUrl;
    }
    return '';
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    DateTime? dob,
    String? gender,
    String? preference,
    String? district,
    String? town,
    String? bio,
    List<String>? interests,
    List<String>? photos,
    String? selfieUrl,
    String? nicFrontUrl,
    String? nicBackUrl,
    String? status,
    String? rejectionReason,
    String? role,
    double? latitude,
    double? longitude,
    String? height,
    String? occupation,
    String? education,
    String? relationshipGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      preference: preference ?? this.preference,
      district: district ?? this.district,
      town: town ?? this.town,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photos: photos ?? this.photos,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      nicFrontUrl: nicFrontUrl ?? this.nicFrontUrl,
      nicBackUrl: nicBackUrl ?? this.nicBackUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      height: height ?? this.height,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'preference': preference,
      'district': district,
      'town': town,
      'bio': bio,
      'interests': interests,
      'photos': photos,
      'selfieUrl': selfieUrl,
      'nicFrontUrl': nicFrontUrl,
      'nicBackUrl': nicBackUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'height': height,
      'occupation': occupation,
      'education': education,
      'relationshipGoal': relationshipGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      id: docId ?? map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 24,
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'].toString()) : null,
      gender: map['gender'] ?? 'Female',
      preference: map['preference'] ?? 'Everyone',
      district: map['district'] ?? 'Colombo',
      town: map['town'] ?? '',
      bio: map['bio'] ?? '',
      interests: (map['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photos: (map['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      selfieUrl: map['selfieUrl'] ?? '',
      nicFrontUrl: map['nicFrontUrl'] ?? '',
      nicBackUrl: map['nicBackUrl'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      role: map['role'] ?? 'user',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      height: map['height'],
      occupation: map['occupation'],
      education: map['education'],
      relationshipGoal: map['relationshipGoal'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
