import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_theme.dart';
import '../../constants/sri_lanka_data.dart';
import '../../services/backend_service.dart';
import '../../services/image_compression_service.dart';
import 'verification_status_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController(text: '24');
  final _bioController = TextEditingController();

  String _gender = 'Female';
  String _preference = 'Men';
  String _selectedDistrict = 'Colombo';
  late String _selectedTown;
  final List<String> _selectedInterests = ['Coffee & Cafes', 'Travel & Roadtrips'];

  File? _primaryPhotoFile;
  File? _selfieFile;
  File? _nicFrontFile;
  File? _nicBackFile;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final towns = SriLankaData.getTownsForDistrict(_selectedDistrict);
    _selectedTown = towns.isNotEmpty ? towns.first : 'Colombo 03';
  }

  Future<void> _captureDocumentPhoto({
    required Function(File) onPicked,
    bool isFrontCamera = false,
    ImageSource source = ImageSource.camera,
  }) async {
    final file = await ImageCompressionService.captureVerificationPhoto(
      isFrontCamera: isFrontCamera,
      source: source,
    );
    if (file != null) {
      setState(() {
        onPicked(file);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_primaryPhotoFile == null) {
      _showError('Please upload a Primary Profile Picture for your profile.');
      return;
    }
    if (_selfieFile == null) {
      _showError('Please upload a clear Selfie photo for NIC verification.');
      return;
    }
    if (_nicFrontFile == null) {
      _showError('Please upload the Front side of your Sri Lankan NIC.');
      return;
    }
    if (_nicBackFile == null) {
      _showError('Please upload the Back side of your Sri Lankan NIC.');
      return;
    }

    setState(() => _isLoading = true);

    final age = int.tryParse(_ageController.text.trim()) ?? 24;

    final result = await BackendService().registerWithVerification(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      age: age,
      gender: _gender,
      preference: _preference,
      district: _selectedDistrict,
      town: _selectedTown,
      bio: _bioController.text.trim(),
      interests: _selectedInterests,
      primaryPhotoFile: _primaryPhotoFile!,
      selfieFile: _selfieFile!,
      nicFrontFile: _nicFrontFile!,
      nicBackFile: _nicBackFile!,
    );

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationStatusScreen(user: result.user!),
        ),
      );
    } else {
      _showError(result.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.error,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile & Verify'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppTheme.primary, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'To protect members and eliminate fake profiles, every zing.lk user must be verified with Selfie & Sri Lankan NIC before activation.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Account credentials
                _sectionHeader('1. Account Information', Icons.lock_outline_rounded),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Kasun Fernando',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 24),

                // Section 2: Personal Details
                _sectionHeader('2. Profile Details', Icons.favorite_border_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'I am a'),
                        items: const [
                          DropdownMenuItem(value: 'Female', child: Text('Woman')),
                          DropdownMenuItem(value: 'Male', child: Text('Man')),
                          DropdownMenuItem(value: 'Other', child: Text('Non-binary')),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _preference,
                        decoration: const InputDecoration(labelText: 'Looking for'),
                        items: const [
                          DropdownMenuItem(value: 'Men', child: Text('Men')),
                          DropdownMenuItem(value: 'Women', child: Text('Women')),
                          DropdownMenuItem(value: 'Everyone', child: Text('Everyone')),
                        ],
                        onChanged: (v) => setState(() => _preference = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                        validator: (v) {
                          final a = int.tryParse(v ?? '');
                          if (a == null || a < 18) return '18+';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: SriLankaData.districts.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedDistrict = v;
                            final towns = SriLankaData.getTownsForDistrict(v);
                            _selectedTown = towns.isNotEmpty ? towns.first : v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: SriLankaData.getTownsForDistrict(_selectedDistrict).contains(_selectedTown)
                            ? _selectedTown
                            : (SriLankaData.getTownsForDistrict(_selectedDistrict).isNotEmpty
                                ? SriLankaData.getTownsForDistrict(_selectedDistrict).first
                                : null),
                        decoration: const InputDecoration(
                          labelText: 'Town / City',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        items: SriLankaData.getTownsForDistrict(_selectedDistrict).map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedTown = v);
                          }
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Select town' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Introduction / Bio',
                    hintText: 'Share a little bit about yourself, hobbies, or what makes you smile...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please write a short bio' : null,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Select Your Interests:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SriLankaData.commonInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
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
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Section 3: Public Profile Picture
                _sectionHeader('3. Primary Profile Picture (Public)', Icons.photo_camera_front_rounded),
                const SizedBox(height: 6),
                const Text(
                  'This is your main dating profile picture visible to potential matches.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),

                _buildDocUploadCard(
                  title: 'Primary Profile Picture',
                  subtitle: 'Select a clear, authentic photo of yourself',
                  icon: Icons.account_box_rounded,
                  file: _primaryPhotoFile,
                  onCaptureCamera: () => _captureDocumentPhoto(
                    onPicked: (f) => _primaryPhotoFile = f,
                    isFrontCamera: true,
                    source: ImageSource.camera,
                  ),
                  onPickGallery: () => _captureDocumentPhoto(
                    onPicked: (f) => _primaryPhotoFile = f,
                    isFrontCamera: false,
                    source: ImageSource.gallery,
                  ),
                ),
                const SizedBox(height: 24),

                // Section 4: Verification Documents (Admin Only)
                _sectionHeader('4. Identity Verification (Private - Admin Review Only)', Icons.verified_user_outlined),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selfie & NIC are reviewed strictly by Super Admin to verify identity and will NEVER be shown on your dating profile.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Selfie (For NIC verification only)
                _buildDocUploadCard(
                  title: 'A. Live Selfie Photo',
                  subtitle: 'Live selfie strictly for matching with your NIC photo',
                  icon: Icons.face_rounded,
                  file: _selfieFile,
                  onCaptureCamera: () => _captureDocumentPhoto(
                    onPicked: (f) => _selfieFile = f,
                    isFrontCamera: true,
                    source: ImageSource.camera,
                  ),
                  onPickGallery: () => _captureDocumentPhoto(
                    onPicked: (f) => _selfieFile = f,
                    isFrontCamera: true,
                    source: ImageSource.gallery,
                  ),
                ),
                const SizedBox(height: 12),

                // 2. NIC Front
                _buildDocUploadCard(
                  title: 'B. Sri Lankan NIC (Front Side)',
                  subtitle: 'Snap front side with rear camera',
                  icon: Icons.badge_rounded,
                  file: _nicFrontFile,
                  onCaptureCamera: () => _captureDocumentPhoto(
                    onPicked: (f) => _nicFrontFile = f,
                    isFrontCamera: false,
                    source: ImageSource.camera,
                  ),
                  onPickGallery: () => _captureDocumentPhoto(
                    onPicked: (f) => _nicFrontFile = f,
                    isFrontCamera: false,
                    source: ImageSource.gallery,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. NIC Back
                _buildDocUploadCard(
                  title: 'C. Sri Lankan NIC (Back Side)',
                  subtitle: 'Snap back side with rear camera',
                  icon: Icons.credit_card_rounded,
                  file: _nicBackFile,
                  onCaptureCamera: () => _captureDocumentPhoto(
                    onPicked: (f) => _nicBackFile = f,
                    isFrontCamera: false,
                    source: ImageSource.camera,
                  ),
                  onPickGallery: () => _captureDocumentPhoto(
                    onPicked: (f) => _nicBackFile = f,
                    isFrontCamera: false,
                    source: ImageSource.gallery,
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.how_to_reg_rounded),
                            SizedBox(width: 8),
                            Text('Submit Profile for Verification'),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onCaptureCamera,
    required VoidCallback onPickGallery,
  }) {
    final bool hasFile = file != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? AppTheme.success : AppTheme.border,
          width: hasFile ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onCaptureCamera, // Tapping card body directly opens camera
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: hasFile ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: hasFile
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              icon,
                              color: AppTheme.primary,
                              size: 26,
                            ),
                    ),
                    if (hasFile)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasFile ? 'Photo captured & compressed ✓' : subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasFile ? AppTheme.success : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary Camera Button (Opens Camera Directly)
                    ElevatedButton.icon(
                      onPressed: onCaptureCamera,
                      icon: Icon(hasFile ? Icons.refresh_rounded : Icons.camera_alt_rounded, size: 14),
                      label: Text(hasFile ? 'Retake' : 'Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        backgroundColor: hasFile ? AppTheme.primaryDark : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Secondary Gallery Button (Optional fallback)
                    IconButton(
                      onPressed: onPickGallery,
                      tooltip: 'Choose from Gallery',
                      icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.textSecondary),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(36, 36),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
