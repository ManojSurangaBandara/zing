import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../models/connect_request_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import 'image_compression_service.dart';
import 'location_service.dart';
import 'mock_data.dart';

class BackendService extends ChangeNotifier {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  final Uuid _uuid = const Uuid();

  bool _isFirebaseAvailable = false;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // In-Memory Database for Mock/Fallback & testing
  final List<UserModel> _users = [];
  final List<ConnectRequestModel> _requests = [];
  final List<MatchModel> _matches = [];
  final List<MessageModel> _messages = [];
  final List<AppNotificationModel> _notifications = [];

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseAvailable = true;
      } else {
        // Try initializing default app if google-services is available
        await Firebase.initializeApp();
        _isFirebaseAvailable = true;
      }
      debugPrint('Firebase initialized successfully: $_isFirebaseAvailable');
    } catch (e) {
      debugPrint('Firebase not configured or failed to initialize, using local persistent engine: $e');
      _isFirebaseAvailable = false;
    }

    _loadInitialMockData();

    // Default to approved user Dilini so the app launches ready to use immediately
    _currentUser = _users.firstWhere((u) => u.id == 'user_001', orElse: () => _users.first);
    notifyListeners();
  }

  void _loadInitialMockData() {
    _users.clear();
    _users.add(MockData.superAdmin);
    _users.addAll(MockData.initialUsers);

    _requests.clear();
    _requests.addAll(MockData.initialRequests);

    _matches.clear();
    _matches.addAll(MockData.initialMatches);

    _messages.clear();
    _messages.addAll(MockData.initialMessages);

    _notifications.clear();
    _notifications.addAll(MockData.initialNotifications);
  }

  // ==================== AUTH & REGISTRATION ====================

  /// Quick switcher for testing & demo purposes
  void switchDemoUser(String userId) {
    final user = _users.firstWhere((u) => u.id == userId, orElse: () => _users.first);
    _currentUser = user;
    notifyListeners();
  }

  /// Register new user profile with manual verification documents
  Future<({bool success, String message, UserModel? user})> registerWithVerification({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    required String preference,
    required String district,
    required String town,
    required String bio,
    required List<String> interests,
    required File selfieFile,
    required File nicFrontFile,
    required File nicBackFile,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // 1. Compress verification documents first!
      debugPrint('Compressing verification documents before upload...');
      final compressedSelfie = await ImageCompressionService.compressImageFile(selfieFile, quality: 75);
      final compressedNicFront = await ImageCompressionService.compressImageFile(nicFrontFile, quality: 80);
      final compressedNicBack = await ImageCompressionService.compressImageFile(nicBackFile, quality: 80);

      String selfieUrl = compressedSelfie?.path ?? selfieFile.path;
      String nicFrontUrl = compressedNicFront?.path ?? nicFrontFile.path;
      String nicBackUrl = compressedNicBack?.path ?? nicBackFile.path;

      final newUserId = _uuid.v4();

      // If Firebase is available, handle auth and storage
      if (_isFirebaseAvailable) {
        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = userCredential.user?.uid ?? newUserId;

          // Upload compressed files to Firebase Storage
          final storage = FirebaseStorage.instance;
          final selfieRef = storage.ref().child('verifications/$uid/selfie.jpg');
          final nicFrontRef = storage.ref().child('verifications/$uid/nic_front.jpg');
          final nicBackRef = storage.ref().child('verifications/$uid/nic_back.jpg');

          if (compressedSelfie != null) {
            await selfieRef.putFile(compressedSelfie);
            selfieUrl = await selfieRef.getDownloadURL();
          }
          if (compressedNicFront != null) {
            await nicFrontRef.putFile(compressedNicFront);
            nicFrontUrl = await nicFrontRef.getDownloadURL();
          }
          if (compressedNicBack != null) {
            await nicBackRef.putFile(compressedNicBack);
            nicBackUrl = await nicBackRef.getDownloadURL();
          }
        } catch (firebaseErr) {
          debugPrint('Firebase registration error, saving to database: $firebaseErr');
        }
      }

      // Default coords for district if GPS not provided
      final coords = LocationService.getDistrictCoordinates(district);

      final newUser = UserModel(
        id: newUserId,
        email: email,
        name: name,
        age: age,
        gender: gender,
        preference: preference,
        district: district,
        town: town,
        bio: bio,
        interests: interests,
        photos: [selfieUrl], // Add selfie as first photo initially
        selfieUrl: selfieUrl,
        nicFrontUrl: nicFrontUrl,
        nicBackUrl: nicBackUrl,
        status: 'pending',
        role: 'user',
        latitude: latitude ?? coords.$1,
        longitude: longitude ?? coords.$2,
      );

      _users.add(newUser);

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(newUser.id).set(newUser.toMap());
        } catch (e) {
          debugPrint('Firestore save error: $e');
        }
      }

      // Automatically add notification for user
      _notifications.add(AppNotificationModel(
        id: _uuid.v4(),
        userId: newUser.id,
        title: 'Application Submitted 📝',
        body: 'Your identity documents are under review by the zing.lk admin team. You will be notified once verified.',
        type: 'verification_pending',
      ));

      _currentUser = newUser;
      notifyListeners();

      return (
        success: true,
        message: 'Registration successful! Your profile has been submitted for manual admin verification.',
        user: newUser,
      );
    } catch (e) {
      debugPrint('Registration exception: $e');
      return (
        success: false,
        message: 'Failed to register: ${e.toString()}',
        user: null,
      );
    }
  }

  /// Sign In with Email and Password
  Future<({bool success, String message, UserModel? user})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Find matching user
      final user = _users.firstWhere(
        (u) => u.email.toLowerCase().trim() == email.toLowerCase().trim(),
        orElse: () => throw Exception('No account found with this email.'),
      );

      // Check verification status
      if (user.role != 'super_admin') {
        if (user.status == 'pending') {
          _currentUser = user;
          notifyListeners();
          return (
            success: false,
            message: 'Your account verification is currently under review by our admin team. Please check back shortly.',
            user: user,
          );
        } else if (user.status == 'rejected') {
          _currentUser = user;
          notifyListeners();
          return (
            success: false,
            message: 'Verification rejected: ${user.rejectionReason ?? "Identity could not be verified."}',
            user: user,
          );
        }
      }

      _currentUser = user;
      notifyListeners();

      return (
        success: true,
        message: 'Welcome back, ${user.name}!',
        user: user,
      );
    } catch (e) {
      return (
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
        user: null,
      );
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // ==================== SUPER ADMIN VERIFICATION ====================

  /// Fetch all profiles pending verification
  List<UserModel> getPendingVerifications() {
    return _users.where((u) => u.status == 'pending').toList();
  }

  /// Fetch all approved profiles
  List<UserModel> getApprovedUsers() {
    return _users.where((u) => u.status == 'approved' && u.role != 'super_admin').toList();
  }

  /// Fetch all rejected profiles
  List<UserModel> getRejectedUsers() {
    return _users.where((u) => u.status == 'rejected').toList();
  }

  /// Super Admin: Approve a user's verification
  Future<bool> approveUserVerification(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final updatedUser = _users[index].copyWith(
        status: 'approved',
        rejectionReason: null,
        updatedAt: DateTime.now(),
      );
      _users[index] = updatedUser;

      // Add approval notification
      _notifications.add(AppNotificationModel(
        id: _uuid.v4(),
        userId: userId,
        title: 'Account Verified! 🌟',
        body: 'Congratulations! Your zing.lk profile has been verified and approved. You can now connect and chat with matches!',
        type: 'verification_approved',
      ));

      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'status': 'approved',
            'rejectionReason': null,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Firestore approve update error: $e');
        }
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Super Admin: Reject a user's verification with a specific reason
  Future<bool> rejectUserVerification(String userId, String reason) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final updatedUser = _users[index].copyWith(
        status: 'rejected',
        rejectionReason: reason,
        updatedAt: DateTime.now(),
      );
      _users[index] = updatedUser;

      // Add rejection notification
      _notifications.add(AppNotificationModel(
        id: _uuid.v4(),
        userId: userId,
        title: 'Verification Update ⚠️',
        body: 'Your profile verification was declined: $reason. Please re-submit clear documents.',
        type: 'verification_rejected',
      ));

      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'status': 'rejected',
            'rejectionReason': reason,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Firestore reject update error: $e');
        }
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Update user profile details
  Future<bool> updateProfile(UserModel updatedUser) async {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(updatedUser.id).update(updatedUser.toMap());
        } catch (e) {
          debugPrint('Firestore update profile error: $e');
        }
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Upload up to 10 photos, compressing each before saving
  Future<List<String>> uploadProfilePhotos(String userId, List<File> newPhotoFiles) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return [];

    final currentPhotos = List<String>.from(_users[index].photos);
    final remainingSlots = 10 - currentPhotos.length;
    if (remainingSlots <= 0) return currentPhotos;

    final filesToProcess = newPhotoFiles.take(remainingSlots);

    for (final file in filesToProcess) {
      // Compress each photo before upload
      final compressed = await ImageCompressionService.compressImageFile(file, quality: 75);
      final finalPath = compressed?.path ?? file.path;

      if (_isFirebaseAvailable) {
        try {
          final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child('users/$userId/photos/$filename');
          await ref.putFile(File(finalPath));
          final downloadUrl = await ref.getDownloadURL();
          currentPhotos.add(downloadUrl);
        } catch (e) {
          debugPrint('Firebase storage photo upload error: $e');
          currentPhotos.add(finalPath);
        }
      } else {
        currentPhotos.add(finalPath);
      }
    }

    final updatedUser = _users[index].copyWith(
      photos: currentPhotos,
      updatedAt: DateTime.now(),
    );
    _users[index] = updatedUser;

    if (_currentUser?.id == userId) {
      _currentUser = updatedUser;
    }

    notifyListeners();
    return currentPhotos;
  }

  /// Remove a photo by index
  Future<void> removeProfilePhoto(String userId, int photoIndex) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1 && photoIndex < _users[index].photos.length) {
      final currentPhotos = List<String>.from(_users[index].photos);
      currentPhotos.removeAt(photoIndex);

      final updatedUser = _users[index].copyWith(photos: currentPhotos);
      _users[index] = updatedUser;

      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }
      notifyListeners();
    }
  }

  // ==================== DISCOVERY & SEARCH FILTER ====================

  /// Search and filter other approved profiles
  List<UserModel> getDiscoverProfiles({
    String? district,
    String? town,
    double? maxRadiusKm,
    String? genderPreference,
    String? searchQuery,
  }) {
    if (_currentUser == null) return [];

    final currentId = _currentUser!.id;
    final currentLat = _currentUser!.latitude ?? 6.9271;
    final currentLng = _currentUser!.longitude ?? 79.8612;

    return _users.where((user) {
      // Must be approved and not the current user, and not admin
      if (user.id == currentId || user.status != 'approved' || user.role == 'super_admin') {
        return false;
      }

      // Gender preference filter
      final pref = genderPreference ?? _currentUser!.preference;
      if (pref != 'Everyone') {
        if (pref == 'Men' && user.gender != 'Male') return false;
        if (pref == 'Women' && user.gender != 'Female') return false;
      }

      // District filter
      if (district != null && district.isNotEmpty && district != 'All Districts') {
        if (user.district.toLowerCase() != district.toLowerCase()) {
          return false;
        }
      }

      // Town filter
      if (town != null && town.isNotEmpty && town != 'All Towns') {
        if (!user.town.toLowerCase().contains(town.toLowerCase())) {
          return false;
        }
      }

      // Radius filter (Distance in KM)
      if (maxRadiusKm != null && maxRadiusKm > 0) {
        final targetLat = user.latitude ?? 6.9271;
        final targetLng = user.longitude ?? 79.8612;
        final distanceKm = LocationService.calculateDistanceKm(
          startLat: currentLat,
          startLng: currentLng,
          endLat: targetLat,
          endLng: targetLng,
        );
        if (distanceKm > maxRadiusKm) {
          return false;
        }
      }

      // Search query (name, bio, interests)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchesName = user.name.toLowerCase().contains(query);
        final matchesBio = user.bio.toLowerCase().contains(query);
        final matchesTown = user.town.toLowerCase().contains(query);
        final matchesInterests = user.interests.any((i) => i.toLowerCase().contains(query));
        if (!matchesName && !matchesBio && !matchesTown && !matchesInterests) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ==================== CONNECT REQUESTS & MATCHES ====================

  /// Send a connect request to another profile
  Future<({bool success, String message})> sendConnectRequest(String receiverId, {String? greeting}) async {
    if (_currentUser == null) return (success: false, message: 'Please log in first.');

    // Check if already connected or request pending
    final existingRequest = _requests.firstWhere(
      (r) => (r.senderId == _currentUser!.id && r.receiverId == receiverId) ||
             (r.senderId == receiverId && r.receiverId == _currentUser!.id),
      orElse: () => ConnectRequestModel(id: '', senderId: '', receiverId: '', senderName: '', senderPhoto: '', senderDistrict: '', senderAge: 0),
    );

    if (existingRequest.id.isNotEmpty) {
      if (existingRequest.isAccepted) {
        return (success: false, message: 'You are already connected with this profile!');
      }
      return (success: false, message: 'Connect request already sent or pending.');
    }

    final newRequest = ConnectRequestModel(
      id: _uuid.v4(),
      senderId: _currentUser!.id,
      receiverId: receiverId,
      senderName: _currentUser!.name,
      senderPhoto: _currentUser!.primaryPhoto,
      senderDistrict: _currentUser!.district,
      senderTown: _currentUser!.town,
      senderAge: _currentUser!.age,
      status: 'pending',
      message: greeting,
      createdAt: DateTime.now(),
    );

    _requests.add(newRequest);

    // Add notification for receiver
    _notifications.add(AppNotificationModel(
      id: _uuid.v4(),
      userId: receiverId,
      title: 'New Connect Request ❤️',
      body: '${_currentUser!.name} from ${_currentUser!.district} sent you a connect request.',
      type: 'connect_request',
      data: {'senderId': _currentUser!.id, 'requestId': newRequest.id},
    ));

    notifyListeners();
    return (success: true, message: 'Connect request sent successfully!');
  }

  /// Get pending requests received by current user
  List<ConnectRequestModel> getReceivedRequests() {
    if (_currentUser == null) return [];
    return _requests.where((r) => r.receiverId == _currentUser!.id && r.isPending).toList();
  }

  /// Get requests sent by current user
  List<ConnectRequestModel> getSentRequests() {
    if (_currentUser == null) return [];
    return _requests.where((r) => r.senderId == _currentUser!.id).toList();
  }

  /// Respond to a connect request (Accept or Decline)
  Future<bool> respondToConnectRequest(String requestId, {required bool accept}) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final request = _requests[index];
    final newStatus = accept ? 'accepted' : 'rejected';

    _requests[index] = ConnectRequestModel(
      id: request.id,
      senderId: request.senderId,
      receiverId: request.receiverId,
      senderName: request.senderName,
      senderPhoto: request.senderPhoto,
      senderDistrict: request.senderDistrict,
      senderTown: request.senderTown,
      senderAge: request.senderAge,
      status: newStatus,
      message: request.message,
      createdAt: request.createdAt,
    );

    if (accept) {
      // Create a match!
      final sender = _users.firstWhere((u) => u.id == request.senderId);
      final receiver = _currentUser!;

      final matchId = 'match_${request.senderId}_${receiver.id}';
      final newMatch = MatchModel(
        id: matchId,
        users: [request.senderId, receiver.id],
        lastMessage: 'You are now connected! Say hi 👋',
        lastMessageTime: DateTime.now(),
        userDetails: {
          sender.id: {
            'name': sender.name,
            'photo': sender.primaryPhoto,
            'district': sender.district,
          },
          receiver.id: {
            'name': receiver.name,
            'photo': receiver.primaryPhoto,
            'district': receiver.district,
          }
        },
      );

      _matches.add(newMatch);

      // Notify the sender that request was accepted
      _notifications.add(AppNotificationModel(
        id: _uuid.v4(),
        userId: request.senderId,
        title: 'New Match! 🎉',
        body: '${receiver.name} accepted your connect request! Start a conversation now.',
        type: 'connect_accepted',
        data: {'matchId': matchId, 'userId': receiver.id},
      ));
    }

    notifyListeners();
    return true;
  }

  // ==================== MATCHES & MESSAGING ====================

  /// Get all active matches for current user
  List<MatchModel> getMatches() {
    if (_currentUser == null) return [];
    return _matches.where((m) => m.users.contains(_currentUser!.id)).toList();
  }

  /// Get messages in a specific chat
  List<MessageModel> getChatMessages(String chatId) {
    return _messages.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Send a real-time message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    if (_currentUser == null || text.trim().isEmpty) return;

    final newMessage = MessageModel(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: _currentUser!.id,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    _messages.add(newMessage);

    // Update match last message
    final matchIndex = _matches.indexWhere((m) => m.id == chatId);
    if (matchIndex != -1) {
      final match = _matches[matchIndex];
      _matches[matchIndex] = MatchModel(
        id: match.id,
        users: match.users,
        lastMessage: text.trim(),
        lastMessageTime: DateTime.now(),
        userDetails: match.userDetails,
      );
    }

    notifyListeners();
  }

  // ==================== NOTIFICATIONS ====================

  List<AppNotificationModel> getNotifications() {
    if (_currentUser == null) return [];
    return _notifications.where((n) => n.userId == _currentUser!.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get unreadNotificationsCount {
    if (_currentUser == null) return 0;
    return _notifications.where((n) => n.userId == _currentUser!.id && !n.isRead).length;
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notif = _notifications[index];
      _notifications[index] = AppNotificationModel(
        id: notif.id,
        userId: notif.userId,
        title: notif.title,
        body: notif.body,
        type: notif.type,
        data: notif.data,
        createdAt: notif.createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }
}
