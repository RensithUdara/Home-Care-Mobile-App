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
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
