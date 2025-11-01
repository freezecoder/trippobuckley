import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:btrips_unified/data/providers/auth_providers.dart';
import 'package:btrips_unified/core/constants/route_constants.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';
import 'package:btrips_unified/View/Screens/Auth_Screens/Login_Screen/login_providers.dart';

class LoginLogics {
  Future<void> loginUser(
    BuildContext context,
    WidgetRef ref,
    TextEditingController emailController,
    TextEditingController passwordController,
  ) async {
    try {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ErrorNotification()
            .showError(context, "Please Enter Email and Password");
        return;
      }

      ref.read(loginIsLoadingProvider.notifier).update((state) => true);

      // Use new AuthRepository
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.loginWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ref.read(loginIsLoadingProvider.notifier).update((state) => false);

      if (context.mounted) {
        // Navigation is handled by Go Router redirect logic
        // based on user role, so we just go to splash
        context.goNamed(RouteNames.splash);
      }
    } catch (e) {
      ref.read(loginIsLoadingProvider.notifier).update((state) => false);
      if (context.mounted) {
        ErrorNotification().showError(context, "Login failed: ${e.toString()}");
      }
    }
  }
}