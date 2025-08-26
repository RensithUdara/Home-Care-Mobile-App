import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_care/screens/home.dart';
import 'package:home_care/services/auth/login_or_register.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasData) {
          return Home(
              uid: snapshot.data!.uid,
              email: snapshot.data!.email
                  .toString()); // Pass the uid to Home widget
        } else {
          return const LoginRegisterToggle(); // User is not signed in
        }
      },
    );
  }
}
