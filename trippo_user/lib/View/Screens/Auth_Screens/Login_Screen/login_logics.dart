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

      // Invalidate all user-related providers to force fresh data
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserStreamProvider);
      ref.invalidate(isDriverProvider);
      ref.invalidate(isRegularUserProvider);
      
      debugPrint('🔄 Providers invalidated for fresh login');

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

  /// Show forgot password dialog
  void showForgotPasswordDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Reset Password',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontFamily: "bold",
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                cursorColor: Colors.red,
                keyboardType: TextInputType.emailAddress,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 14, color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                
                if (email.isEmpty) {
                  if (dialogContext.mounted) {
                    ErrorNotification().showError(
                      dialogContext,
                      "Please enter your email",
                    );
                  }
                  return;
                }

                if (!email.contains('@')) {
                  if (dialogContext.mounted) {
                    ErrorNotification().showError(
                      dialogContext,
                      "Please enter a valid email",
                    );
                  }
                  return;
                }

                try {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.sendPasswordResetEmail(email);
                  
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password reset email sent! Check your inbox.',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.green[700],
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ErrorNotification().showError(
                      dialogContext,
                      "Failed to send reset email: ${e.toString()}",
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Send Reset Link',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }
}