import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../../services/location_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  final UserModel user;

  const ProfileDetailScreen({super.key, required this.user});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final PageController _pageController = PageController();
  int _activePhotoIndex = 0;
  bool _isSending = false;

  void _sendConnectDialog() {
    final messageController = TextEditingController(
      text: 'Hi ${widget.user.name.split(" ").first}! I loved your profile and would love to connect.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Connect with ${widget.user.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a personal greeting. When they accept, you can start messaging!',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Say something nice...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isSending
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      setState(() => _isSending = true);
                      final result = await BackendService().sendConnectRequest(
                        widget.user.id,
                        greeting: messageController.text.trim(),
                      );
                      setState(() => _isSending = false);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: result.success ? AppTheme.primary : AppTheme.error,
                            content: Text(result.message),
                          ),
                        );
                      }
                    },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Send Connect Request'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        ),
      );
    } else if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.person, size: 64, color: Colors.grey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final photos = user.photos.isNotEmpty ? user.photos : [user.primaryPhoto];
    final currentUser = BackendService().currentUser;

    // Calculate distance
    String distanceText = '';
    if (currentUser != null && currentUser.latitude != null && currentUser.longitude != null && user.latitude != null && user.longitude != null) {
      final km = LocationService.calculateDistanceKm(
        startLat: currentUser.latitude!,
        startLng: currentUser.longitude!,
        endLat: user.latitude!,
        endLng: user.longitude!,
      );
      distanceText = '${km.toStringAsFixed(1)} km away';
    }

    return Scaffold(
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Photos Carousel
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    SizedBox(
                      height: 420,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: photos.length,
                        onPageChanged: (idx) => setState(() => _activePhotoIndex = idx),
                        itemBuilder: (context, index) {
                          return _buildPhotoWidget(photos[index]);
                        },
                      ),
                    ),
                    // Gradient overlay at bottom of photo
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Photo indicator dots & Counter
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(photos.length, (idx) {
                              final active = idx == _activePhotoIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 6),
                                width: active ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_activePhotoIndex + 1} / ${photos.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Profile Details Body
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Age & Verified Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.name}, ${user.age}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: AppTheme.success, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'NIC Verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Location & Distance
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${user.town.isNotEmpty ? "${user.town}, " : ""}${user.district}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                          if (distanceText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                distanceText,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // About Me / Bio
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio.isNotEmpty ? user.bio : 'No introduction provided.',
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Important Details Matrix
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDetailChip(Icons.person_outline, 'Gender', user.gender),
                          _buildDetailChip(Icons.favorite_outline, 'Looking For', user.preference),
                          if (user.height != null) _buildDetailChip(Icons.straighten, 'Height', user.height!),
                          if (user.occupation != null) _buildDetailChip(Icons.work_outline, 'Job', user.occupation!),
                          if (user.education != null) _buildDetailChip(Icons.school_outlined, 'Education', user.education!),
                          if (user.relationshipGoal != null) _buildDetailChip(Icons.diamond_outlined, 'Looking for', user.relationshipGoal!),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Interests
                      if (user.interests.isNotEmpty) ...[
                        const Text(
                          'Interests & Passions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Action Bar: Connect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _sendConnectDialog,
                icon: const Icon(Icons.favorite_rounded, size: 22),
                label: Text('Connect with ${user.name.split(" ").first}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
