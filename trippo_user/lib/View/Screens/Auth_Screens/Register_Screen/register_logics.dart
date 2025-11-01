import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:btrips_unified/data/providers/auth_providers.dart';
import 'package:btrips_unified/core/enums/user_type.dart';
import 'package:btrips_unified/core/constants/route_constants.dart';
import 'package:btrips_unified/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:btrips_unified/Container/utils/error_notification.dart';
import 'package:btrips_unified/View/Screens/Auth_Screens/Register_Screen/register_providers.dart';

class RegisterLogics {
  Future<void> registerUser(
    BuildContext context,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController emailController,
    TextEditingController passwordController,
  ) async {
    try {
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        ErrorNotification()
            .showError(context, "Please fill in all fields");
        return;
      }

      // Get selected user type from role selection screen
      final selectedRole = ref.read(selectedUserTypeProvider);
      
      if (selectedRole == null) {
        ErrorNotification()
            .showError(context, "Please select a role first");
        return;
      }

      ref.read(registerIsLoadingProvider.notifier).update((state) => true);

      // Use new AuthRepository with role
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.registerWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        userType: selectedRole,
      );

      ref.read(registerIsLoadingProvider.notifier).update((state) => false);

      if (context.mounted) {
        // Navigation handled by Go Router based on role
        // Drivers will go to driver config, users to user main
        context.goNamed(RouteNames.splash);
      }
    } catch (e) {
      ref.read(registerIsLoadingProvider.notifier).update((state) => false);
      if (context.mounted) {
        ErrorNotification().showError(context, "Registration failed: ${e.toString()}");
      }
    }
  }
}