import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/backend_service.dart';
import 'discover/discover_screen.dart';
import 'requests/connect_requests_screen.dart';
import 'chat/matches_and_chat_screen.dart';
import 'profile/my_profile_screen.dart';
import 'admin/super_admin_screen.dart';

class HomeShell extends StatefulWidget {
  final int initialTab;

  const HomeShell({super.key, this.initialTab = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _showNotificationSheet() {
    final backend = BackendService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final notifs = backend.getNotifications();
          final hasUnread = notifs.any((n) => !n.isRead);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications 🔔',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    if (hasUnread)
                      TextButton(
                        onPressed: () async {
                          await backend.markAllNotificationsRead();
                          setSheetState(() {});
                          if (mounted) setState(() {});
                        },
                        child: const Text('Mark all read'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: notifs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No notifications yet', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: notifs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final n = notifs[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.type.contains('approved')
                                      ? AppTheme.success.withValues(alpha: 0.12)
                                      : n.type.contains('rejected')
                                          ? AppTheme.error.withValues(alpha: 0.12)
                                          : AppTheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  n.type.contains('approved')
                                      ? Icons.verified
                                      : n.type.contains('rejected')
                                          ? Icons.error_outline
                                          : Icons.favorite,
                                  color: n.type.contains('approved')
                                      ? AppTheme.success
                                      : n.type.contains('rejected')
                                          ? AppTheme.error
                                          : AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: Text(
                                n.body,
                                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                              ),
                              trailing: !n.isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () async {
                                await backend.markNotificationRead(n.id);
                                if (context.mounted) {
                                  setSheetState(() {});
                                }
                                if (mounted) {
                                  setState(() {});
                                }
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (n.type == 'connect_request') {
                                  setState(() => _currentIndex = 1);
                                } else if (n.type == 'connect_accepted') {
                                  setState(() => _currentIndex = 2);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();
    final user = backend.currentUser;
    final receivedRequestsCount = backend.getReceivedRequests().length;

    final screens = [
      DiscoverScreen(onOpenNotifications: _showNotificationSheet),
      const ConnectRequestsScreen(),
      const MatchesAndChatScreen(),
      const MyProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: (user != null && user.isSuperAdmin)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
              label: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF6366F1),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppTheme.primary.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded, color: AppTheme.primary),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: receivedRequestsCount > 0,
              label: Text('$receivedRequestsCount'),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.favorite_border_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: receivedRequestsCount > 0,
              label: Text('$receivedRequestsCount'),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.favorite_rounded, color: AppTheme.primary),
            ),
            label: 'Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppTheme.primary),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
