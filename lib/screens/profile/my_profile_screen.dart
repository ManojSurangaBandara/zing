import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/sri_lanka_data.dart';
import '../../services/backend_service.dart';
import '../../services/mock_data.dart';
import '../../services/image_compression_service.dart';
import '../auth/welcome_screen.dart';
import '../admin/super_admin_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _townController;
  late TextEditingController _heightController;
  late TextEditingController _occupationController;
  late TextEditingController _educationController;

  late String _gender;
  late String _preference;
  late String _district;
  late String _relationshipGoal;
  late List<String> _interests;
  late List<String> _photos;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = BackendService().currentUser ?? MockData.superAdmin;

    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _townController = TextEditingController(text: user.town);
    _heightController = TextEditingController(text: user.height ?? '');
    _occupationController = TextEditingController(text: user.occupation ?? '');
    _educationController = TextEditingController(text: user.education ?? '');

    _gender = user.gender;
    _preference = user.preference;
    _district = user.district;
    _relationshipGoal = user.relationshipGoal ?? 'Serious relationship';
    _interests = List<String>.from(user.interests);
    _photos = List<String>.from(user.photos);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _townController.dispose();
    _heightController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_photos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum limit reached (up to 10 photos allowed).')),
      );
      return;
    }

    final xfile = await ImageCompressionService.pickImage();
    if (xfile == null) return;

    setState(() => _isUploadingPhoto = true);

    final backend = BackendService();
    final user = backend.currentUser;
    if (user != null) {
      final file = File(xfile.path);
      // Auto compress and upload
      final updatedPhotos = await backend.uploadProfilePhotos(user.id, [file]);
      setState(() {
        _photos = List<String>.from(updatedPhotos);
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Photo compressed & uploaded successfully!'),
          ),
        );
      }
    } else {
      setState(() => _isUploadingPhoto = false);
    }
  }

  void _removePhoto(int index) async {
    final backend = BackendService();
    final user = backend.currentUser;
    if (user != null) {
      await backend.removeProfilePhoto(user.id, index);
      setState(() {
        _photos.removeAt(index);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final backend = BackendService();
    final user = backend.currentUser;
    if (user != null) {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        gender: _gender,
        preference: _preference,
        district: _district,
        town: _townController.text.trim(),
        height: _heightController.text.trim().isNotEmpty ? _heightController.text.trim() : null,
        occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        education: _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
        relationshipGoal: _relationshipGoal,
        interests: _interests,
        photos: _photos,
        updatedAt: DateTime.now(),
      );

      await backend.updateProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Profile updated successfully! ✨'),
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  Widget _buildPhotoThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
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
    final user = backend.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Verification & Safety Badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withOpacity(0.12),
                      const Color(0xFFECFDF5).withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NIC & Selfie Verified Member ✓',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.success),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified by zing.lk Super Admin. Real Sri Lankan profile.',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Photos Section (Up to 10 photos)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Photos (Up to 10)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${_photos.length} / 10',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Photos are compressed before upload to reduce data and load instantly.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Photos Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: _photos.length < 10 ? _photos.length + 1 : 10,
                itemBuilder: (context, index) {
                  // Add Photo Button slot
                  if (index == _photos.length && _photos.length < 10) {
                    return InkWell(
                      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.4), style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isUploadingPhoto)
                              const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)
                            else ...[
                              const Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 28),
                              const SizedBox(height: 6),
                              const Text(
                                'Add Photo',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  final photoPath = _photos[index];
                  final isPrimary = index == 0;

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: _buildPhotoThumbnail(photoPath),
                        ),
                      ),
                      // Primary photo pill
                      if (isPrimary)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // User details form
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Introduction / Bio',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Female', child: Text('Woman')),
                        DropdownMenuItem(value: 'Male', child: Text('Man')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _preference,
                      decoration: const InputDecoration(labelText: 'Preference'),
                      items: const [
                        DropdownMenuItem(value: 'Men', child: Text('Men')),
                        DropdownMenuItem(value: 'Women', child: Text('Women')),
                        DropdownMenuItem(value: 'Everyone', child: Text('Everyone')),
                      ],
                      onChanged: (v) => setState(() => _preference = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _district,
                      decoration: const InputDecoration(labelText: 'District'),
                      items: SriLankaData.districts.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _district = v;
                          final towns = SriLankaData.getTownsForDistrict(v);
                          _townController.text = towns.isNotEmpty ? towns.first : v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: () {
                        final towns = SriLankaData.getTownsForDistrict(_district);
                        if (towns.contains(_townController.text)) {
                          return _townController.text;
                        }
                        return towns.isNotEmpty ? towns.first : null;
                      }(),
                      decoration: const InputDecoration(labelText: 'Town / City'),
                      items: () {
                        final towns = List<String>.from(SriLankaData.getTownsForDistrict(_district));
                        if (_townController.text.isNotEmpty && !towns.contains(_townController.text)) {
                          towns.insert(0, _townController.text);
                        }
                        return towns.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis),
                          );
                        }).toList();
                      }(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _townController.text = v);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Interests (Tap to select)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SriLankaData.commonInterests.map((interest) {
                  final isSelected = _interests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _interests.add(interest);
                        } else {
                          _interests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Other important details
              const Text(
                'Other Important Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height', hintText: 'e.g. 5\' 7"'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _relationshipGoal,
                      decoration: const InputDecoration(labelText: 'Looking for'),
                      items: const [
                        DropdownMenuItem(value: 'Serious relationship', child: Text('Serious relationship')),
                        DropdownMenuItem(value: 'Dating & Marriage', child: Text('Dating & Marriage')),
                        DropdownMenuItem(value: 'Casual dating', child: Text('Casual dating')),
                        DropdownMenuItem(value: 'Friendship', child: Text('Friendship')),
                      ],
                      onChanged: (v) => setState(() => _relationshipGoal = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Occupation / Job', hintText: 'e.g. Software Engineer, Doctor'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(labelText: 'Education', hintText: 'e.g. University Graduate'),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile Changes'),
              ),
              const SizedBox(height: 20),

              // Admin / Role switcher for testing
              if (user?.isSuperAdmin == true || user?.email == 'admin@zing.lk')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text('Open Super Admin Panel'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  ),
                ),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () {
                  backend.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
