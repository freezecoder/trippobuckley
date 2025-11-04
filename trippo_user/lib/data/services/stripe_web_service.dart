import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';

/// Web-specific Stripe service using Stripe.js
/// This creates tokens only - Cloud Function handles payment method creation
class StripeWebService {
  /// Initialize Stripe Elements (web only)
  /// Must be called before creating payment method
  static Future<bool> initializeElements(String containerId) async {
    if (!kIsWeb) {
      throw UnsupportedError('This method is only for web platform');
    }

    try {
      print('🎨 Initializing Stripe Elements for container: $containerId');
      
      if (!js.context.hasProperty('initializeStripeElements')) {
        print('❌ initializeStripeElements function not found');
        return false;
      }
      
      final jsFunction = js.context['initializeStripeElements'] as js.JsFunction;
      final result = jsFunction.apply([containerId]);
      
      print('✅ Stripe Elements initialized: $result');
      return result as bool? ?? false;
    } catch (e) {
      print('❌ Failed to initialize Stripe Elements: $e');
      return false;
    }
  }

  /// Create Stripe payment method using Stripe Elements (web only)
  /// Uses the mounted card element, not raw card data
  static Future<Map<String, dynamic>> createPaymentMethod({
    required String cardholderName,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('This method is only for web platform');
    }

    try {
      print('💳 Creating payment method with cardholder: $cardholderName');
      
      // Call JavaScript function - only needs cardholder name
      // Card data comes from Stripe Elements
      final result = await _callJavaScriptFunction(
        'createStripePaymentMethod',  // Correct function name
        [cardholderName],  // Only name needed, card from Elements
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create payment method: $e',
      };
    }
  }

  /// Helper to call JavaScript functions from Dart
  /// Ultra-simplified direct call with promiseToFuture
  static Future<Map<String, dynamic>> _callJavaScriptFunction(
    String functionName,
    List<dynamic> args,
  ) async {
    try {
      print('🔍 Calling JavaScript function: $functionName');
      print('   Args: $args');
      
      // Get the function directly
      final jsFunction = js_util.getProperty(js.context, functionName);
      
      if (jsFunction == null) {
        throw Exception('Function $functionName not found');
      }

      print('✅ Function found');

      // Call the function and convert the returned promise
      final jsPromise = js_util.callMethod(jsFunction, 'call', [null, ...args]);

      print('📞 Waiting for promise...');

      // Convert the promise to a Dart future
      final result = await js_util.promiseToFuture(jsPromise);

      print('✅ Promise resolved, result: $result');
      
      // Build result map
      final Map<String, dynamic> dartResult = {};
      
      // Extract properties using js_util
      try {
        dartResult['success'] = js_util.getProperty(result, 'success') ?? false;
        
        if (js_util.hasProperty(result, 'paymentMethodId')) {
          dartResult['paymentMethodId'] = js_util.getProperty(result, 'paymentMethodId').toString();
        }
        
        if (js_util.hasProperty(result, 'last4')) {
          dartResult['last4'] = js_util.getProperty(result, 'last4').toString();
        }
        
        if (js_util.hasProperty(result, 'brand')) {
          dartResult['brand'] = js_util.getProperty(result, 'brand').toString();
        }
        
        if (js_util.hasProperty(result, 'error')) {
          dartResult['error'] = js_util.getProperty(result, 'error').toString();
        }
        
        print('✅ Result converted to Dart: $dartResult');
      } catch (e) {
        print('⚠️  Property extraction error: $e');
        dartResult['success'] = false;
        dartResult['error'] = 'Failed to extract properties: $e';
      }
      
      return dartResult;
      
    } catch (e) {
      print('❌ JavaScript call failed: $e');
      return {
        'success': false,
        'error': 'Call failed: $e',
      };
    }
  }

  /// Check if Stripe.js is loaded and ready
  static bool isStripeLoaded() {
    if (!kIsWeb) return false;
    
    try {
      final hasStripe = js.context.hasProperty('Stripe');
      final hasFunction = js.context.hasProperty('createStripePaymentMethod');
      final isReady = js.context.hasProperty('stripeReady');
      
      print('🔍 Stripe loaded check:');
      print('   Stripe object: $hasStripe');
      print('   createStripePaymentMethod function: $hasFunction');
      print('   stripeReady flag: $isReady');
      
      return hasStripe && hasFunction && isReady;
    } catch (e) {
      print('❌ Error checking Stripe: $e');
      return false;
    }
  }
}

