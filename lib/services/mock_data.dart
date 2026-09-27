import '../models/user_model.dart';

class MockData {
  static const String adminEmail = 'admin@zing.lk';
  static const String adminDefaultPassword = 'Admin@Zing2026!';
  static const String adminId = 'super_admin_zing_lk';

  /// The only default account in the system: Super Admin
  static final UserModel superAdmin = UserModel(
    id: adminId,
    email: adminEmail,
    name: 'Zing Super Admin',
    age: 35,
    gender: 'Other',
    preference: 'Everyone',
    district: 'Colombo',
    town: 'Colombo 07 - Cinnamon Gardens',
    bio: 'Official Super Admin for zing.lk moderation & identity verification.',
    role: 'super_admin',
    status: 'approved',
    photos: const [],
    selfieUrl: '',
    nicFrontUrl: '',
    nicBackUrl: '',
  );
}
