import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../services/backend_service.dart';
import 'chat_detail_screen.dart';

class MatchesAndChatScreen extends StatefulWidget {
  const MatchesAndChatScreen({super.key});

  @override
  State<MatchesAndChatScreen> createState() => _MatchesAndChatScreenState();
}

class _MatchesAndChatScreenState extends State<MatchesAndChatScreen> {
  Widget _buildPhoto(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
      );
    } else if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    } else {
      return const Icon(Icons.person, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();
    final myId = backend.currentUser?.id ?? '';
    final matches = backend.getMatches();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Messages'),
      ),
      body: matches.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No Conversations Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Send connect requests to profiles on the Discover page. When someone accepts, you can start messaging here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // New Matches Carousel
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                    child: Text(
                      'New Matches (${matches.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  SizedBox(
                    height: 95,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final m = matches[index];
                        final otherId = m.getOtherUserId(myId);
                        final details = m.userDetails[otherId] ?? {};
                        final name = details['name'] ?? 'Match';
                        final photo = details['photo'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chatId: m.id,
                                  otherUserId: otherId,
                                  otherUserName: name,
                                  otherUserPhoto: photo,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [AppTheme.primary, AppTheme.gold],
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: _buildPhoto(photo),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    name.split(' ').first,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 20),

                  // Messages List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      'Messages',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
                    itemBuilder: (context, index) {
                      final m = matches[index];
                      final otherId = m.getOtherUserId(myId);
                      final details = m.userDetails[otherId] ?? {};
                      final name = details['name'] ?? 'Match';
                      final photo = details['photo'] ?? '';
                      final timeStr = DateFormat('h:mm a').format(m.lastMessageTime);

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                chatId: m.id,
                                otherUserId: otherId,
                                otherUserName: name,
                                otherUserPhoto: photo,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: _buildPhoto(photo),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          m.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
