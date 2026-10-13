import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../../services/image_compression_service.dart';
import '../home_shell.dart';
import 'welcome_screen.dart';

class VerificationStatusScreen extends StatefulWidget {
  final UserModel user;

  const VerificationStatusScreen({super.key, required this.user});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  late UserModel _user;
  bool _isChecking = false;

  // For resubmission if rejected
  File? _newSelfie;
  File? _newNicFront;
  File? _newNicBack;
  bool _isResubmitting = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _checkStatus() {
    setState(() => _isChecking = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      final backend = BackendService();
      // Reload user from backend
      final found = backend.getPendingVerifications().followedBy(backend.getApprovedUsers()).followedBy(backend.getRejectedUsers()).firstWhere(
        (u) => u.id == _user.id,
        orElse: () => _user,
      );

      setState(() {
        _user = found;
        _isChecking = false;
      });

      if (mounted && _user.isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('🎉 Your profile has been approved! Welcome to zing.lk'),
          ),
        );
      }
    });
  }

  Future<void> _captureFile({
    required Function(File) onPicked,
    bool isFrontCamera = false,
    ImageSource source = ImageSource.camera,
  }) async {
    final file = await ImageCompressionService.captureVerificationPhoto(
      isFrontCamera: isFrontCamera,
      source: source,
    );
    if (file != null) {
      setState(() {
        onPicked(file);
      });
    }
  }

  Future<void> _resubmitVerification() async {
    if (_newSelfie == null && _newNicFront == null && _newNicBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one document to update.')),
      );
      return;
    }

    setState(() => _isResubmitting = true);

    final backend = BackendService();
    await backend.resubmitVerificationDocuments(
      userId: _user.id,
      selfieFile: _newSelfie,
      nicFrontFile: _newNicFront,
      nicBackFile: _newNicBack,
    );

    // Refresh local user state
    final updated = backend.currentUser ?? _user;

    setState(() {
      _user = updated;
      _newSelfie = null;
      _newNicFront = null;
      _newNicBack = null;
      _isResubmitting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.primary,
          content: Text('Updated documents submitted for Admin review!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile Verification'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Log Out',
              onPressed: () {
                BackendService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              if (_user.isPending) _buildPendingCard(),
              if (_user.isRejected) _buildRejectedCard(),
              if (_user.isApproved) _buildApprovedCard(),
              const SizedBox(height: 24),
              _buildSubmittedDocumentsPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warning.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              color: AppTheme.warning,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verification Pending',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our Super Admin is manually verifying your Selfie and both sides of your Sri Lankan NIC to ensure real, authentic dating.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isChecking ? null : _checkStatus,
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(_isChecking ? 'Checking...' : 'Check Verification Status'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.error.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Verification Declined',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Reason from Super Admin:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error.withOpacity(0.2)),
            ),
            child: Text(
              _user.rejectionReason ?? 'Identity verification documents could not be validated. Please provide clearer photos.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF991B1B),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Re-upload Clear Documents:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildReuploadPicker(
            title: '1. Re-take Selfie Photo',
            file: _newSelfie,
            onCaptureCamera: () => _captureFile(
              onPicked: (f) => setState(() => _newSelfie = f),
              isFrontCamera: true,
              source: ImageSource.camera,
            ),
            onPickGallery: () => _captureFile(
              onPicked: (f) => setState(() => _newSelfie = f),
              isFrontCamera: true,
              source: ImageSource.gallery,
            ),
          ),
          const SizedBox(height: 10),
          _buildReuploadPicker(
            title: '2. Re-upload NIC Front Side',
            file: _newNicFront,
            onCaptureCamera: () => _captureFile(
              onPicked: (f) => setState(() => _newNicFront = f),
              isFrontCamera: false,
              source: ImageSource.camera,
            ),
            onPickGallery: () => _captureFile(
              onPicked: (f) => setState(() => _newNicFront = f),
              isFrontCamera: false,
              source: ImageSource.gallery,
            ),
          ),
          const SizedBox(height: 10),
          _buildReuploadPicker(
            title: '3. Re-upload NIC Back Side',
            file: _newNicBack,
            onCaptureCamera: () => _captureFile(
              onPicked: (f) => setState(() => _newNicBack = f),
              isFrontCamera: false,
              source: ImageSource.camera,
            ),
            onPickGallery: () => _captureFile(
              onPicked: (f) => setState(() => _newNicBack = f),
              isFrontCamera: false,
              source: ImageSource.gallery,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isResubmitting ? null : _resubmitVerification,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: _isResubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Resubmit for Admin Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.success.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppTheme.success,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profile Verified! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your identity has been manually checked and approved by the zing.lk team. You can now explore matches, send requests, and message other singles!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Enter zing.lk App'),
          ),
        ],
      ),
    );
  }

  Widget _buildReuploadPicker({
    required String title,
    required File? file,
    required VoidCallback onCaptureCamera,
    required VoidCallback onPickGallery,
  }) {
    final bool hasFile = file != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasFile ? AppTheme.success : AppTheme.border, width: hasFile ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onCaptureCamera, // Tapping row opens camera directly
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasFile ? AppTheme.success.withValues(alpha: 0.12) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: hasFile
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              file,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                  ),
                  if (hasFile)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasFile ? 'New photo captured ✓' : 'Tap camera to capture',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasFile ? AppTheme.success : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: onCaptureCamera,
                    icon: Icon(hasFile ? Icons.refresh_rounded : Icons.camera_alt_rounded, size: 14),
                    label: Text(hasFile ? 'Retake' : 'Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 34),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      backgroundColor: hasFile ? AppTheme.primaryDark : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onPickGallery,
                    tooltip: 'Choose from Gallery',
                    icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.textSecondary),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(34, 34),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedDocumentsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Submitted Verification Info',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _docRow('Full Name', _user.name),
          _docRow('Email', _user.email),
          _docRow('District / Town', '${_user.district} - ${_user.town}'),
          _docRow('Selfie Uploaded', _user.selfieUrl.isNotEmpty ? 'Yes (Compressed)' : 'No'),
          _docRow('NIC Front Uploaded', _user.nicFrontUrl.isNotEmpty ? 'Yes (Compressed)' : 'No'),
          _docRow('NIC Back Uploaded', _user.nicBackUrl.isNotEmpty ? 'Yes (Compressed)' : 'No'),
        ],
      ),
    );
  }

  Widget _docRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
