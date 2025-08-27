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

  // Add this method to refresh statistics when needed
  Future<void> _refreshStatistics() async {
    await _loadStatistics();
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
        
        // Count expiring warranties (within 30 days or already expired)
        final now = DateTime.now();
        
        int expiringCount = 0;
        for (var doc in appliancesSnapshot.docs) {
          final data = doc.data();
          if (data['warrantyPeriod'] != null) {
            DateTime warrantyDate;
            
            // Handle different data types for warrantyPeriod
            if (data['warrantyPeriod'] is Timestamp) {
              warrantyDate = (data['warrantyPeriod'] as Timestamp).toDate();
            } else if (data['warrantyPeriod'] is String) {
              warrantyDate = DateTime.parse(data['warrantyPeriod']);
            } else {
              continue; // Skip if we can't parse the date
            }
            
            // Count warranties that are expiring within 30 days (including today)
            // or already expired (for comprehensive tracking)
            final daysUntilExpiry = warrantyDate.difference(now).inDays;
            
            // Include: expired warranties OR warranties expiring within 30 days
            if (daysUntilExpiry <= 30) {
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
      // Set default values in case of error
      setState(() {
        _totalAppliances = 0;
        _expiringWarranties = 0;
      });
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

  // Settings Dialog Methods
  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement password change logic here
                _changePassword(currentPasswordController.text, newPasswordController.text, confirmPasswordController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      _showErrorSnackbar('Passwords do not match');
      return;
    }
    if (newPassword.length < 6) {
      _showErrorSnackbar('Password must be at least 6 characters');
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Change password
        await user.updatePassword(newPassword);
        _showSuccessSnackbar('Password changed successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to change password: ${e.toString()}');
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Notification Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationToggle('Warranty Expiry Alerts', 'Get notified before warranties expire', true),
                  _buildNotificationToggle('New Product Added', 'Notifications for newly added products', true),
                  _buildNotificationToggle('App Updates', 'Get notified about app updates', false),
                  _buildNotificationToggle('Tips & Tricks', 'Helpful tips for using the app', false),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationToggle(String title, String subtitle, bool initialValue) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isEnabled = initialValue;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    isEnabled = value;
                  });
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Data & Privacy'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage your data and privacy settings:'),
              SizedBox(height: 16),
              Text('• Your data is stored securely in Firebase'),
              Text('• We only collect necessary information'),
              Text('• You can delete your account anytime'),
              Text('• No data is shared with third parties'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement delete account functionality
                _showDeleteAccountConfirmation();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation() {
    Navigator.of(context).pop(); // Close privacy dialog first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account'),
          content: const Text(
            'This action cannot be undone. All your data will be permanently deleted.\n\nAre you sure you want to delete your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement account deletion
                Navigator.of(context).pop();
                _showErrorSnackbar('Account deletion is not implemented yet');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showFAQ() {
    final List<Map<String, String>> faqs = [
      {
        'question': 'How do I add a new appliance?',
        'answer': 'Tap the + button on the home screen and fill in the product details including warranty information.',
      },
      {
        'question': 'How can I track warranty expiration?',
        'answer': 'The app automatically tracks warranty dates and shows warnings when they\'re about to expire.',
      },
      {
        'question': 'Can I edit product information?',
        'answer': 'Yes, tap on any product card and then tap the edit icon to modify its details.',
      },
      {
        'question': 'How do I delete a product?',
        'answer': 'Open the product details and tap the delete button (trash icon) in the top right.',
      },
      {
        'question': 'Can I backup my data?',
        'answer': 'Your data is automatically backed up to the cloud when you\'re signed in.',
      },
      {
        'question': 'How do I change themes?',
        'answer': 'Go to Profile > Settings and toggle the Dark Mode switch.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Frequently Asked Questions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        return _buildFAQItem(faqs[index]['question']!, faqs[index]['answer']!);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Send Feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How would you rate this app?'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        child: Icon(
                          Icons.star,
                          size: 32,
                          color: index < rating ? Colors.amber : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your feedback (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Tell us what you think...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _submitFeedback(rating, feedbackController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Send Feedback'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitFeedback(int rating, String feedback) {
    // Here you would typically send this to a backend service
    _showSuccessSnackbar('Thank you for your feedback!');
    // You could store this in Firestore under a 'feedback' collection
  }

  void _showBugReportDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedSeverity = 'Medium';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Report Bug'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Bug Title',
                      border: OutlineInputBorder(),
                      hintText: 'Brief description of the issue',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Low', 'Medium', 'High', 'Critical'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSeverity = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bug Description',
                      border: OutlineInputBorder(),
                      hintText: 'Detailed description of the bug...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _submitBugReport(titleController.text, selectedSeverity, descriptionController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitBugReport(String title, String severity, String description) {
    // Here you would typically send this to a backend service
    _showSuccessSnackbar('Bug report submitted successfully!');
    // You could store this in Firestore under a 'bug_reports' collection
  }

  void _showContactSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact Support',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildContactMethod(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@homecare.com',
                onTap: () {
                  // Open email app
                  _showSuccessSnackbar('Opening email app...');
                },
              ),
              _buildContactMethod(
                icon: Icons.phone_outlined,
                title: 'Phone Support',
                subtitle: '+1 (555) 123-4567',
                onTap: () {
                  // Make phone call
                  _showSuccessSnackbar('Opening phone app...');
                },
              ),
              _buildContactMethod(
                icon: Icons.chat_outlined,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () {
                  // Open chat
                  _showSuccessSnackbar('Live chat coming soon!');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('About Home Care App'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text('Build: 100'),
              SizedBox(height: 16),
              Text(
                'Home Care App helps you manage and track your home appliances and their warranties.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 16),
              Text('© 2024 Home Care Team'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Terms of Service'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last updated: August 2024',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '''By using Home Care App, you agree to these terms and conditions.

1. ACCEPTANCE OF TERMS
By accessing and using this app, you accept and agree to be bound by the terms and provision of this agreement.

2. USE LICENSE
Permission is granted to temporarily use Home Care App for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
• Modify or copy the materials
• Use the materials for any commercial purpose or for any public display
• Attempt to reverse engineer any software contained on the app
• Remove any copyright or other proprietary notations from the materials

3. DISCLAIMER
The materials on Home Care App are provided on an 'as is' basis. Home Care App makes no warranties, expressed or implied, and hereby disclaim and negate all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.

Further, Home Care App does not warrant or make any representations concerning the accuracy, likely results, or reliability of the use of the materials on its app or otherwise relating to such materials or on any sites linked to this app.

4. LIMITATIONS
In no event shall Home Care App or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Home Care App, even if Home Care App or an authorized representative has been notified orally or in writing of the possibility of such damage. Because some jurisdictions do not allow limitations on implied warranties, or limitations of liability for consequential or incidental damages, these limitations may not apply to you.

5. ACCURACY OF MATERIALS
The materials appearing on Home Care App could include technical, typographical, or photographic errors. Home Care App does not warrant that any of the materials on its app are accurate, complete, or current. Home Care App may make changes to the materials contained on its app at any time without notice. However, Home Care App does not make any commitment to update the materials.

6. LINKS
Home Care App has not reviewed all of the sites linked to our app and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by Home Care App of the site. Use of any such linked app is at the user's own risk.

7. MODIFICATIONS
Home Care App may revise these terms of service for its app at any time without notice. By using this app, you are agreeing to be bound by the then current version of these terms of service.

8. GOVERNING LAW
These terms and conditions are governed by and construed in accordance with the laws of the jurisdiction in which Home Care App operates and you irrevocably submit to the exclusive jurisdiction of the courts in that state or location.

9. USER ACCOUNTS
When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.

10. PROHIBITED USES
You may not use our service:
• For any unlawful purpose or to solicit others to perform or participate in any unlawful acts
• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances
• To infringe upon or violate our intellectual property rights or the intellectual property rights of others
• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate
• To submit false or misleading information
• To upload or transmit viruses or any other type of malicious code

By continuing to use Home Care App, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.''',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'If you have any questions about these Terms, please contact us at support@homecare.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Privacy Policy'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.privacy_tip_outlined,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last updated: August 2024',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '''Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use Home Care App.

INFORMATION WE COLLECT

1. Personal Information
We may collect personal information that you provide directly to us, such as:
• Name and email address when you create an account
• Profile information and preferences
• Communication preferences
• Contact information for service requests

2. Usage Information
We automatically collect certain information when you use our app:
• Device information (device type, operating system, app version)
• Usage patterns and app interactions
• Log files and crash reports
• Location data (if you grant permission)

3. Service Data
When you use our home care services:
• Service requests and scheduling information
• Communication with care providers
• Service feedback and ratings
• Payment and billing information

HOW WE USE YOUR INFORMATION

We use the information we collect to:
• Provide and maintain our services
• Process and fulfill service requests
• Communicate with you about your account and services
• Send notifications about appointments and updates
• Improve our app and services
• Ensure safety and security
• Comply with legal obligations

INFORMATION SHARING

We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:

• With service providers who help us operate our app
• With care providers to fulfill your service requests
• When required by law or to protect our rights
• In case of business transfer or merger
• With your explicit consent

DATA SECURITY

We implement appropriate technical and organizational measures to protect your personal information:
• Encryption of data in transit and at rest
• Regular security assessments and updates
• Access controls and authentication
• Secure payment processing
• Employee training on data protection

YOUR RIGHTS

You have the following rights regarding your personal information:
• Access: Request access to your personal data
• Correction: Update or correct inaccurate information
• Deletion: Request deletion of your personal data
• Portability: Request a copy of your data in a portable format
• Opt-out: Unsubscribe from marketing communications

DATA RETENTION

We retain your personal information only as long as necessary to:
• Provide our services to you
• Comply with legal obligations
• Resolve disputes and enforce agreements
• Maintain business records

Typically, we retain:
• Account information: Until account deletion
• Service records: 3 years after service completion
• Communication logs: 1 year
• Usage analytics: 2 years (anonymized)

CHILDREN'S PRIVACY

Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover that we have collected information from a child under 13, we will delete it immediately.

INTERNATIONAL TRANSFERS

If you are located outside our primary jurisdiction, please note that we may transfer your information to countries that may have different data protection laws. We ensure appropriate safeguards are in place for such transfers.

COOKIES AND TRACKING

Our app may use cookies and similar tracking technologies to:
• Remember your preferences
• Analyze app usage
• Provide personalized content
• Ensure app security

You can control cookie preferences through your device settings.

THIRD-PARTY SERVICES

Our app may integrate with third-party services (such as payment processors, analytics providers). These third parties have their own privacy policies, and we encourage you to review them.

CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of any material changes by:
• Posting the updated policy in the app
• Sending an email notification
• Displaying a prominent notice

Your continued use of the app after changes constitutes acceptance of the updated policy.

CONTACT US

If you have questions or concerns about this Privacy Policy or our data practices, please contact us:

Email: privacy@homecare.com
Phone: +1-800-HOMECARE
Address: Home Care App Privacy Team
123 Care Street, Suite 100
Privacy City, PC 12345

You can also reach out through the app's contact support feature.

COMPLIANCE

This Privacy Policy complies with applicable data protection laws, including:
• General Data Protection Regulation (GDPR)
• California Consumer Privacy Act (CCPA)
• Children's Online Privacy Protection Act (COPPA)
• Health Insurance Portability and Accountability Act (HIPAA) where applicable

By using Home Care App, you acknowledge that you have read and understood this Privacy Policy and agree to our collection and use of your information as described herein.''',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your privacy matters to us. For privacy-related inquiries, contact us at privacy@homecare.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _refreshStatistics();
        },
        child: CustomScrollView(
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
