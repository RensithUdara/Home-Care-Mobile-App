import 'package:flutter/material.dart';
import 'package:home_care/components/app_icon.dart';
import 'package:home_care/components/main_button.dart';
import 'package:home_care/components/text_input_field.dart';
import 'package:home_care/services/auth/authentication.dart';

class Register extends StatefulWidget {
  final Function onTap;
  const Register({super.key, required this.onTap});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {}); // Rebuild to update password requirements
    });
  }

  void register() async {
    final auth = AuthServices();

    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (!email.contains('@')) {
      _showErrorSnackbar("Invalid email address");
      return;
    }

    if (password.length < 8) {
      _showErrorSnackbar("Password must be at least 8 characters");
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackbar("Passwords do not match");
      return;
    }

    try {
      await auth.signUpWithEmailPassword(email: email, password: password);
      // Handle successful registration if needed
    } catch (e) {
      _showErrorSnackbar("Registration failed: ${e.toString()}");
    }
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      widget.onTap();
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        const AppIcon(),
                        const SizedBox(height: 32),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join Home Care and get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextInputField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextInputField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password Requirements:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PasswordRequirement(
                                text: 'At least 8 characters',
                                isValid: _passwordController.text.length >= 8,
                              ),
                              _PasswordRequirement(
                                text: 'Contains uppercase letter',
                                isValid: _passwordController.text.contains(RegExp(r'[A-Z]')),
                              ),
                              _PasswordRequirement(
                                text: 'Contains lowercase letter',
                                isValid: _passwordController.text.contains(RegExp(r'[a-z]')),
                              ),
                              _PasswordRequirement(
                                text: 'Contains number',
                                isValid: _passwordController.text.contains(RegExp(r'[0-9]')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        MainButton(
                          onTap: () {
                            register();
                          },
                          text: 'Create Account',
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.onTap();
                              },
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _SocialLoginButton(
                                onTap: () {
                                  // TODO: Implement Apple signup
                                },
                                imagePath: 'images/apple.png',
                                text: 'Apple',
                                imageHeight: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SocialLoginButton(
                                onTap: () {
                                  // TODO: Implement Google signup
                                },
                                imagePath: 'images/google.png',
                                text: 'Google',
                                imageHeight: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isValid;

  const _PasswordRequirement({
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid ? Colors.green : Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green : Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final String imagePath;
  final String text;
  final double imageHeight;

  const _SocialLoginButton({
    required this.onTap,
    required this.imagePath,
    required this.text,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: imageHeight,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
