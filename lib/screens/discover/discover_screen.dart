import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/sri_lanka_data.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../../services/location_service.dart';
import 'profile_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onOpenNotifications;

  const DiscoverScreen({super.key, this.onOpenNotifications});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selectedDistrict = 'All Districts';
  String _townQuery = '';
  double _radiusKm = 50.0; // 50km default
  bool _enableRadiusFilter = false;
  String _genderPreference = 'Everyone';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = BackendService().currentUser;
    if (user != null) {
      _genderPreference = user.preference;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    String tempDistrict = _selectedDistrict;
    String tempTown = _townQuery;
    double tempRadius = _radiusKm;
    bool tempEnableRadius = _enableRadiusFilter;
    String tempGender = _genderPreference;
    final townCtrl = TextEditingController(text: tempTown);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Profiles 🇱🇰',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          tempDistrict = 'All Districts';
                          tempTown = '';
                          townCtrl.clear();
                          tempRadius = 50;
                          tempEnableRadius = false;
                          tempGender = 'Everyone';
                        });
                      },
                      child: const Text('Reset', style: TextStyle(color: AppTheme.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // District dropdown
                const Text('District:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: tempDistrict,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.map_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: ['All Districts', ...SriLankaData.districts].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (v) => setSheetState(() => tempDistrict = v!),
                ),
                const SizedBox(height: 14),

                // Town text
                const Text('Town / City:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: townCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Kollupitiya, Galle Fort, Kandy City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) => tempTown = v.trim(),
                ),
                const SizedBox(height: 16),

                // Distance Radius
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Distance Radius:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Text(
                          tempEnableRadius ? '${tempRadius.round()} km' : 'Any distance',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                        Switch(
                          value: tempEnableRadius,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setSheetState(() => tempEnableRadius = val),
                        ),
                      ],
                    ),
                  ],
                ),
                if (tempEnableRadius) ...[
                  Slider(
                    value: tempRadius,
                    min: 5,
                    max: 150,
                    divisions: 29,
                    activeColor: AppTheme.primary,
                    label: '${tempRadius.round()} km',
                    onChanged: (val) => setSheetState(() => tempRadius = val),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5 km', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text('75 km', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text('150 km', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Looking for
                const Text('Interested in:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: ['Men', 'Women', 'Everyone'].map((opt) {
                    final selected = tempGender == opt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Center(child: Text(opt)),
                          selected: selected,
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          onSelected: (_) => setSheetState(() => tempGender = opt),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedDistrict = tempDistrict;
                      _townQuery = tempTown;
                      _radiusKm = tempRadius;
                      _enableRadiusFilter = tempEnableRadius;
                      _genderPreference = tempGender;
                    });
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
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
        child: const Center(child: Icon(Icons.person, color: Colors.grey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();
    final currentUser = backend.currentUser;

    final profiles = backend.getDiscoverProfiles(
      district: _selectedDistrict,
      town: _townQuery,
      maxRadiusKm: _enableRadiusFilter ? _radiusKm : null,
      genderPreference: _genderPreference,
      searchQuery: _searchQuery,
    );

    final hasActiveFilters = _selectedDistrict != 'All Districts' ||
        _townQuery.isNotEmpty ||
        _enableRadiusFilter ||
        _genderPreference != 'Everyone';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'zing',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                  TextSpan(
                    text: '.lk',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onOpenNotifications != null)
            IconButton(
              icon: Badge(
                isLabelVisible: backend.unreadNotificationsCount > 0,
                label: Text('${backend.unreadNotificationsCount}'),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: 'Notifications',
              onPressed: widget.onOpenNotifications,
            ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter Profiles',
                onPressed: _openFilterSheet,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Summary Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, town, hobbies...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active filter chip row if filters are enabled
          if (hasActiveFilters)
            Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_selectedDistrict != 'All Districts')
                    _buildActiveFilterChip('District: $_selectedDistrict', () {
                      setState(() => _selectedDistrict = 'All Districts');
                    }),
                  if (_townQuery.isNotEmpty)
                    _buildActiveFilterChip('Town: $_townQuery', () {
                      setState(() => _townQuery = '');
                    }),
                  if (_enableRadiusFilter)
                    _buildActiveFilterChip('Within ${_radiusKm.round()} km', () {
                      setState(() => _enableRadiusFilter = false);
                    }),
                  if (_genderPreference != 'Everyone')
                    _buildActiveFilterChip('For: $_genderPreference', () {
                      setState(() => _genderPreference = 'Everyone');
                    }),
                ],
              ),
            ),

          // Profiles Feed
          Expanded(
            child: profiles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return _buildProfileCard(profile, currentUser);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
        backgroundColor: AppTheme.primary.withOpacity(0.12),
        deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.primary),
        onDeleted: onRemove,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildProfileCard(UserModel profile, UserModel? currentUser) {
    String distanceString = '';
    if (currentUser?.latitude != null && currentUser?.longitude != null && profile.latitude != null && profile.longitude != null) {
      final km = LocationService.calculateDistanceKm(
        startLat: currentUser!.latitude!,
        startLng: currentUser!.longitude!,
        endLat: profile.latitude!,
        endLng: profile.longitude!,
      );
      distanceString = '${km.toStringAsFixed(1)} km away';
    }

    final photoCount = profile.photos.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetailScreen(user: profile),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Header
            Stack(
              children: [
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: _buildPhoto(profile.primaryPhoto),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top Badges: Verified & Photo count
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: AppTheme.success, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'NIC Verified',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                if (photoCount > 1)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '$photoCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Bottom overlay: Name, Age, Location
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.name}, ${profile.age}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.accent),
                          const SizedBox(width: 3),
                          Text(
                            '${profile.town.isNotEmpty ? "${profile.town}, " : ""}${profile.district}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (distanceString.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                distanceString,
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bio preview & Interests
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.bio.isNotEmpty) ...[
                    Text(
                      profile.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: profile.interests.take(4).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons: View Profile & Connect
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfileDetailScreen(user: profile)),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('View Profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfileDetailScreen(user: profile)),
                            );
                          },
                          icon: const Icon(Icons.favorite_rounded, size: 18),
                          label: const Text('Connect'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Profiles Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try relaxing your district or radius filters to discover more verified singles in Sri Lanka.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedDistrict = 'All Districts';
                  _townQuery = '';
                  _searchController.clear();
                  _searchQuery = '';
                  _enableRadiusFilter = false;
                  _genderPreference = 'Everyone';
                });
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
