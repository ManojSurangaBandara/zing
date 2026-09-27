import 'dart:io';
import 'package:flutter/material.dart';
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
  final _townController = TextEditingController();
  final _bioController = TextEditingController();

  String _gender = 'Female';
  String _preference = 'Men';
  String _selectedDistrict = 'Colombo';
  final List<String> _selectedInterests = ['Coffee & Cafes', 'Travel & Roadtrips'];

  File? _selfieFile;
  File? _nicFrontFile;
  File? _nicBackFile;

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _pickImage(Function(File) onPicked) async {
    final xfile = await ImageCompressionService.pickImage();
    if (xfile != null) {
      final file = File(xfile.path);
      // Auto compress
      final compressed = await ImageCompressionService.compressImageFile(file);
      setState(() {
        onPicked(compressed ?? file);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selfieFile == null) {
      _showError('Please upload a clear Selfie photo for verification.');
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
      town: _townController.text.trim().isEmpty ? '$_selectedDistrict City' : _townController.text.trim(),
      bio: _bioController.text.trim(),
      interests: _selectedInterests,
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
    _townController.dispose();
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
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: SriLankaData.districts.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedDistrict = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _townController,
                        decoration: const InputDecoration(
                          labelText: 'Town / City',
                          hintText: 'e.g. Kollupitiya',
                        ),
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

                // Section 3: Verification Documents
                _sectionHeader('3. Verification Documents (Super Admin Review)', Icons.verified_user_outlined),
                const SizedBox(height: 6),
                const Text(
                  'All photos are compressed automatically before upload to save data.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),

                // 1. Selfie
                _buildDocUploadCard(
                  title: 'A. Live Selfie Photo',
                  subtitle: 'Take or choose a clear selfie showing your face',
                  icon: Icons.camera_alt_rounded,
                  file: _selfieFile,
                  onPick: () => _pickImage((f) => _selfieFile = f),
                ),
                const SizedBox(height: 12),

                // 2. NIC Front
                _buildDocUploadCard(
                  title: 'B. Sri Lankan NIC (Front Side)',
                  subtitle: 'Front side with photo and NIC number clearly visible',
                  icon: Icons.badge_rounded,
                  file: _nicFrontFile,
                  onPick: () => _pickImage((f) => _nicFrontFile = f),
                ),
                const SizedBox(height: 12),

                // 3. NIC Back
                _buildDocUploadCard(
                  title: 'C. Sri Lankan NIC (Back Side)',
                  subtitle: 'Back side showing address or barcode',
                  icon: Icons.credit_card_rounded,
                  file: _nicBackFile,
                  onPick: () => _pickImage((f) => _nicBackFile = f),
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
    required VoidCallback onPick,
  }) {
    final bool hasFile = file != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? AppTheme.success : AppTheme.border,
          width: hasFile ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasFile ? AppTheme.success.withOpacity(0.12) : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasFile ? Icons.check_circle_rounded : icon,
              color: hasFile ? AppTheme.success : AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasFile ? 'Image selected & compressed ✓' : subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: hasFile ? AppTheme.success : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(hasFile ? 'Change' : 'Upload'),
          ),
        ],
      ),
    );
  }
}
