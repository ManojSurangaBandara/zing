import 'package:flutter_test/flutter_test.dart';
import 'package:zing/main.dart';
import 'package:zing/services/backend_service.dart';

void main() {
  testWidgets('ZingApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZingApp());
    expect(find.byType(ZingApp), findsOneWidget);
  });

  test('BackendService markNotificationRead and markAllNotificationsRead test', () async {
    final backend = BackendService();
    // Verify notifications count doesn't crash
    expect(backend.unreadNotificationsCount, greaterThanOrEqualTo(0));
    await backend.markAllNotificationsRead();
    expect(backend.unreadNotificationsCount, equals(0));
  });

  test('Super Admin is never shown in discovery feed for other users', () {
    final backend = BackendService();
    final discoverProfiles = backend.getDiscoverProfiles();
    for (final profile in discoverProfiles) {
      expect(profile.isSuperAdmin, isFalse);
      expect(profile.role, isNot('admin'));
      expect(profile.role, isNot('super_admin'));
      expect(profile.email.toLowerCase(), isNot('admin@zing.lk'));
      expect(profile.id, isNot('super_admin_zing_lk'));
    }
  });
}
