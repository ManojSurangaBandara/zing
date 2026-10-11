import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/connect_request_model.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../chat/chat_detail_screen.dart';
import '../discover/profile_detail_screen.dart';

class ConnectRequestsScreen extends StatefulWidget {
  const ConnectRequestsScreen({super.key});

  @override
  State<ConnectRequestsScreen> createState() => _ConnectRequestsScreenState();
}

class _ConnectRequestsScreenState extends State<ConnectRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    BackendService().addListener(_onBackendChange);
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onBackendChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BackendService().removeListener(_onBackendChange);
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
      );
    } else if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    } else {
      return Container(color: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey));
    }
  }

  Future<void> _openSenderProfile(ConnectRequestModel req) async {
    final backend = BackendService();
    UserModel? user = await backend.fetchUserById(req.senderId);
    user ??= UserModel(
      id: req.senderId,
      email: '',
      name: req.senderName,
      age: req.senderAge,
      gender: 'Member',
      preference: 'Everyone',
      district: req.senderDistrict,
      town: req.senderTown,
      bio: req.message ?? '',
      photos: req.senderPhoto.isNotEmpty ? [req.senderPhoto] : const [],
      interests: const [],
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(user: user!),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _openReceiverProfile(ConnectRequestModel req) async {
    final backend = BackendService();
    UserModel? user = await backend.fetchUserById(req.receiverId);
    if (user != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileDetailScreen(user: user),
        ),
      );
      if (mounted) setState(() {});
    }
  }

  void _respond(ConnectRequestModel request, bool accept) async {
    final backend = BackendService();
    final success = await backend.respondToConnectRequest(request.id, accept: accept);
    if (success && accept) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('🎉 Connected with ${request.senderName}! You can now chat.'),
            action: SnackBarAction(
              label: 'Chat Now',
              textColor: Colors.white,
              onPressed: () {
                final matchId = 'match_${request.senderId}_${backend.currentUser!.id}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: matchId,
                      otherUserId: request.senderId,
                      otherUserName: request.senderName,
                      otherUserPhoto: request.senderPhoto,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();
    final received = backend.getReceivedRequests();
    final sent = backend.getSentRequests();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Received'),
                  if (received.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${received.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Sent (${sent.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Received Tab
          received.isEmpty
              ? _buildEmptyState('No pending connect requests received.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: received.length,
                  itemBuilder: (context, index) {
                    final req = received[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openSenderProfile(req),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: _buildPhoto(req.senderPhoto),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${req.senderName}, ${req.senderAge}',
                                          style: const TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 13, color: AppTheme.primary),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${req.senderTown.isNotEmpty ? "${req.senderTown}, " : ""}${req.senderDistrict}',
                                              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View Profile',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primary),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (req.message != null && req.message!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    '"${req.message}"',
                                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respond(req, false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textSecondary,
                                        side: const BorderSide(color: AppTheme.border),
                                        minimumSize: const Size.fromHeight(38),
                                      ),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respond(req, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        minimumSize: const Size.fromHeight(38),
                                      ),
                                      child: const Text('Accept & Match'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Sent Tab
          sent.isEmpty
              ? _buildEmptyState('You haven\'t sent any connect requests yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sent.length,
                  itemBuilder: (context, index) {
                    final req = sent[index];
                    final receiver = backend.getUserById(req.receiverId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openReceiverProfile(req),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: receiver != null && receiver.primaryPhoto.isNotEmpty
                                  ? _buildPhoto(receiver.primaryPhoto)
                                  : Container(
                                      color: AppTheme.accent,
                                      child: const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 20),
                                    ),
                            ),
                          ),
                          title: Text(
                            receiver != null ? receiver.name : 'Request to member',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          subtitle: Text(
                            req.isAccepted ? 'Connected! Chat unlocked 🎉' : 'Status: Pending response...',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: req.isAccepted ? AppTheme.success : AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: req.isAccepted
                                      ? AppTheme.success.withValues(alpha: 0.12)
                                      : AppTheme.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  req.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: req.isAccepted ? AppTheme.success : AppTheme.warning,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
