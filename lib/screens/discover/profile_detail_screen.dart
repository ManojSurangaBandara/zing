import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../../services/location_service.dart';
import '../chat/chat_detail_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final UserModel user;
  final bool autoOpenConnect;

  const ProfileDetailScreen({
    super.key,
    required this.user,
    this.autoOpenConnect = false,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final PageController _pageController = PageController();
  int _activePhotoIndex = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    BackendService().addListener(_onBackendChange);
    if (widget.autoOpenConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final backend = BackendService();
        final hasSent = backend.hasSentConnectRequestTo(widget.user.id);
        final isConnected = backend.isConnectedWith(widget.user.id);
        if (!hasSent && !isConnected && mounted) {
          _sendConnectDialog();
        }
      });
    }
  }

  void _onBackendChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BackendService().removeListener(_onBackendChange);
    _pageController.dispose();
    super.dispose();
  }

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
    final backend = BackendService();
    final currentUser = backend.currentUser;
    final hasReceivedRequest = backend.hasReceivedConnectRequestFrom(user.id);

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
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: photos.length,
                        onPageChanged: (idx) => setState(() => _activePhotoIndex = idx),
                        itemBuilder: (context, index) {
                          return _buildPhotoWidget(photos[index]);
                        },
                      ),
                    ),
                    // Gradient overlay at bottom of photo (IgnorePointer to avoid blocking swipes)
                    IgnorePointer(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Photo indicator dots & Counter (IgnorePointer to allow horizontal swipe pass-through)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: IgnorePointer(
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

                      // If there is an incoming connect request with a personal message, display it
                      if (hasReceivedRequest) ...[
                        Builder(
                          builder: (context) {
                            final req = backend.getConnectRequestWith(user.id);
                            if (req?.message != null && req!.message!.isNotEmpty) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.favorite_rounded, size: 16, color: AppTheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Message from ${user.name.split(" ").first}:',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '"${req.message}"',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],

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
                      const SizedBox(height: 90),
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

          // Bottom Action Bar: Conditional based on connect status
          _buildBottomActionBar(user),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(UserModel user) {
    final backend = BackendService();
    final isSelf = backend.currentUser?.id == user.id;
    if (isSelf) return const SizedBox.shrink();

    final isConnected = backend.isConnectedWith(user.id);
    final hasSentRequest = backend.hasSentConnectRequestTo(user.id);
    final hasReceivedRequest = backend.hasReceivedConnectRequestFrom(user.id);
    final isRejected = backend.isConnectRequestRejected(user.id);
    final firstName = user.name.split(" ").first;

    Widget actionWidget;

    if (isConnected) {
      actionWidget = ElevatedButton.icon(
        onPressed: () {
          final myId = backend.currentUser?.id ?? '';
          final matchId = 'match_${user.id}_$myId';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatId: matchId,
                otherUserId: user.id,
                otherUserName: user.name,
                otherUserPhoto: user.primaryPhoto,
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
        label: Text('Connected! Chat with $firstName'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else if (hasSentRequest) {
      // Connect request already sent: Do NOT show connect button!
      actionWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1), // Amber 50
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.2), // Amber 300
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFFF8F00), size: 20),
            SizedBox(width: 8),
            Text(
              'Connect Request Sent • Pending Response',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF6F00),
              ),
            ),
          ],
        ),
      );
    } else if (hasReceivedRequest) {
      final request = backend.getConnectRequestWith(user.id);
      actionWidget = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                if (request != null) {
                  await backend.respondToConnectRequest(request.id, accept: false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Declined connect request from $firstName'),
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (request != null) {
                  final success = await backend.respondToConnectRequest(request.id, accept: true);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.success,
                        content: Text('🎉 Connected with $firstName! You can now chat.'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.favorite_rounded, size: 20),
              label: const Text('Accept & Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );
    } else if (isRejected) {
      actionWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Connect Request Declined',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      // Connect request NOT sent yet: Show Connect button
      actionWidget = ElevatedButton.icon(
        onPressed: _sendConnectDialog,
        icon: const Icon(Icons.favorite_rounded, size: 22),
        label: Text('Connect with $firstName'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    return Positioned(
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
        child: actionWidget,
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
