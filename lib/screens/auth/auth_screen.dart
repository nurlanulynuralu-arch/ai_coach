import 'package:flutter/material.dart';

import 'sign_in_screen.dart';

@Deprecated('Use SignInScreen or SignUpScreen directly.')
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignInScreen();
  }
}
