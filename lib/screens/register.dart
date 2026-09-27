import 'package:flutter/material.dart';
import 'package:home_care/components/auth_layout.dart';
import 'package:home_care/components/text_input_field.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/services/auth/authentication.dart';
import 'package:home_care/themes/app_colors.dart';

class Register extends StatefulWidget {
  final Function onTap;
  const Register({super.key, required this.onTap});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> register() async {
    _clearError();
    FocusScope.of(context).unfocus();

    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty) {
      _showError("Please enter your email address");
      return;
    }
    if (!AuthServices.isValidEmail(email)) {
      _showError("Please enter a valid email address");
      return;
    }
    if (password.isEmpty) {
      _showError("Please enter a password");
      return;
    }
    if (password.length < 8) {
      _showError("Password must be at least 8 characters long");
      return;
    }
    if (AuthServices.getPasswordStrength(password) < 3) {
      _showError(
          "Please create a stronger password with uppercase, lowercase, and numbers");
      return;
    }
    if (confirmPassword.isEmpty) {
      _showError("Please confirm your password");
      return;
    }
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthServices().signUpWithEmailPassword(
        email: email,
        password: password,
        name: _nameController.text,
      );
      if (mounted) {
        AppSnack.success(
            context, "Account created successfully! Welcome to Home Care!");
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _showError(errorMessage);
    } finally {
      if (mounted && _errorMessage.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    return AuthLayout(
      title: 'Create account',
      subtitle: 'Start tracking appliances & warranties in minutes',
      footer: AuthSwitchPrompt(
        prompt: 'Already have an account?',
        action: 'Sign In',
        onTap: _isLoading ? null : () => widget.onTap(),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextInputField(
              controller: _nameController,
              labelText: 'Full name (optional)',
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => _clearError(),
            ),
            const SizedBox(height: 14),
            TextInputField(
              controller: _emailController,
              labelText: 'Email address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => _clearError(),
            ),
            const SizedBox(height: 14),
            TextInputField(
              controller: _passwordController,
              labelText: 'Password',
              icon: Icons.lock_rounded,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) {
                _clearError();
                setState(() {}); // Refresh strength meter
              },
            ),
            if (password.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PasswordStrength(password: password),
            ],
            const SizedBox(height: 14),
            TextInputField(
              controller: _confirmPasswordController,
              labelText: 'Confirm password',
              icon: Icons.lock_reset_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => register(),
              onChanged: (_) => _clearError(),
            ),
            AuthErrorBanner(message: _errorMessage),
            const SizedBox(height: 20),
            Button3D(
              label: 'Create Account',
              icon: Icons.rocket_launch_rounded,
              loading: _isLoading,
              onPressed: register,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = AuthServices.getPasswordStrength(password);
    final (label, color) = switch (strength) {
      <= 1 => ('Very weak', AppColors.danger),
      2 => ('Weak', AppColors.danger),
      3 => ('Fair', AppColors.warning),
      4 => ('Good', AppColors.success),
      _ => ('Strong', AppColors.success),
    };
    final rules = [
      ('8+ characters', password.length >= 8),
      ('Uppercase', password.contains(RegExp(r'[A-Z]'))),
      ('Lowercase', password.contains(RegExp(r'[a-z]'))),
      ('Number', password.contains(RegExp(r'[0-9]'))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < strength ? color : context.surfaceAlt,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 5),
            ],
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final (text, ok) in rules)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: ok
                      ? AppColors.success.withValues(alpha: 0.12)
                      : context.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        ok
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 13,
                        color: ok ? AppColors.success : context.textMuted),
                    const SizedBox(width: 4),
                    Text(text,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ok ? AppColors.success : context.textMuted)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
