import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/data/legal_text.dart';
import 'package:home_care/screens/legal_page.dart';
import 'package:home_care/services/auth/authentication.dart';
import 'package:home_care/services/firestore/firestore_services.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/themes/theme_provider.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportEmail = 'support@homecare.com';
const _supportPhone = '+15551234567';
const _supportPhoneDisplay = '+1 (555) 123-4567';

class ProfilePage extends StatefulWidget {
  final String email;
  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _displayName = '';
  String _phoneNumber = '';

  static const _notificationPrefs = [
    ('notif_warranty', 'Warranty expiry alerts',
        'Get reminded before warranties expire', true),
    ('notif_new_product', 'New product added',
        'Confirmation when an appliance is added', true),
    ('notif_updates', 'App updates', 'Hear about new features', false),
    ('notif_tips', 'Tips & tricks', 'Helpful tips for using the app', false),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _displayName = user.displayName ?? '');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _displayName = data['name'] ?? user.displayName ?? '';
          _phoneNumber = data['phone'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  String get _initials {
    final source = _displayName.trim().isNotEmpty
        ? _displayName.trim()
        : widget.email.split('@').first;
    final parts = source.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  // ---------------------------------------------------------------- actions

  void _showEditProfile() {
    final name = TextEditingController(text: _displayName);
    final phone = TextEditingController(text: _phoneNumber);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SheetFrame(
            title: 'Edit Profile',
            subtitle: 'How you appear in Home Care',
            icon: Icons.person_rounded,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Full name',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Button3D(
                    label: 'Save Changes',
                    icon: Icons.check_rounded,
                    loading: saving,
                    onPressed: () async {
                      setSheet(() => saving = true);
                      final ok = await _updateProfile(name.text, phone.text);
                      if (!sheetContext.mounted) return;
                      if (ok) {
                        Navigator.pop(sheetContext);
                      } else {
                        setSheet(() => saving = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _updateProfile(String name, String phone) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': widget.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }
      setState(() {
        _displayName = name.trim();
        _phoneNumber = phone.trim();
      });
      if (mounted) AppSnack.success(context, 'Profile updated successfully');
      HapticFeedback.lightImpact();
      return true;
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Failed to update profile: $e');
      return false;
    }
  }

  Future<void> _signOut() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in any time with your email and password.',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
      color: AppColors.primary,
    );
    if (!ok) return;
    try {
      await AuthServices().signOut();
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Failed to sign out');
    }
  }

  void _showChangePassword() {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String error = '';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            setSheet(() => error = '');
            if (current.text.isEmpty || next.text.isEmpty || confirm.text.isEmpty) {
              setSheet(() => error = 'Please fill all fields');
              return;
            }
            if (next.text != confirm.text) {
              setSheet(() => error = 'Passwords do not match');
              return;
            }
            if (next.text.length < 6) {
              setSheet(() => error = 'Password must be at least 6 characters');
              return;
            }
            setSheet(() => saving = true);
            try {
              final user = FirebaseAuth.instance.currentUser!;
              await user.reauthenticateWithCredential(EmailAuthProvider.credential(
                  email: user.email!, password: current.text));
              await user.updatePassword(next.text);
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              if (mounted) AppSnack.success(context, 'Password changed successfully');
            } on FirebaseAuthException catch (e) {
              setSheet(() {
                saving = false;
                error = e.code == 'wrong-password' || e.code == 'invalid-credential'
                    ? 'Your current password is incorrect'
                    : 'Failed to change password: ${e.message}';
              });
            } catch (e) {
              setSheet(() {
                saving = false;
                error = 'Failed to change password: $e';
              });
            }
          }

          Widget field(TextEditingController c, String hint, IconData icon) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: c,
                  obscureText: true,
                  decoration:
                      InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
                ),
              );

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: SheetFrame(
              title: 'Change Password',
              subtitle: 'Keep your account secure',
              icon: Icons.password_rounded,
              color: AppColors.info,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    field(current, 'Current password', Icons.lock_outline_rounded),
                    field(next, 'New password', Icons.lock_rounded),
                    field(confirm, 'Confirm new password', Icons.lock_reset_rounded),
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(error,
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600)),
                      ),
                    Button3D(
                      label: 'Update Password',
                      icon: Icons.shield_rounded,
                      loading: saving,
                      onPressed: submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNotificationSettings() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    if (!mounted) return;
    final values = {
      for (final p in _notificationPrefs) p.$1: prefs?.getBool(p.$1) ?? p.$4,
    };

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SheetFrame(
          title: 'Notifications',
          subtitle: 'Choose what you hear about',
          icon: Icons.notifications_active_rounded,
          color: AppColors.warning,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, 16 + MediaQuery.of(sheetContext).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in _notificationPrefs)
                  SwitchListTile(
                    value: values[p.$1]!,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(p.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(p.$3,
                        style: TextStyle(color: sheetContext.textMuted)),
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      setSheet(() => values[p.$1] = v);
                      prefs?.setBool(p.$1, v);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportData() {
    final products = context.read<ProductStore>().products;
    if (products.isEmpty) {
      AppSnack.info(context, 'You have no appliances to export yet');
      return;
    }
    final text = [
      'Home Care — ${products.length} appliances',
      for (final p in products) '\n${ProductUtils.shareText(p)}',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: text));
    AppSnack.success(
        context, 'Exported ${products.length} appliances to clipboard');
  }

  void _showFAQ() {
    const faqs = [
      ('How do I add a new appliance?',
          'Tap the + button in the middle of the bottom bar and fill in the product details, including warranty information. Use the quick presets (1 year, 2 years…) to fill in the warranty end date.'),
      ('How can I track warranty expiration?',
          'Open the Warranty tab for a timeline of every warranty. Items expiring within 30 days are highlighted and counted on the bell icon on the Home screen.'),
      ('Can I edit product information?',
          'Yes — open any product and tap the pencil icon, or long-press a card on the Home screen for quick actions.'),
      ('How do I delete a product?',
          'Open the product and tap the trash icon, or switch Home to list view and swipe a card to the left. You can undo right after deleting.'),
      ('What does the Insights tab show?',
          'A home health score, category breakdown, upcoming warranty expiries by month, total value and more.'),
      ('Can I backup my data?',
          'Your data is automatically backed up to the cloud while you\'re signed in. You can also export everything via Profile → Export data.'),
      ('How do I change themes?',
          'Go to Profile → Appearance and choose System, Light or Dark.'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
        child: SheetFrame(
          title: 'FAQ',
          subtitle: 'Frequently asked questions',
          icon: Icons.quiz_rounded,
          color: AppColors.secondary,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(
                12, 0, 12, 16 + MediaQuery.of(sheetContext).padding.bottom),
            children: [
              for (final (q, a) in faqs)
                Theme(
                  data: Theme.of(sheetContext)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(q,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a,
                          style: TextStyle(
                              color: sheetContext.textMuted, height: 1.5)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback() {
    final feedback = TextEditingController();
    int rating = 5;
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SheetFrame(
            title: 'Send Feedback',
            subtitle: 'How are we doing?',
            icon: Icons.favorite_rounded,
            color: const Color(0xFFEC4899),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final on = i < rating;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => rating = i + 1);
                        },
                        child: AnimatedScale(
                          scale: on ? 1.1 : 0.9,
                          duration: const Duration(milliseconds: 180),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.star_rounded,
                                size: 42,
                                color: on
                                    ? const Color(0xFFFBBF24)
                                    : sheetContext.outline),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedback,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        hintText: 'Tell us what you think… (optional)'),
                  ),
                  const SizedBox(height: 20),
                  Button3D(
                    label: 'Send Feedback',
                    icon: Icons.send_rounded,
                    loading: sending,
                    onPressed: () async {
                      setSheet(() => sending = true);
                      final ok = await _submit({
                        'type': 'feedback',
                        'rating': rating,
                        'message': feedback.text.trim(),
                      });
                      if (!sheetContext.mounted) return;
                      if (ok) {
                        Navigator.pop(sheetContext);
                        if (mounted) {
                          AppSnack.success(context, 'Thank you for your feedback!');
                        }
                      } else {
                        setSheet(() => sending = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBugReport() {
    final title = TextEditingController();
    final description = TextEditingController();
    String severity = 'Medium';
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SheetFrame(
            title: 'Report a Bug',
            subtitle: 'Help us squash it',
            icon: Icons.bug_report_rounded,
            color: AppColors.danger,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                        hintText: 'Brief description of the issue',
                        prefixIcon: Icon(Icons.title_rounded)),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      for (final s in ['Low', 'Medium', 'High', 'Critical'])
                        ButtonSegment(value: s, label: Text(s)),
                    ],
                    selected: {severity},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setSheet(() => severity = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        hintText: 'What happened? What did you expect?'),
                  ),
                  const SizedBox(height: 20),
                  Button3D(
                    label: 'Submit Report',
                    icon: Icons.send_rounded,
                    loading: sending,
                    gradient: AppColors.sunsetGradient,
                    onPressed: () async {
                      if (title.text.trim().isEmpty) {
                        AppSnack.error(context, 'Please add a short title');
                        return;
                      }
                      setSheet(() => sending = true);
                      final ok = await _submit({
                        'type': 'bug',
                        'title': title.text.trim(),
                        'severity': severity,
                        'message': description.text.trim(),
                      });
                      if (!sheetContext.mounted) return;
                      if (ok) {
                        Navigator.pop(sheetContext);
                        if (mounted) {
                          AppSnack.success(
                              context, 'Bug report submitted successfully!');
                        }
                      } else {
                        setSheet(() => sending = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _submit(Map<String, dynamic> data) async {
    try {
      await FirestoreService.submitFeedback({
        ...data,
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'email': widget.email,
      });
      return true;
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Could not send right now. Please try again later.');
      return false;
    }
  }

  Future<void> _launch(Uri uri, String fallbackCopy) async {
    try {
      if (await launchUrl(uri)) return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: fallbackCopy));
    if (mounted) AppSnack.info(context, 'Copied $fallbackCopy to clipboard');
  }

  void _showContactSupport() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SheetFrame(
        title: 'Contact Support',
        subtitle: 'We usually reply within a day',
        icon: Icons.support_agent_rounded,
        color: AppColors.success,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 4, 16, 16 + MediaQuery.of(sheetContext).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsTile(
                icon: Icons.email_rounded,
                color: AppColors.info,
                title: 'Email support',
                subtitle: _supportEmail,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _launch(
                    Uri(
                        scheme: 'mailto',
                        path: _supportEmail,
                        query: 'subject=Home Care support'),
                    _supportEmail,
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.phone_rounded,
                color: AppColors.success,
                title: 'Phone support',
                subtitle: _supportPhoneDisplay,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _launch(Uri(scheme: 'tel', path: _supportPhone),
                      _supportPhoneDisplay);
                },
              ),
              _SettingsTile(
                icon: Icons.chat_rounded,
                color: AppColors.secondary,
                title: 'Live chat',
                subtitle: 'Coming soon',
                onTap: () {
                  Navigator.pop(sheetContext);
                  AppSnack.info(context, 'Live chat is coming soon!');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.raised(dialogContext),
                ),
                child: Image.asset('images/logo.png',
                    errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded,
                        color: AppColors.primary, size: 40)),
              ),
              const SizedBox(height: 16),
              const Text('Home Care',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Version 1.0.0 (100)',
                  style: TextStyle(color: dialogContext.textMuted)),
              const SizedBox(height: 14),
              Text(
                'Home Care helps you manage and track your home appliances and their warranties.',
                textAlign: TextAlign.center,
                style: TextStyle(color: dialogContext.textMuted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Text('© 2024 Home Care Team',
                  style: TextStyle(
                      color: dialogContext.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccount() {
    final password = TextEditingController();
    String error = '';
    bool deleting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SheetFrame(
            title: 'Delete Account',
            subtitle: 'This cannot be undone',
            icon: Icons.person_remove_rounded,
            color: AppColors.danger,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your account, profile and all saved appliances will be permanently deleted. Enter your password to confirm.',
                    style: TextStyle(color: sheetContext.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock_rounded)),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(error,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 20),
                  Button3D(
                    label: 'Permanently Delete',
                    icon: Icons.delete_forever_rounded,
                    gradient: AppColors.sunsetGradient,
                    loading: deleting,
                    onPressed: () async {
                      if (password.text.isEmpty) {
                        setSheet(() => error = 'Please enter your password');
                        return;
                      }
                      setSheet(() {
                        deleting = true;
                        error = '';
                      });
                      try {
                        await _deleteAccount(password.text);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      } on FirebaseAuthException catch (e) {
                        setSheet(() {
                          deleting = false;
                          error = e.code == 'wrong-password' ||
                                  e.code == 'invalid-credential'
                              ? 'Incorrect password'
                              : (e.message ?? 'Could not delete account');
                        });
                      } catch (e) {
                        setSheet(() {
                          deleting = false;
                          error = 'Could not delete account: $e';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(String password) async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password));
    final db = FirebaseFirestore.instance;
    final products =
        await db.collection('products').where('uid', isEqualTo: user.uid).get();
    final batch = db.batch();
    for (final doc in products.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(db.collection('users').doc(user.uid));
    await batch.commit();
    await user.delete(); // Auth stream then routes back to login.
  }

  void _openLegal(String title, String body, IconData icon, String note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalPage(
            title: title, body: body, icon: icon, contactNote: note),
      ),
    );
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(store)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
            sliver: SliverList.list(children: [
              const SectionHeader(
                  title: 'Appearance',
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              Entrance(child: _ThemePicker(provider: theme)),
              const SectionHeader(
                  title: 'Account', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              Entrance(
                index: 1,
                child: _SettingsGroup(children: [
                  _SettingsTile(
                    icon: Icons.person_rounded,
                    color: AppColors.primary,
                    title: 'Edit profile',
                    subtitle: _phoneNumber.isEmpty ? 'Name & phone' : _phoneNumber,
                    onTap: _showEditProfile,
                  ),
                  _SettingsTile(
                    icon: Icons.password_rounded,
                    color: AppColors.info,
                    title: 'Change password',
                    subtitle: 'Update your sign-in password',
                    onTap: _showChangePassword,
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.warning,
                    title: 'Notifications',
                    subtitle: 'Alerts & reminders',
                    onTap: _showNotificationSettings,
                  ),
                  _SettingsTile(
                    icon: Icons.ios_share_rounded,
                    color: AppColors.success,
                    title: 'Export data',
                    subtitle: 'Copy all appliances as text',
                    onTap: _exportData,
                  ),
                ]),
              ),
              const SectionHeader(
                  title: 'Support', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              Entrance(
                index: 2,
                child: _SettingsGroup(children: [
                  _SettingsTile(
                    icon: Icons.quiz_rounded,
                    color: AppColors.secondary,
                    title: 'FAQ',
                    subtitle: 'Answers to common questions',
                    onTap: _showFAQ,
                  ),
                  _SettingsTile(
                    icon: Icons.support_agent_rounded,
                    color: AppColors.success,
                    title: 'Contact support',
                    subtitle: 'Email or call us',
                    onTap: _showContactSupport,
                  ),
                  _SettingsTile(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFEC4899),
                    title: 'Send feedback',
                    subtitle: 'Rate the app',
                    onTap: _showFeedback,
                  ),
                  _SettingsTile(
                    icon: Icons.bug_report_rounded,
                    color: AppColors.danger,
                    title: 'Report a bug',
                    subtitle: 'Something not working?',
                    onTap: _showBugReport,
                  ),
                ]),
              ),
              const SectionHeader(
                  title: 'About', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              Entrance(
                index: 3,
                child: _SettingsGroup(children: [
                  _SettingsTile(
                    icon: Icons.description_rounded,
                    color: const Color(0xFF64748B),
                    title: 'Terms of Service',
                    onTap: () => _openLegal(
                        'Terms of Service',
                        termsOfServiceText,
                        Icons.description_rounded,
                        'If you have any questions about these Terms, please contact us at support@homecare.com'),
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    color: const Color(0xFF64748B),
                    title: 'Privacy Policy',
                    onTap: () => _openLegal(
                        'Privacy Policy',
                        privacyPolicyText,
                        Icons.privacy_tip_rounded,
                        'Your privacy matters to us. For privacy-related inquiries, contact us at privacy@homecare.com'),
                  ),
                  _SettingsTile(
                    icon: Icons.info_rounded,
                    color: AppColors.accent,
                    title: 'About Home Care',
                    subtitle: 'Version 1.0.0',
                    onTap: _showAbout,
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              Entrance(
                index: 4,
                child: Button3D(
                  label: 'Sign Out',
                  icon: Icons.logout_rounded,
                  gradient: AppColors.sunsetGradient,
                  onPressed: _signOut,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _showDeleteAccount,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Delete account'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ProductStore store) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: FloatingOrbs()),
          Column(
            children: [
              Row(
                children: [
                  const Text('Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit profile',
                    onPressed: _showEditProfile,
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Avatar3D(initials: _initials),
              const SizedBox(height: 14),
              Text(
                _displayName.isEmpty ? 'Add your name' : _displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(widget.email,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _headerStat('${store.count}', 'Appliances'),
                  const SizedBox(width: 10),
                  _headerStat('${store.needsAttention.length}', 'Need attention'),
                  const SizedBox(width: 10),
                  _headerStat(
                      ProductUtils.formatMoney(store.totalValue), 'Total value'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Avatar3D extends StatelessWidget {
  final String initials;
  const _Avatar3D({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withValues(alpha: 0.4)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.35, -0.4),
            radius: 0.9,
            colors: [Color(0xFFA5B4FC), AppColors.primaryDark],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeProvider provider;
  const _ThemePicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    const options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];
    return DepthCard(
      depth: 0.6,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (final (mode, icon, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.setThemeMode(mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: provider.themeMode == mode
                        ? AppColors.brandGradient
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: provider.themeMode == mode
                        ? AppShadows.glow(AppColors.primary, strength: 0.7)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(icon,
                          color: provider.themeMode == mode
                              ? Colors.white
                              : context.textMuted),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: provider.themeMode == mode
                                ? Colors.white
                                : context.textMuted,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      depth: 0.6,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(color: context.outline.withValues(alpha: 0.6)),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: IconOrb(icon: icon, color: color, size: 40),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: TextStyle(color: context.textMuted, fontSize: 12.5)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.textMuted),
    );
  }
}
