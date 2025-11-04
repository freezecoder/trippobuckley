import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stripe_repository.dart';
import '../models/stripe_customer_model.dart';
import '../models/payment_method_model.dart';
import 'auth_providers.dart';

/// Provider for StripeRepository instance
final stripeRepositoryProvider = Provider<StripeRepository>((ref) {
  return StripeRepository();
});

/// Provider to check if current user has Stripe customer account
final hasStripeCustomerProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(firebaseAuthUserProvider).value;
  if (user == null) return false;

  final stripeRepo = ref.read(stripeRepositoryProvider);
  return await stripeRepo.customerExists(user.uid);
});

/// Provider for Stripe customer data
final stripeCustomerProvider = StreamProvider<StripeCustomerModel?>((ref) async* {
  final user = ref.watch(firebaseAuthUserProvider).value;
  
  if (user == null) {
    yield null;
    return;
  }

  final stripeRepo = ref.read(stripeRepositoryProvider);
  
  // Get customer data once
  final customer = await stripeRepo.getCustomer(user.uid);
  yield customer;

  // You can add a real-time stream here if needed
  // For now, we'll use manual refresh
});

/// Provider for payment methods list
final paymentMethodsProvider = FutureProvider<List<PaymentMethodModel>>((ref) async {
  final user = ref.watch(firebaseAuthUserProvider).value;
  if (user == null) return [];

  final stripeRepo = ref.read(stripeRepositoryProvider);
  
  try {
    return await stripeRepo.getPaymentMethods(user.uid);
  } catch (e) {
    // If customer doesn't exist yet, return empty list
    return [];
  }
});

/// Provider for default payment method
final defaultPaymentMethodProvider = FutureProvider<PaymentMethodModel?>((ref) async {
  final user = ref.watch(firebaseAuthUserProvider).value;
  if (user == null) return null;

  final stripeRepo = ref.read(stripeRepositoryProvider);
  
  try {
    return await stripeRepo.getDefaultPaymentMethod(user.uid);
  } catch (e) {
    return null;
  }
});

/// Provider to check if user has any payment methods
final hasPaymentMethodsProvider = FutureProvider<bool>((ref) async {
  final paymentMethods = await ref.watch(paymentMethodsProvider.future);
  return paymentMethods.isNotEmpty;
});

/// State provider for managing payment method operations
final paymentMethodOperationProvider = StateProvider<AsyncValue<void>>((ref) {
  return const AsyncValue.data(null);
});

