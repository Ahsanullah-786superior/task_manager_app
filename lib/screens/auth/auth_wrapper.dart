import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/task_provider.dart';
import '../home_screen.dart';
import 'login_screen.dart';

/// Switches between the login flow and the main app depending on whether
/// a user is currently signed in. Also binds the TaskProvider to the
/// signed-in user's uid so Firestore queries are scoped correctly.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();

    if (auth.isAuthenticated) {
      context.read<TaskProvider>().bindToUser(auth.user!.uid);
      return const HomeScreen();
    }

    context.read<TaskProvider>().clear();
    return const LoginScreen();
  }
}
