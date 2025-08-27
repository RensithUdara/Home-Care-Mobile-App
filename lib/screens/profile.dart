import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/services/auth/authentication.dart';
import 'package:home_care/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  
  String _displayName = '';
  String _phoneNumber = '';
  int _totalAppliances = 0;
  int _expiringWarranties = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    _loadUserData();
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _displayName = data['name'] ?? user.displayName ?? '';
            _phoneNumber = data['phone'] ?? '';
            _nameController.text = _displayName;
            _phoneController.text = _phoneNumber;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load total appliances
        final appliancesSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('uid', isEqualTo: user.uid)
            .get();
        
        // Count expiring warranties (within 30 days)
        final now = DateTime.now();
        final thirtyDaysFromNow = now.add(const Duration(days: 30));
        
        int expiringCount = 0;
        for (var doc in appliancesSnapshot.docs) {
          final data = doc.data();
          if (data['warrantyPeriod'] != null) {
            final warrantyDate = (data['warrantyPeriod'] as Timestamp).toDate();
            if (warrantyDate.isAfter(now) && warrantyDate.isBefore(thirtyDaysFromNow)) {
              expiringCount++;
            }
          }
        }

        setState(() {
          _totalAppliances = appliancesSnapshot.docs.length;
          _expiringWarranties = expiringCount;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': widget.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update display name in Firebase Auth
        if (_nameController.text.trim().isNotEmpty) {
          await user.updateDisplayName(_nameController.text.trim());
        }

        setState(() {
          _displayName = _nameController.text.trim();
          _phoneNumber = _phoneController.text.trim();
          _isEditing = false;
        });

        _showSuccessSnackbar('Profile updated successfully');
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showSignOutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final AuthServices auth = AuthServices();
        await auth.signOut();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        _showErrorSnackbar('Failed to sign out');
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Hero Animation
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 20,
                ),
              ),
            ),
            actions: [
              AnimatedBuilder(
                animation: _fadeAnimation,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        _nameController.text = _displayName;
                        _phoneController.text = _phoneNumber;
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.green.shade100 : Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: _isEditing ? Colors.green.shade700 : Theme.of(context).colorScheme.inversePrimary,
                      size: 20,
                    ),
                  ),
                ),
                builder: (context, child) {
                  return Opacity(opacity: _fadeAnimation.value, child: child);
                },
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Profile Image with Animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                'images/avatar.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.inversePrimary,
                                      size: 60,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name Display/Edit
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _isEditing
                            ? SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your name',
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                _displayName.isEmpty ? 'Add your name' : _displayName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(height: 8),
                      // Email
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Appliances',
                          _totalAppliances.toString(),
                          Icons.devices,
                          Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Expiring Soon',
                          _expiringWarranties.toString(),
                          Icons.warning_amber_rounded,
                          Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Profile Information Card
                  _buildProfileInfoCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Settings Section
                  _buildSettingsSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Support Section
                  _buildSupportSection(),
                  
                  const SizedBox(height: 20),
                  
                  // App Info Section
                  _buildAppInfoSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showSignOutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Phone Number Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              _isEditing
                  ? TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.phone,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone_outlined, color: Colors.grey.shade500),
                          const SizedBox(width: 12),
                          Text(
                            _phoneNumber.isEmpty ? 'Add phone number' : _phoneNumber,
                            style: TextStyle(
                              color: _phoneNumber.isEmpty 
                                  ? Colors.grey.shade500 
                                  : Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: Colors.purple.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Dark Mode Toggle
          _buildSettingsItem(
            icon: Provider.of<ThemeProvider>(context).isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark Mode',
            subtitle: 'Toggle dark/light theme',
            iconColor: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.amber.shade700 : Colors.blue.shade700,
            iconBgColor: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.amber.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            trailing: CupertinoSwitch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                HapticFeedback.lightImpact();
              },
              activeColor: Colors.blue.shade600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Change Password
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            iconColor: Colors.green.shade700,
            iconBgColor: Colors.green.withOpacity(0.1),
            onTap: _showChangePasswordDialog,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Notifications
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            iconColor: Colors.orange.shade700,
            iconBgColor: Colors.orange.withOpacity(0.1),
            onTap: _showNotificationSettings,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Data & Privacy
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Data & Privacy',
            subtitle: 'Manage your data and privacy',
            iconColor: Colors.indigo.shade700,
            iconBgColor: Colors.indigo.withOpacity(0.1),
            onTap: _showPrivacySettings,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.teal.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Support & Help',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // FAQ
          _buildSettingsItem(
            icon: Icons.quiz_outlined,
            title: 'FAQ',
            subtitle: 'Frequently asked questions',
            iconColor: Colors.blue.shade700,
            iconBgColor: Colors.blue.withOpacity(0.1),
            onTap: _showFAQ,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Send Feedback
          _buildSettingsItem(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            iconColor: Colors.green.shade700,
            iconBgColor: Colors.green.withOpacity(0.1),
            onTap: _showFeedbackDialog,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Report Bug
          _buildSettingsItem(
            icon: Icons.bug_report_outlined,
            title: 'Report Bug',
            subtitle: 'Help us improve the app',
            iconColor: Colors.red.shade700,
            iconBgColor: Colors.red.withOpacity(0.1),
            onTap: _showBugReportDialog,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Contact Support
          _buildSettingsItem(
            icon: Icons.contact_support_outlined,
            title: 'Contact Support',
            subtitle: 'Get help from our team',
            iconColor: Colors.purple.shade700,
            iconBgColor: Colors.purple.withOpacity(0.1),
            onTap: _showContactSupport,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'App Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // About App
          _buildSettingsItem(
            icon: Icons.mobile_friendly_outlined,
            title: 'About App',
            subtitle: 'Version 1.0.0 • Learn more',
            iconColor: Colors.indigo.shade700,
            iconBgColor: Colors.indigo.withOpacity(0.1),
            onTap: _showAboutDialog,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Terms of Service
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            iconColor: Colors.grey.shade700,
            iconBgColor: Colors.grey.withOpacity(0.1),
            onTap: _showTermsOfService,
            showArrow: true,
          ),
          
          const SizedBox(height: 12),
          
          // Privacy Policy
          _buildSettingsItem(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            iconColor: Colors.teal.shade700,
            iconBgColor: Colors.teal.withOpacity(0.1),
            onTap: _showPrivacyPolicy,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow && trailing == null)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
