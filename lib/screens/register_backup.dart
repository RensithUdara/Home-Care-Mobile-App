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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void register() async {
    final auth = AuthServices();

    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (!email.contains('@')) {
      _showErrorSnackbar(
        "Invalid email address",
      );
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
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon(),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Let\'s Create an Account.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextInputField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.email,
                ),
                const SizedBox(height: 10),
                TextInputField(
                  controller: _passwordController,
                  labelText: 'Password',
                  icon: Icons.password,
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                TextInputField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  icon: Icons.password,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                MainButton(
                  onTap: () {
                    register();
                  },
                  text: 'Register',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already a Member?"),
                    TextButton(
                      onPressed: () {
                        widget.onTap();
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/apple.png',
                            height: 35,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Continue with Apple",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                fontSize: 16),
                          ),
                        ],
                      )),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/google.png',
                            height: 30,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Continue with Google",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                fontSize: 16),
                          ),
                        ],
                      )),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
