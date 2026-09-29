import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/audio_service.dart';
import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../models/user_profile.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _localAvatarPath;
  String? _selectedAvatarUrl;
  DateTime? _selectedDob;
  String? _dobFormatted;
  String _selectedGender = 'Male';
  bool _isSaving = false;

  final List<String> _cyberAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
    'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=200',
    'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
  ];

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _localAvatarPath = user?.avatarPath;
    _selectedAvatarUrl = user?.avatarUrl;
    _dobFormatted = user?.dateOfBirth;
    if (_dobFormatted != null && _dobFormatted!.isNotEmpty) {
      _selectedDob = DateTime.tryParse(_dobFormatted!);
    }
    _selectedGender = user?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Pick custom image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // close modal sheet
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );

      if (picked != null) {
        setState(() {
          _localAvatarPath = picked.path;
          _selectedAvatarUrl = null;
        });
        HapticFeedback.mediumImpact();
        AudioService.instance.playPop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Photo selected! Tap "Save Changes" to apply.'),
              backgroundColor: AppTheme.neonCyan,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e'), backgroundColor: AppTheme.neonPink),
        );
      }
    }
  }

  /// Select preset avatar
  void _selectPresetAvatar(String url) {
    Navigator.of(context).pop();
    setState(() {
      _selectedAvatarUrl = url;
      _localAvatarPath = null;
    });
    HapticFeedback.selectionClick();
    AudioService.instance.playPop();
  }

  /// Open bottom sheet for avatar selection
  void _openAvatarSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Upload from Camera / Gallery options
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardDark,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.neonCyan),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Or Choose an Arcade Preset:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Grid of 6 Cyber Avatars
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cyberAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final url = _cyberAvatars[idx];
                      return GestureDetector(
                        onTap: () => _selectPresetAvatar(url),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(url),
                          backgroundColor: AppTheme.cardDark,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Date of Birth Picker
  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonCyan,
              onPrimary: Colors.black,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobFormatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
      HapticFeedback.selectionClick();
    }
  }

  /// Save Profile Updates
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty!'), backgroundColor: AppTheme.neonPink),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await AuthService.instance.updateProfileDetails(
        displayName: name,
        avatarPath: _localAvatarPath,
        avatarUrl: _selectedAvatarUrl,
        dateOfBirth: _dobFormatted,
        gender: _selectedGender,
      );

      AudioService.instance.playVictory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile successfully updated!'),
            backgroundColor: AppTheme.neonGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.neonPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatarWidget(UserProfile? user) {
    ImageProvider? imageProvider;

    if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty) {
      if (!kIsWeb) {
        final file = File(_localAvatarPath!);
        if (file.existsSync()) {
          imageProvider = FileImage(file);
        }
      } else {
        imageProvider = NetworkImage(_localAvatarPath!);
      }
    } else if (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_selectedAvatarUrl!);
    } else if (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty) {
      imageProvider = NetworkImage(user.avatarUrl);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.neonCyan, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.surfaceDark,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person_rounded, size: 60, color: AppTheme.neonCyan)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _openAvatarSelectionSheet,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final user = auth.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Player Profile & Info'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check_rounded, color: AppTheme.neonGreen),
                tooltip: 'Save Profile',
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar & Gamer Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonCyan),
                  child: Column(
                    children: [
                      _buildAvatarWidget(user),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? 'Gamer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email.isNotEmpty == true ? user!.email : 'Email Authenticated',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // VIP & Coins Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.neonGold, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Text('🪙 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  '${user?.gemsBalance ?? 0} Coins',
                                  style: const TextStyle(
                                    color: AppTheme.neonGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.neonGreen, width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: AppTheme.neonGreen),
                                SizedBox(width: 4),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: AppTheme.neonGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Editable Profile Details Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderGlow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERSONAL INFORMATION',
                        style: TextStyle(
                          color: AppTheme.neonCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username field
                      const Text('Gamer Tag / Display Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.neonCyan, size: 20),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Date of Birth Selector
                      const Text('Date of Birth', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectDateOfBirth,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderGlow),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_rounded, color: AppTheme.neonPink, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _dobFormatted != null && _dobFormatted!.isNotEmpty
                                    ? _dobFormatted!
                                    : 'Select Date of Birth',
                                style: TextStyle(
                                  color: _dobFormatted != null ? Colors.white : Colors.white38,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.calendar_month_rounded, color: AppTheme.neonCyan, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Gender Selector
                      const Text('Gender', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Male', 'Female', 'Other'].map((g) {
                          final isSelected = _selectedGender.toLowerCase() == g.toLowerCase();
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(g),
                                selected: isSelected,
                                selectedColor: AppTheme.neonCyan,
                                backgroundColor: AppTheme.surfaceDark,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.neonCyan : AppTheme.borderGlow,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedGender = g);
                                    HapticFeedback.selectionClick();
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.save_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'SAVING...' : 'SAVE PROFILE CHANGES',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Referral & VIP summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGlow),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR REFERRAL CODE', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            user?.referralCode ?? 'NONE',
                            style: const TextStyle(
                              color: AppTheme.neonGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppTheme.neonCyan),
                        onPressed: () {
                          if (user?.referralCode != null) {
                            Clipboard.setData(ClipboardData(text: user!.referralCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Referral code copied!'), backgroundColor: AppTheme.neonCyan),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Out / Switch Account
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.neonPink),
                  label: const Text('Sign Out', style: TextStyle(color: AppTheme.neonPink)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.neonPink),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 12),

                // Delete Account (Google Play Policy Mandate)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppTheme.neonPink, width: 1.5),
                          ),
                          title: const Text('Delete Account & Data?', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold)),
                          content: const Text(
                            'This will permanently delete your account, game scores, and coin wallet balance pursuant to Google Play Policy. This action cannot be undone.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await AuthService.instance.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                                    (route) => false,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account and data deleted successfully.'), backgroundColor: AppTheme.neonPink),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
                              child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white38, size: 18),
                    label: const Text('Delete Account & Clear Data', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
