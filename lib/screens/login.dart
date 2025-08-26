import 'package:flutter/material.dart';
import 'package:home_care/components/app_icon.dart';
import 'package:home_care/components/main_button.dart';
import 'package:home_care/components/text_input_field.dart';
import 'package:home_care/services/auth/authentication.dart';

class Login extends StatefulWidget {
  final Function onTap;
  const Login({super.key, required this.onTap});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void login() async {
    final auth = AuthServices();

    try {
      await auth.signInWithEmailPassword(
          email: _emailController.text, password: _passwordController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue to Home Care',
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    MainButton(
                      onTap: () {
                        login();
                      },
                      text: 'Sign In',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
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
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        )
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
                              // TODO: Implement Apple login
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
                              // TODO: Implement Google login
                            },
                            imagePath: 'images/google.png',
                            text: 'Google',
                            imageHeight: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
