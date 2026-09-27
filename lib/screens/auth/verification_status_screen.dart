import 'dart:io';
import 'package:flutter/material.dart';
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

      if (_user.isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('🎉 Your profile has been approved! Welcome to zing.lk'),
          ),
        );
      }
    });
  }

  Future<void> _pickFile(Function(File) onPicked) async {
    final xfile = await ImageCompressionService.pickImage();
    if (xfile != null) {
      final file = File(xfile.path);
      final compressed = await ImageCompressionService.compressImageFile(file);
      onPicked(compressed ?? file);
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
    final updated = _user.copyWith(
      selfieUrl: _newSelfie?.path ?? _user.selfieUrl,
      nicFrontUrl: _newNicFront?.path ?? _user.nicFrontUrl,
      nicBackUrl: _newNicBack?.path ?? _user.nicBackUrl,
      status: 'pending',
      rejectionReason: null,
      updatedAt: DateTime.now(),
    );

    await backend.updateProfile(updated);

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
    return Scaffold(
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
            onTap: () => _pickFile((f) => setState(() => _newSelfie = f)),
          ),
          const SizedBox(height: 10),
          _buildReuploadPicker(
            title: '2. Re-upload NIC Front Side',
            file: _newNicFront,
            onTap: () => _pickFile((f) => setState(() => _newNicFront = f)),
          ),
          const SizedBox(height: 10),
          _buildReuploadPicker(
            title: '3. Re-upload NIC Back Side',
            file: _newNicBack,
            onTap: () => _pickFile((f) => setState(() => _newNicBack = f)),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeShell()),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
              color: file != null ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file != null ? 'New photo selected ✓' : title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: file != null ? FontWeight.w700 : FontWeight.w500,
                  color: file != null ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              file != null ? 'Change' : 'Select',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
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
