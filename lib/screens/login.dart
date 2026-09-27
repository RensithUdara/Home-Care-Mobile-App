import 'package:flutter/material.dart';
import 'package:home_care/components/auth_layout.dart';
import 'package:home_care/components/text_input_field.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/services/auth/authentication.dart';
import 'package:home_care/themes/app_colors.dart';

class Login extends StatefulWidget {
  final Function onTap;
  const Login({super.key, required this.onTap});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  String _cleanError(Object e) {
    final message = e.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }

  Future<void> login() async {
    _clearError();
    FocusScope.of(context).unfocus();

    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty) {
      _showError("Please enter your email address");
      return;
    }
    if (!AuthServices.isValidEmail(email)) {
      _showError("Please enter a valid email address");
      return;
    }
    if (password.isEmpty) {
      _showError("Please enter your password");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthServices()
          .signInWithEmailPassword(email: email, password: password);
      // Success - navigation handled by auth state listener
    } catch (e) {
      _showError(_cleanError(e));
    } finally {
      if (mounted && _errorMessage.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    _clearError();
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError("Enter your email above, then tap “Forgot password?”");
      return;
    }
    if (!AuthServices.isValidEmail(email)) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthServices().sendPasswordResetEmail(email: email);
      if (mounted) {
        AppSnack.success(context,
            "Password reset email sent! Check your inbox for instructions.");
      }
    } catch (e) {
      _showError(_cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to keep your home running smoothly',
      footer: AuthSwitchPrompt(
        prompt: "Don't have an account?",
        action: 'Sign Up',
        onTap: _isLoading ? null : () => widget.onTap(),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => login(),
              onChanged: (_) => _clearError(),
            ),
            AuthErrorBanner(message: _errorMessage),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _forgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 6),
            Button3D(
              label: 'Sign In',
              icon: Icons.login_rounded,
              loading: _isLoading,
              onPressed: login,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with',
                      style: TextStyle(color: context.textMuted, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SocialLoginButton(
                    imagePath: 'images/google.png',
                    text: 'Google',
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialLoginButton(
                    imagePath: 'images/apple.png',
                    text: 'Apple',
                    enabled: !_isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String imagePath;
  final String text;
  final bool enabled;

  const _SocialLoginButton({
    required this.imagePath,
    required this.text,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DepthCard(
        depth: 0.5,
        radius: 16,
        tilt: false,
        padding: const EdgeInsets.symmetric(vertical: 13),
        onTap: enabled
            ? () => AppSnack.info(context, '$text sign-in is coming soon')
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 22,
              color: text == 'Apple' && context.isDark ? Colors.white : null,
              errorBuilder: (_, __, ___) => Icon(
                  text == 'Apple' ? Icons.apple : Icons.g_mobiledata_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}
