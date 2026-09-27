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
import '../firebase_options.dart';
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

  // In-Memory Database (Stores Super Admin and registered users)
  final List<UserModel> _users = [];
  final List<ConnectRequestModel> _requests = [];
  final List<MatchModel> _matches = [];
  final List<MessageModel> _messages = [];
  final List<AppNotificationModel> _notifications = [];

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseAvailable = true;
      debugPrint('Firebase initialized successfully: $_isFirebaseAvailable');
    } catch (e) {
      debugPrint('Firebase not configured or failed to initialize, running local engine: $e');
      _isFirebaseAvailable = false;
    }

    _users.clear();
    _requests.clear();
    _matches.clear();
    _messages.clear();
    _notifications.clear();

    // Ensure Super Admin is always registered in the system and created in Firebase
    await _ensureSuperAdminInFirebase();

    // If Firebase is available, sync real users and check active session
    if (_isFirebaseAvailable) {
      await _syncFromFirebase();

      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final existing = _users.where((u) => u.id == fbUser.uid || u.email.toLowerCase() == fbUser.email?.toLowerCase());
        if (existing.isNotEmpty) {
          _currentUser = existing.first;
        } else {
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }

    notifyListeners();
  }

  /// Automatically creates and configures the Super Admin account in Firebase Auth and Firestore
  Future<void> _ensureSuperAdminInFirebase() async {
    // Add super admin to local list
    if (!_users.any((u) => u.email == MockData.adminEmail)) {
      _users.add(MockData.superAdmin);
    }

    if (!_isFirebaseAvailable) return;

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      String adminUid = MockData.adminId;

      // 1. Try creating or verifying Super Admin in Firebase Auth
      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: MockData.adminEmail,
          password: MockData.adminDefaultPassword,
        );
        adminUid = credential.user?.uid ?? MockData.adminId;
        debugPrint('Super Admin user created in Firebase Auth: $adminUid');
      } on FirebaseAuthException catch (authErr) {
        if (authErr.code == 'email-already-in-use') {
          debugPrint('Super Admin email already registered in Firebase Auth.');
          try {
            // Check if we can sign in or retrieve UID
            final signInRes = await auth.signInWithEmailAndPassword(
              email: MockData.adminEmail,
              password: MockData.adminDefaultPassword,
            );
            adminUid = signInRes.user?.uid ?? MockData.adminId;
          } catch (_) {
            // Could have a custom password; query Firestore by email
            final query = await firestore
                .collection('users')
                .where('email', isEqualTo: MockData.adminEmail)
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              adminUid = query.docs.first.id;
            }
          }
        } else {
          debugPrint('Firebase Auth Super Admin initialization notice: $authErr');
        }
      }

      // 2. Ensure Super Admin document exists in Firestore
      final adminDoc = await firestore.collection('users').doc(adminUid).get();
      if (!adminDoc.exists) {
        final superAdminUser = MockData.superAdmin.copyWith(id: adminUid);
        await firestore.collection('users').doc(adminUid).set(superAdminUser.toMap(), SetOptions(merge: true));
        debugPrint('Created Super Admin document in Firestore: $adminUid');

        // Update in-memory reference
        final idx = _users.indexWhere((u) => u.email == MockData.adminEmail);
        if (idx != -1) {
          _users[idx] = superAdminUser;
        }
      } else {
        final existingAdmin = UserModel.fromMap(adminDoc.data()!, adminDoc.id);
        final idx = _users.indexWhere((u) => u.email == MockData.adminEmail);
        if (idx != -1) {
          _users[idx] = existingAdmin;
        }
      }
    } catch (e) {
      debugPrint('Error ensuring Super Admin in Firebase: $e');
    }
  }

  /// Sync real users, requests, and matches from Cloud Firestore
  Future<void> _syncFromFirebase() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch real users from Firestore
      final userDocs = await firestore.collection('users').get();
      for (final doc in userDocs.docs) {
        try {
          final user = UserModel.fromMap(doc.data(), doc.id);
          final idx = _users.indexWhere((u) => u.id == user.id);
          if (idx != -1) {
            _users[idx] = user;
          } else {
            _users.add(user);
          }
        } catch (e) {
          debugPrint('Error parsing user doc ${doc.id}: $e');
        }
      }

      // Ensure Super Admin remains
      if (!_users.any((u) => u.email == MockData.adminEmail)) {
        _users.add(MockData.superAdmin);
      }

      // 2. Fetch requests
      final reqDocs = await firestore.collection('connect_requests').get();
      _requests.clear();
      for (final doc in reqDocs.docs) {
        try {
          _requests.add(ConnectRequestModel.fromMap(doc.data(), doc.id));
        } catch (_) {}
      }

      // 3. Fetch matches
      final matchDocs = await firestore.collection('matches').get();
      _matches.clear();
      for (final doc in matchDocs.docs) {
        try {
          _matches.add(MatchModel.fromMap(doc.data(), doc.id));
        } catch (_) {}
      }

      // 4. Fetch notifications
      try {
        final notifDocs = await firestore.collection('notifications').get();
        _notifications.clear();
        for (final doc in notifDocs.docs) {
          try {
            _notifications.add(AppNotificationModel.fromMap(doc.data(), doc.id));
          } catch (_) {}
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error syncing from Firebase: $e');
    }
  }

  // ==================== AUTH & REGISTRATION ====================

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
      // 1. Compress verification documents before upload
      debugPrint('Compressing verification documents before upload...');
      final compressedSelfie = await ImageCompressionService.compressImageFile(selfieFile, quality: 75);
      final compressedNicFront = await ImageCompressionService.compressImageFile(nicFrontFile, quality: 80);
      final compressedNicBack = await ImageCompressionService.compressImageFile(nicBackFile, quality: 80);

      String selfieUrl = compressedSelfie?.path ?? selfieFile.path;
      String nicFrontUrl = compressedNicFront?.path ?? nicFrontFile.path;
      String nicBackUrl = compressedNicBack?.path ?? nicBackFile.path;

      String newUserId = _uuid.v4();

      // If Firebase is available, create account in Firebase Auth and upload to Storage
      if (_isFirebaseAvailable) {
        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
          newUserId = userCredential.user?.uid ?? newUserId;

          final storage = FirebaseStorage.instance;
          final selfieRef = storage.ref().child('verification/$newUserId/selfie.jpg');
          final nicFrontRef = storage.ref().child('verification/$newUserId/nic_front.jpg');
          final nicBackRef = storage.ref().child('verification/$newUserId/nic_back.jpg');
          final metadata = SettableMetadata(contentType: 'image/jpeg');

          if (compressedSelfie != null) {
            final task = await selfieRef.putFile(compressedSelfie, metadata);
            selfieUrl = await task.ref.getDownloadURL();
            debugPrint('Selfie uploaded to Firebase Storage: $selfieUrl');
          }
          if (compressedNicFront != null) {
            final task = await nicFrontRef.putFile(compressedNicFront, metadata);
            nicFrontUrl = await task.ref.getDownloadURL();
            debugPrint('NIC Front uploaded to Firebase Storage: $nicFrontUrl');
          }
          if (compressedNicBack != null) {
            final task = await nicBackRef.putFile(compressedNicBack, metadata);
            nicBackUrl = await task.ref.getDownloadURL();
            debugPrint('NIC Back uploaded to Firebase Storage: $nicBackUrl');
          }
        } catch (firebaseErr, stack) {
          debugPrint('⚠️ Firebase Storage upload failed: $firebaseErr');
          debugPrint('Stack trace: $stack');
        }
      }

      // Coordinates
      final coords = LocationService.getDistrictCoordinates(district);

      final newUser = UserModel(
        id: newUserId,
        email: email.trim(),
        name: name.trim(),
        age: age,
        gender: gender,
        preference: preference,
        district: district,
        town: town.trim(),
        bio: bio.trim(),
        interests: interests,
        photos: [selfieUrl],
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

      final notif = AppNotificationModel(
        id: _uuid.v4(),
        userId: newUser.id,
        title: 'Application Submitted 📝',
        body: 'Your identity documents are under review by the zing.lk Super Admin. You will be notified once verified.',
        type: 'verification_pending',
      );
      _notifications.add(notif);

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('notifications').doc(notif.id).set(notif.toMap());
        } catch (_) {}
      }

      _currentUser = newUser;
      notifyListeners();

      return (
        success: true,
        message: 'Registration submitted! Your profile is pending manual Super Admin verification.',
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

  /// Sign In with Email and Password (Firebase Auth + Firestore)
  Future<({bool success, String message, UserModel? user})> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      // 1. Authenticate with Firebase Auth if available
      if (_isFirebaseAvailable) {
        try {
          final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          final uid = credential.user?.uid;
          if (uid != null) {
            final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              final user = UserModel.fromMap(doc.data()!, doc.id);

              if (user.role != 'super_admin') {
                if (user.status == 'pending') {
                  _currentUser = user;
                  notifyListeners();
                  return (
                    success: false,
                    message: 'Your account verification is currently under review by our admin team.',
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
            }
          }
        } on FirebaseAuthException catch (authErr) {
          debugPrint('Firebase signIn error: ${authErr.code} - ${authErr.message}');
          // If not admin account, return the auth error
          if (cleanEmail != MockData.adminEmail.toLowerCase()) {
            return (
              success: false,
              message: authErr.message ?? 'Invalid email or password.',
              user: null,
            );
          }
        }
      }

      // 2. Super Admin fallback check
      if (cleanEmail == MockData.adminEmail.toLowerCase()) {
        if (cleanPassword == 'admin123' || cleanPassword == MockData.adminDefaultPassword) {
          _currentUser = MockData.superAdmin;
          notifyListeners();
          return (
            success: true,
            message: 'Welcome Super Admin!',
            user: MockData.superAdmin,
          );
        } else {
          return (
            success: false,
            message: 'Incorrect password for Super Admin.',
            user: null,
          );
        }
      }

      // 3. In-memory check (for users registered locally during offline run)
      final localUser = _users.firstWhere(
        (u) => u.email.toLowerCase() == cleanEmail,
        orElse: () => throw Exception('No account found with this email.'),
      );

      if (localUser.role != 'super_admin') {
        if (localUser.status == 'pending') {
          _currentUser = localUser;
          notifyListeners();
          return (
            success: false,
            message: 'Your account verification is currently under review by our admin team.',
            user: localUser,
          );
        } else if (localUser.status == 'rejected') {
          _currentUser = localUser;
          notifyListeners();
          return (
            success: false,
            message: 'Verification rejected: ${localUser.rejectionReason ?? "Identity could not be verified."}',
            user: localUser,
          );
        }
      }

      _currentUser = localUser;
      notifyListeners();

      return (
        success: true,
        message: 'Welcome back, ${localUser.name}!',
        user: localUser,
      );
    } catch (e) {
      return (
        success: false,
        message: e.toString().replaceAll('Exception: ', ''),
        user: null,
      );
    }
  }

  Future<void> logout() async {
    if (_isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Firebase signout error: $e');
      }
    }
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

      final notif = AppNotificationModel(
        id: _uuid.v4(),
        userId: userId,
        title: 'Account Verified! 🌟',
        body: 'Congratulations! Your zing.lk profile has been verified and approved by the Super Admin.',
        type: 'verification_approved',
      );
      _notifications.add(notif);

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
          await FirebaseFirestore.instance.collection('notifications').doc(notif.id).set(notif.toMap());
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

      final notif = AppNotificationModel(
        id: _uuid.v4(),
        userId: userId,
        title: 'Verification Update ⚠️',
        body: 'Your profile verification was declined: $reason. Please re-submit clear documents.',
        type: 'verification_rejected',
      );
      _notifications.add(notif);

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
          await FirebaseFirestore.instance.collection('notifications').doc(notif.id).set(notif.toMap());
        } catch (e) {
          debugPrint('Firestore reject update error: $e');
        }
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Resubmit updated verification documents after rejection
  Future<bool> resubmitVerificationDocuments({
    required String userId,
    File? selfieFile,
    File? nicFrontFile,
    File? nicBackFile,
  }) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    String selfieUrl = _users[index].selfieUrl;
    String nicFrontUrl = _users[index].nicFrontUrl;
    String nicBackUrl = _users[index].nicBackUrl;

    if (_isFirebaseAvailable) {
      try {
        final storage = FirebaseStorage.instance;
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        if (selfieFile != null) {
          final compressed = await ImageCompressionService.compressImageFile(selfieFile, quality: 75);
          final ref = storage.ref().child('verification/$userId/selfie.jpg');
          final task = await ref.putFile(compressed ?? selfieFile, metadata);
          selfieUrl = await task.ref.getDownloadURL();
          debugPrint('Resubmitted selfie uploaded: $selfieUrl');
        }
        if (nicFrontFile != null) {
          final compressed = await ImageCompressionService.compressImageFile(nicFrontFile, quality: 80);
          final ref = storage.ref().child('verification/$userId/nic_front.jpg');
          final task = await ref.putFile(compressed ?? nicFrontFile, metadata);
          nicFrontUrl = await task.ref.getDownloadURL();
          debugPrint('Resubmitted NIC front uploaded: $nicFrontUrl');
        }
        if (nicBackFile != null) {
          final compressed = await ImageCompressionService.compressImageFile(nicBackFile, quality: 80);
          final ref = storage.ref().child('verification/$userId/nic_back.jpg');
          final task = await ref.putFile(compressed ?? nicBackFile, metadata);
          nicBackUrl = await task.ref.getDownloadURL();
          debugPrint('Resubmitted NIC back uploaded: $nicBackUrl');
        }
      } catch (e) {
        debugPrint('Error uploading resubmitted verification documents: $e');
      }
    } else {
      if (selfieFile != null) selfieUrl = selfieFile.path;
      if (nicFrontFile != null) nicFrontUrl = nicFrontFile.path;
      if (nicBackFile != null) nicBackUrl = nicBackFile.path;
    }

    final updated = _users[index].copyWith(
      selfieUrl: selfieUrl,
      nicFrontUrl: nicFrontUrl,
      nicBackUrl: nicBackUrl,
      status: 'pending',
      rejectionReason: null,
      updatedAt: DateTime.now(),
    );

    return await updateProfile(updated);
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

  /// Upload up to 10 photos, compressing each before uploading to Firebase
  Future<List<String>> uploadProfilePhotos(String userId, List<File> newPhotoFiles) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return [];

    final currentPhotos = List<String>.from(_users[index].photos);
    final remainingSlots = 10 - currentPhotos.length;
    if (remainingSlots <= 0) return currentPhotos;

    final filesToProcess = newPhotoFiles.take(remainingSlots);

    for (final file in filesToProcess) {
      final compressed = await ImageCompressionService.compressImageFile(file, quality: 75);
      final finalPath = compressed?.path ?? file.path;

      if (_isFirebaseAvailable) {
        try {
          final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child('profile_photos/$userId/$filename');
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          final task = await ref.putFile(File(finalPath), metadata);
          final downloadUrl = await task.ref.getDownloadURL();
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

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'photos': currentPhotos,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
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

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'photos': currentPhotos,
          });
        } catch (_) {}
      }

      notifyListeners();
    }
  }

  // ==================== DISCOVERY & SEARCH FILTER ====================

  /// Search and filter other approved profiles (real registered profiles only)
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
      if (user.id == currentId || user.status != 'approved' || user.role == 'super_admin') {
        return false;
      }

      final pref = genderPreference ?? _currentUser!.preference;
      if (pref != 'Everyone') {
        if (pref == 'Men' && user.gender != 'Male') return false;
        if (pref == 'Women' && user.gender != 'Female') return false;
      }

      if (district != null && district.isNotEmpty && district != 'All Districts') {
        if (user.district.toLowerCase() != district.toLowerCase()) {
          return false;
        }
      }

      if (town != null && town.isNotEmpty && town != 'All Towns') {
        if (!user.town.toLowerCase().contains(town.toLowerCase())) {
          return false;
        }
      }

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

    final notif = AppNotificationModel(
      id: _uuid.v4(),
      userId: receiverId,
      title: 'New Connect Request ❤️',
      body: '${_currentUser!.name} sent you a connect request.',
      type: 'connect_request',
      data: {'senderId': _currentUser!.id, 'requestId': newRequest.id},
    );
    _notifications.add(notif);

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('connect_requests').doc(newRequest.id).set(newRequest.toMap());
        await FirebaseFirestore.instance.collection('notifications').doc(notif.id).set(notif.toMap());
      } catch (_) {}
    }

    notifyListeners();
    return (success: true, message: 'Connect request sent successfully!');
  }

  List<ConnectRequestModel> getReceivedRequests() {
    if (_currentUser == null) return [];
    return _requests.where((r) => r.receiverId == _currentUser!.id && r.isPending).toList();
  }

  List<ConnectRequestModel> getSentRequests() {
    if (_currentUser == null) return [];
    return _requests.where((r) => r.senderId == _currentUser!.id).toList();
  }

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

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('connect_requests').doc(requestId).update({'status': newStatus});
      } catch (_) {}
    }

    if (accept) {
      final sender = _users.firstWhere((u) => u.id == request.senderId, orElse: () => _currentUser!);
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

      final notif = AppNotificationModel(
        id: _uuid.v4(),
        userId: request.senderId,
        title: 'New Match! 🎉',
        body: '${receiver.name} accepted your connect request! Start a conversation now.',
        type: 'connect_accepted',
        data: {'matchId': matchId, 'userId': receiver.id},
      );
      _notifications.add(notif);

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance.collection('matches').doc(matchId).set(newMatch.toMap());
          await FirebaseFirestore.instance.collection('notifications').doc(notif.id).set(notif.toMap());
        } catch (_) {}
      }
    }

    notifyListeners();
    return true;
  }

  // ==================== MATCHES & MESSAGING ====================

  List<MatchModel> getMatches() {
    if (_currentUser == null) return [];
    return _matches.where((m) => m.users.contains(_currentUser!.id)).toList();
  }

  List<MessageModel> getChatMessages(String chatId) {
    return _messages.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

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

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc(newMessage.id).set(newMessage.toMap());
        await FirebaseFirestore.instance.collection('matches').doc(chatId).update({
          'lastMessage': text.trim(),
          'lastMessageTime': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
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

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      if (_isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(id)
              .set({'isRead': true}, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error marking notification read in Firestore: $e');
        }
      }
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUser == null) return;
    bool hasChanges = false;
    final List<String> updatedIds = [];

    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == _currentUser!.id && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
        updatedIds.add(_notifications[i].id);
      }
    }

    if (!hasChanges) return;

    // Immediately notify UI so the badge and list update without delay
    notifyListeners();

    if (_isFirebaseAvailable && updatedIds.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final id in updatedIds) {
          final docRef = FirebaseFirestore.instance.collection('notifications').doc(id);
          batch.set(docRef, {'isRead': true}, SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error committing batch mark all notifications read: $e');
      }
    }
  }
}
