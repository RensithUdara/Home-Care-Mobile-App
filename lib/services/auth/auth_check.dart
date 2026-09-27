import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_care/screens/main_shell.dart';
import 'package:home_care/services/auth/login_or_register.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:provider/provider.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // Keyed by uid so switching accounts starts with a fresh store.
          return ChangeNotifierProvider(
            key: ValueKey(user.uid),
            create: (_) => ProductStore(user.uid),
            child: MainShell(uid: user.uid, email: user.email ?? ''),
          );
        } else {
          return const LoginRegisterToggle(); // User is not signed in
        }
      },
    );
  }
}
