import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../auth/welcome_screen.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approveUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Profile Verification?'),
        content: Text('Are you sure you want to approve ${user.name}? This will verify their profile and enable full app access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Confirm & Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BackendService().approveUserVerification(user.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Approved ${user.name}! User has been notified.'),
          ),
        );
      }
    }
  }

  void _rejectUser(UserModel user) {
    final reasonController = TextEditingController();
    final List<String> commonReasons = [
      'NIC front side is blurry or unreadable.',
      'Selfie does not match NIC portrait photo.',
      'NIC back side is dark or missing barcode/details.',
      'Invalid or suspected unofficial identity document.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Reject Verification: ${user.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Please specify a clear reason. The user will be notified and can re-upload their documents accordingly.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              const Text(
                'Quick Reason Templates:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonReasons.map((r) {
                  return ActionChip(
                    label: Text(r, style: const TextStyle(fontSize: 11.5)),
                    backgroundColor: Colors.grey.shade100,
                    onPressed: () {
                      reasonController.text = r;
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason (Sent to User)',
                  hintText: 'Enter specific instructions for the applicant...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a rejection reason.')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        await BackendService().rejectUserVerification(user.id, reason);
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.error,
                              content: Text('Verification rejected for ${user.name}. Reason delivered.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      child: const Text('Confirm Reject'),
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

  void _showDocumentZoom(String title, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: InteractiveViewer(
                child: _buildImageWidget(imagePath, height: 350, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path, {double? height, BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        height: height,
        fit: fit,
      );
    } else {
      return Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();
    final pending = backend.getPendingVerifications();
    final approved = backend.getApprovedUsers();
    final rejected = backend.getRejectedUsers();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppTheme.gold, size: 22),
            SizedBox(width: 8),
            Text(
              'zing.lk Super Admin',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () {
              backend.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: pending.isNotEmpty ? AppTheme.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pending.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Approved'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${approved.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Rejected'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${rejected.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Pending Tab
          _buildUserList(
            users: pending,
            emptyMessage: 'No pending verifications! All profiles reviewed. ✨',
            isPendingTab: true,
          ),
          // 2. Approved Tab
          _buildUserList(
            users: approved,
            emptyMessage: 'No approved profiles yet.',
            isPendingTab: false,
          ),
          // 3. Rejected Tab
          _buildUserList(
            users: rejected,
            emptyMessage: 'No rejected profiles.',
            isPendingTab: false,
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({
    required List<UserModel> users,
    required String emptyMessage,
    required bool isPendingTab,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildVerificationCard(user, isPendingTab: isPendingTab);
      },
    );
  }

  Widget _buildVerificationCard(UserModel user, {required bool isPendingTab}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: User basic info & Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: _buildImageWidget(user.primaryPhoto),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${user.name}, ${user.age}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.gender,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${user.district} (${user.town})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(user.status),
              ],
            ),
            const SizedBox(height: 12),

            // Bio
            if (user.bio.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '"${user.bio}"',
                  style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Rejection reason if already rejected
            if (user.isRejected && user.rejectionReason != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection reason: ${user.rejectionReason}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Text(
              'Identity Documents (Tap photo to Zoom):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Verification Assets: Selfie, NIC Front, NIC Back
            Row(
              children: [
                Expanded(
                  child: _buildDocThumbnail(
                    label: 'Live Selfie',
                    imagePath: user.selfieUrl,
                    onTap: () => _showDocumentZoom('Live Selfie Photo - ${user.name}', user.selfieUrl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDocThumbnail(
                    label: 'NIC Front',
                    imagePath: user.nicFrontUrl,
                    onTap: () => _showDocumentZoom('Sri Lankan NIC (Front) - ${user.name}', user.nicFrontUrl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDocThumbnail(
                    label: 'NIC Back',
                    imagePath: user.nicBackUrl,
                    onTap: () => _showDocumentZoom('Sri Lankan NIC (Back) - ${user.name}', user.nicBackUrl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Admin Action Buttons
            Row(
              children: [
                if (!user.isApproved)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveUser(user),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Approve & Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                if (!user.isApproved && !user.isRejected) const SizedBox(width: 12),
                if (!user.isRejected)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectUser(user),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject with Reason'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocThumbnail({
    required String label,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 80,
                child: _buildImageWidget(imagePath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'approved':
        bg = AppTheme.success.withOpacity(0.12);
        fg = AppTheme.success;
        text = 'Approved ✓';
        break;
      case 'rejected':
        bg = AppTheme.error.withOpacity(0.12);
        fg = AppTheme.error;
        text = 'Rejected ✕';
        break;
      default:
        bg = AppTheme.warning.withOpacity(0.15);
        fg = const Color(0xFFB45309);
        text = 'Pending Review';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
