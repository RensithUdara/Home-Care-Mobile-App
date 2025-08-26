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
    if (loginPage) {
      return Login(onTap: togglePages);
    } else {
      return Register(onTap: togglePages);
    }
  }
}
