import 'package:flutter/material.dart';
import 'package:home_care/screens/login.dart';
import 'package:home_care/screens/register.dart';

class LoginRegisterToggle extends StatefulWidget {
  const LoginRegisterToggle({super.key});

  @override
  State<LoginRegisterToggle> createState() => _LoginRegisterToggleState();
}

class _LoginRegisterToggleState extends State<LoginRegisterToggle> {
  bool loginPage = true;

  void togglePages() {
    setState(() {
      loginPage = !loginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: loginPage
          ? Login(key: const ValueKey('login'), onTap: togglePages)
          : Register(key: const ValueKey('register'), onTap: togglePages),
    );
  }
}
