import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// Import http differently for web vs mobile
import 'package:http/http.dart' as http;

import '../../core/constants/firebase_constants.dart';
import '../../core/constants/stripe_constants.dart';
import '../models/stripe_customer_model.dart';
import '../models/payment_method_model.dart';

/// Repository for handling Stripe payment operations
/// 
/// IMPORTANT: Some operations (like creating customers, charging cards)
/// should be done via Firebase Cloud Functions for security.
/// This repository handles client-side Stripe SDK operations.
class StripeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Firebase Cloud Functions base URL
  // This will be auto-configured based on your Firebase project
  final String _functionsBaseUrl = 'https://us-central1-trippo-42089.cloudfunctions.net';
  
  /// Initialize Stripe SDK
  /// Call this in main.dart before runApp()
  static Future<void> initializeStripe() async {
    Stripe.publishableKey = StripeConstants.activePublishableKey;
    Stripe.merchantIdentifier = StripeConstants.merchantIdentifier;
    await Stripe.instance.applySettings();
  }
  
  // ================== CUSTOMER MANAGEMENT ==================
  
  /// Create Stripe customer
  /// 
  /// Calls Firebase Cloud Function to securely create a Stripe customer
  /// with the secret API key stored server-side.
  Future<StripeCustomerModel> createCustomer({
    required String userId,
    required String email,
    required String name,
    BillingAddress? billingAddress,
  }) async {
    try {
      // Create HTTP client (works on both web and mobile)
      final client = http.Client();
      
      try {
        // Call Cloud Function to create Stripe customer
        final response = await client.post(
          Uri.parse('$_functionsBaseUrl/createStripeCustomer'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'userId': userId,
            'email': email,
            'name': name,
            'billingAddress': billingAddress?.toMap(),
          }),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode != 200) {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to create Stripe customer');
        }
        
        final data = json.decode(response.body);
        
        // Check if customer already existed
        if (data['existing'] == true) {
          // Fetch from Firestore since it already exists
          return (await getCustomer(userId))!;
        }
        
        final stripeCustomerId = data['customerId'] as String;
        
        // Customer was just created by Cloud Function
        // It's already in Firestore, so fetch it
        final customer = await getCustomer(userId);
        
        if (customer == null) {
          throw Exception('Customer created but not found in Firestore');
        }
        
        return customer;
      } finally {
        client.close();
      }
    } catch (e) {
      // Check if it's a platform-specific error
      if (e.toString().contains('Platform._operatingSystem') ||
          e.toString().contains('Unsupported operation')) {
        throw Exception(
          'Payment setup error.\n\n'
          'This feature requires running on a physical device or emulator.\n'
          'Flutter web payment processing is limited.\n\n'
          'Please test on:\n'
          '- Android emulator/device\n'
          '- iOS simulator/device\n\n'
          'Or contact support for web-specific payment options.'
        );
      }
      
      // Check if it's a network/Cloud Function issue
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
          'Unable to connect to payment server.\n\n'
          'Please check:\n'
          '1. Internet connection\n'
          '2. Cloud Functions are deployed\n'
          '3. Firebase project is accessible'
        );
      }
      
      throw Exception('Failed to create Stripe customer: $e');
    }
  }
  
  /// Get Stripe customer by user ID
  Future<StripeCustomerModel?> getCustomer(String userId) async {
    try {
      print('📥 Fetching Stripe customer for userId: $userId');
      final doc = await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        print('⚠️  No Stripe customer found for userId: $userId');
        return null;
      }
      
      print('✅ Found Stripe customer document');
      final data = doc.data()!;
      print('📄 Raw Firestore data: $data');
      
      return StripeCustomerModel.fromFirestore(
        data,
        doc.id,
      );
    } catch (e) {
      print('❌ Error in getCustomer: $e');
      throw Exception('Failed to get Stripe customer: $e');
    }
  }
  
  /// Update billing address
  Future<void> updateBillingAddress({
    required String userId,
    required BillingAddress billingAddress,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .update({
        'billingAddress': billingAddress.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update billing address: $e');
    }
  }
  
  // ================== PAYMENT METHOD MANAGEMENT ==================
  
  /// Add payment method using Stripe Elements
  /// This collects card details securely and creates a payment method
  Future<PaymentMethodModel> addPaymentMethod({
    required String userId,
    required BillingDetails billingDetails,
    bool setAsDefault = false,
  }) async {
    try {
      // Create payment method using Stripe SDK
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );
      
      final pmId = paymentMethod.id;
      
      // Call Cloud Function to attach payment method to customer
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/attachPaymentMethod'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'paymentMethodId': pmId,
          'setAsDefault': setAsDefault,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to attach payment method: ${response.body}');
      }
      
      // Create local payment method model
      final card = paymentMethod.card;
      if (card == null) {
        throw Exception('Payment method does not have card information');
      }
      
      final paymentMethodModel = PaymentMethodModel(
        id: pmId,
        type: 'card',
        isDefault: setAsDefault,
        last4: card.last4 ?? '',
        brand: card.brand?.toString().replaceAll('CardBrand.', '') ?? 'unknown',
        expiryMonth: card.expMonth.toString().padLeft(2, '0'),
        expiryYear: card.expYear.toString().substring(2),
        cardholderName: billingDetails.name ?? '',
        stripePaymentMethodId: pmId,
        addedAt: DateTime.now(),
        addedBy: 'user',
        isActive: true,
      );
      
      // Update Firestore
      await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .update({
        'paymentMethods': FieldValue.arrayUnion([paymentMethodModel.toFirestore()]),
        'defaultPaymentMethodId': setAsDefault ? pmId : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return paymentMethodModel;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }
  
  /// Remove payment method
  Future<void> removePaymentMethod({
    required String userId,
    required String paymentMethodId,
  }) async {
    try {
      // Call Cloud Function to detach payment method
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/detachPaymentMethod'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'paymentMethodId': paymentMethodId,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to detach payment method: ${response.body}');
      }
      
      // Get current customer data
      final customerDoc = await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .get();
      
      if (!customerDoc.exists) {
        throw Exception('Customer not found');
      }
      
      final customer = StripeCustomerModel.fromFirestore(
        customerDoc.data()!,
        customerDoc.id,
      );
      
      // Remove payment method from array
      final updatedPaymentMethods = customer.paymentMethods
          .where((pm) => pm.id != paymentMethodId)
          .map((pm) => pm.toFirestore())
          .toList();
      
      // Update Firestore
      await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .update({
        'paymentMethods': updatedPaymentMethods,
        'defaultPaymentMethodId': customer.defaultPaymentMethodId == paymentMethodId
            ? null
            : customer.defaultPaymentMethodId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove payment method: $e');
    }
  }
  
  /// Set default payment method
  Future<void> setDefaultPaymentMethod({
    required String userId,
    required String paymentMethodId,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .update({
        'defaultPaymentMethodId': paymentMethodId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also update the isDefault flag in payment methods array
      final customerDoc = await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .get();
      
      if (!customerDoc.exists) return;
      
      final customer = StripeCustomerModel.fromFirestore(
        customerDoc.data()!,
        customerDoc.id,
      );
      
      // Update payment methods array
      final updatedPaymentMethods = customer.paymentMethods.map((pm) {
        return pm.copyWith(isDefault: pm.id == paymentMethodId).toFirestore();
      }).toList();
      
      await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .update({
        'paymentMethods': updatedPaymentMethods,
      });
    } catch (e) {
      throw Exception('Failed to set default payment method: $e');
    }
  }
  
  // ================== PAYMENT PROCESSING ==================
  
  /// Create payment intent for ride payment
  /// This should be called via Cloud Function for security
  Future<Map<String, dynamic>> createPaymentIntent({
    required String userId,
    required double amount, // Amount in dollars
    required String currency,
    required String rideId,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert amount to cents
      final amountCents = (amount * 100).round();
      
      // Validate amount
      if (amountCents < StripeConstants.minimumPaymentAmountCents) {
        throw Exception('Amount must be at least \$${StripeConstants.minimumPaymentAmountCents / 100}');
      }
      
      if (amountCents > StripeConstants.maximumPaymentAmountCents) {
        throw Exception('Amount cannot exceed \$${StripeConstants.maximumPaymentAmountCents / 100}');
      }
      
      // Call Cloud Function to create payment intent
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/createPaymentIntent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amountCents,
          'currency': currency,
          'rideId': rideId,
          'paymentMethodId': paymentMethodId,
          'metadata': {
            ...?metadata,
            'app': 'BTrips',
            'prefix': StripeConstants.customerIdPrefix,
          },
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
      
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }
  
  /// Confirm payment (for 3D Secure, etc.)
  Future<PaymentIntent> confirmPayment({
    required String clientSecret,
    String? paymentMethodId,
  }) async {
    try {
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodId != null
            ? PaymentMethodParams.card(
                paymentMethodData: PaymentMethodData(),
              )
            : null,
      );
      
      return paymentIntent;
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }
  
  /// Process ride payment via cloud function
  /// This charges the customer's card for a completed ride
  Future<Map<String, dynamic>> processRidePayment({
    required String rideId,
    required String userId,
    required double amount,
    required String paymentMethodId,
  }) async {
    try {
      print('💳 Processing ride payment: \$$amount for ride $rideId');
      
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/processRidePayment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rideId': rideId,
          'userId': userId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
        }),
      );
      
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to process ride payment');
      }
      
      final data = json.decode(response.body);
      print('✅ Ride payment processed: ${data['paymentIntentId']}');
      return data;
    } catch (e) {
      print('❌ Error processing ride payment: $e');
      throw Exception('Failed to process ride payment: $e');
    }
  }
  
  /// Process admin invoice (one-off charge)
  /// Allows admins to manually charge a customer's default payment method
  Future<Map<String, dynamic>> processAdminInvoice({
    required String userEmail,
    required double amount,
    required String description,
    String? adminEmail,
  }) async {
    try {
      print('🔐 Processing admin invoice: \$$amount for $userEmail');
      print('   Reason: $description');
      
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/processAdminInvoice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userEmail': userEmail,
          'amount': amount,
          'description': description,
          'adminEmail': adminEmail ?? 'admin',
        }),
      );
      
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to process admin invoice');
      }
      
      final data = json.decode(response.body);
      print('✅ Admin invoice processed: ${data['paymentIntentId']}');
      return data;
    } catch (e) {
      print('❌ Error processing admin invoice: $e');
      throw Exception('Failed to process admin invoice: $e');
    }
  }
  
  // ================== UTILITY METHODS ==================
  
  /// Present payment sheet (for one-time payments)
  Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Failed to present payment sheet: $e');
    }
  }
  
  /// Check if customer exists
  Future<bool> customerExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.stripeCustomersCollection)
          .doc(userId)
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
  
  /// Get all payment methods for a user
  Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
    try {
      print('🔍 Fetching payment methods for user: $userId');
      final customer = await getCustomer(userId);
      print('📦 Customer data: ${customer?.toFirestore()}');
      print('💳 Payment methods count: ${customer?.paymentMethods.length ?? 0}');
      if (customer != null && customer.paymentMethods.isNotEmpty) {
        for (var pm in customer.paymentMethods) {
          print('   - ${pm.fullDisplayString} (${pm.expiryDisplayString})');
        }
      }
      return customer?.paymentMethods ?? [];
    } catch (e) {
      print('❌ Error fetching payment methods: $e');
      throw Exception('Failed to get payment methods: $e');
    }
  }
  
  /// Get default payment method for a user
  Future<PaymentMethodModel?> getDefaultPaymentMethod(String userId) async {
    try {
      final customer = await getCustomer(userId);
      return customer?.defaultPaymentMethod;
    } catch (e) {
      throw Exception('Failed to get default payment method: $e');
    }
  }
}

