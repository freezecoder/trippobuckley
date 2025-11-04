# 🎯 Stripe Integration Setup Guide for BTrips

**Version**: 1.0.0  
**Date**: November 2, 2025  
**Status**: ✅ Ready for Implementation

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Getting Stripe Credentials](#getting-stripe-credentials)
3. [Firebase Collections Schema](#firebase-collections-schema)
4. [Configuration Setup](#configuration-setup)
5. [Testing with Test Mode](#testing-with-test-mode)
6. [Production Setup](#production-setup)
7. [Security Best Practices](#security-best-practices)
8. [Common Issues & Troubleshooting](#common-issues--troubleshooting)

---

## 🎯 Overview

This guide walks you through setting up Stripe payment integration for BTrips. We'll cover:

- Creating a Stripe account
- Getting API credentials (Publishable and Secret keys)
- Setting up test mode for development
- Configuring Firebase collections for Stripe data
- Implementing secure payment processing

### What We Store

✅ **Stored in Firestore**:
- Stripe customer ID (prefixed with `BTRP_`)
- Payment method tokens (NOT full card numbers)
- Last 4 digits of card
- Card brand (Visa, Mastercard, etc.)
- Expiry date (month/year)
- Billing address

❌ **NEVER Stored**:
- Full credit card numbers
- CVV/CVC codes
- Card PINs
- Raw card data

---

## 🔑 Getting Stripe Credentials

### Step 1: Create Stripe Account

1. Go to [https://stripe.com](https://stripe.com)
2. Click **"Start now"** or **"Sign in"**
3. Create your account with:
   - Email address
   - Password
   - Business name: **"BTrips"** (or your business name)
   - Country: Select your country

4. Complete email verification

### Step 2: Access Stripe Dashboard

After login, you'll see the Stripe Dashboard:
- Test Mode (orange banner): For development
- Live Mode (no banner): For production

**Important**: Always start with Test Mode for development!

### Step 3: Get API Keys

#### For Test/Sandbox Environment (Development)

1. In Stripe Dashboard, ensure you're in **Test Mode** (check for orange banner)
2. Navigate to: **Developers** → **API keys**
3. You'll see two keys:

   **Publishable Key** (Safe for client apps)
   ```
   pk_test_51AbCdEfGhIjKlMnOpQrStUvWxYz1234567890AbCdEfGhIjKlMnOpQrStUvWxYz
   ```
   - Starts with `pk_test_`
   - Can be used in your mobile app
   - Safe to expose (client-side)

   **Secret Key** (Server-side only)
   ```
   sk_test_51AbCdEfGhIjKlMnOpQrStUvWxYz1234567890AbCdEfGhIjKlMnOpQrStUvWxYz
   ```
   - Starts with `sk_test_`
   - **NEVER use in mobile app**
   - Only for backend (Firebase Cloud Functions)
   - Click **"Reveal test key"** to see it

4. Copy both keys to a secure location

#### For Production Environment (Later)

Once you're ready for production:

1. Switch to **Live Mode** (toggle in top-left)
2. Navigate to: **Developers** → **API keys**
3. You'll see production keys:

   **Publishable Key** (Production)
   ```
   pk_live_51AbCdEfGhIjKlMnOpQrStUvWxYz1234567890AbCdEfGhIjKlMnOpQrStUvWxYz
   ```
   - Starts with `pk_live_`

   **Secret Key** (Production)
   ```
   sk_live_51AbCdEfGhIjKlMnOpQrStUvWxYz1234567890AbCdEfGhIjKlMnOpQrStUvWxYz
   ```
   - Starts with `sk_live_`

---

## 🗄️ Firebase Collections Schema

### Collection 1: `stripeCustomers`

Stores Stripe customer IDs and payment information for each user.

**Document ID**: Firebase User UID  
**Structure**:

```javascript
stripeCustomers/{userId}/
  ├── userId: string                    // Firebase Auth UID
  ├── stripeCustomerId: string          // "BTRP_cus_xxxxx" (prefixed)
  ├── email: string                     // User email
  ├── name: string                      // User full name
  ├── billingAddress: {                 // Billing address object
  │     line1: string                   // Street address
  │     line2: string?                  // Apt/Suite (optional)
  │     city: string                    // City
  │     state: string                   // State/Province
  │     postalCode: string              // ZIP/Postal code
  │     country: string                 // Country code (e.g., "US")
  │   }
  ├── paymentMethods: [                 // Array of payment methods
  │     {
  │       id: string                    // Payment method ID
  │       type: "card" | "cash"         // Payment type
  │       isDefault: boolean            // Default payment method
  │       last4: string                 // Last 4 digits (e.g., "4242")
  │       brand: string                 // "Visa", "Mastercard", etc.
  │       expiryMonth: string           // "12"
  │       expiryYear: string            // "25" (2-digit)
  │       cardholderName: string        // Name on card
  │       stripePaymentMethodId: string // Stripe PM token
  │       addedAt: Timestamp            // When added
  │       addedBy: "user" | "admin"     // Who added it
  │       lastUsedAt: Timestamp?        // Last transaction
  │       isActive: boolean             // Active status
  │     }
  │   ]
  ├── defaultPaymentMethodId: string?   // Default PM ID
  ├── createdAt: Timestamp              // Customer created
  ├── updatedAt: Timestamp              // Last updated
  ├── isActive: boolean                 // Account active
  └── metadata: {                       // Additional metadata
        prefix: "BTRP"                  // Customer prefix
        createdVia: "mobile_app"        // Creation source
      }
```

**Example Document**:

```json
{
  "userId": "abc123xyz789",
  "stripeCustomerId": "BTRP_cus_Pq7RsTuVwXyZ1234",
  "email": "john.doe@example.com",
  "name": "John Doe",
  "billingAddress": {
    "line1": "123 Main Street",
    "line2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "postalCode": "10001",
    "country": "US"
  },
  "paymentMethods": [
    {
      "id": "pm_1234567890abcdef",
      "type": "card",
      "isDefault": true,
      "last4": "4242",
      "brand": "Visa",
      "expiryMonth": "12",
      "expiryYear": "25",
      "cardholderName": "John Doe",
      "stripePaymentMethodId": "pm_1234567890abcdef",
      "addedAt": "2025-11-02T10:00:00Z",
      "addedBy": "user",
      "lastUsedAt": "2025-11-02T12:30:00Z",
      "isActive": true
    }
  ],
  "defaultPaymentMethodId": "pm_1234567890abcdef",
  "createdAt": "2025-11-01T15:00:00Z",
  "updatedAt": "2025-11-02T12:30:00Z",
  "isActive": true,
  "metadata": {
    "prefix": "BTRP",
    "createdVia": "mobile_app"
  }
}
```

### Collection 2: `stripePaymentIntents`

Stores payment intent records for transactions.

**Document ID**: Auto-generated  
**Structure**:

```javascript
stripePaymentIntents/{intentId}/
  ├── userId: string                    // User making payment
  ├── rideId: string                    // Associated ride ID
  ├── amount: number                    // Amount in cents
  ├── currency: string                  // "usd", "eur", etc.
  ├── status: string                    // "succeeded", "pending", "failed"
  ├── stripePaymentIntentId: string     // Stripe PI ID
  ├── paymentMethodId: string           // PM used
  ├── clientSecret: string              // For 3D Secure
  ├── createdAt: Timestamp              // When created
  └── metadata: object                  // Additional data
```

### Collection 3: `stripeTransactions`

Audit trail of completed transactions.

**Document ID**: Auto-generated  
**Structure**:

```javascript
stripeTransactions/{transactionId}/
  ├── userId: string                    // User who paid
  ├── driverId: string?                 // Driver who received
  ├── rideId: string                    // Associated ride
  ├── amount: number                    // Amount in cents
  ├── currency: string                  // Currency code
  ├── status: string                    // "completed", "refunded"
  ├── type: string                      // "payment", "refund"
  ├── stripeChargeId: string            // Stripe charge ID
  ├── paymentMethodId: string           // PM used
  ├── completedAt: Timestamp            // Transaction time
  └── metadata: object                  // Additional data
```

---

## ⚙️ Configuration Setup

### Step 1: Create Environment File

Create `.env` file in project root:

```bash
# Stripe Test Mode Keys (Development)
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY_HERE
STRIPE_SECRET_KEY=sk_test_YOUR_SECRET_KEY_HERE

# Stripe Webhook Secret (from Stripe Dashboard > Webhooks)
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET_HERE

# Firebase Project ID
FIREBASE_PROJECT_ID=your-firebase-project-id

# Environment
ENVIRONMENT=development
```

**Important**: Add `.env` to `.gitignore` to prevent committing secrets!

### Step 2: Update Stripe Constants

Edit `lib/core/constants/stripe_constants.dart`:

```dart
class StripeConstants {
  // Replace with your actual test keys
  static const String publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
  
  // For production (leave empty for now)
  static const String publishableKeyProduction = '';
  
  // ... rest of constants
}
```

### Step 3: Initialize Stripe in App

In `lib/main.dart`:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/constants/stripe_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Stripe
  Stripe.publishableKey = StripeConstants.publishableKey;
  Stripe.merchantIdentifier = StripeConstants.merchantIdentifier;
  await Stripe.instance.applySettings();
  
  runApp(MyApp());
}
```

---

## 🧪 Testing with Test Mode

### Test Credit Cards

Stripe provides test cards for different scenarios:

| Scenario | Card Number | CVC | Date |
|----------|-------------|-----|------|
| **Success** | `4242 4242 4242 4242` | Any 3 digits | Any future date |
| **Declined** | `4000 0000 0000 0002` | Any 3 digits | Any future date |
| **Insufficient Funds** | `4000 0000 0000 9995` | Any 3 digits | Any future date |
| **Expired Card** | `4000 0000 0000 0069` | Any 3 digits | Any past date |
| **3D Secure Required** | `4000 0025 0000 3155` | Any 3 digits | Any future date |

### Testing Flow

1. Use test publishable key (`pk_test_...`)
2. Add a payment method using test card `4242 4242 4242 4242`
3. Process a test payment
4. Check Stripe Dashboard → **Payments** to see transaction
5. All test transactions are marked with "TEST MODE" badge

### Test vs Live Mode Indicator

In Stripe Dashboard:
- **Test Mode**: Orange banner at top
- **Live Mode**: No banner (be careful!)

You can toggle between modes in the top-left corner.

---

## 🚀 Production Setup

### Before Going Live

1. **Complete Stripe Account Verification**
   - Stripe Dashboard → **Settings** → **Account details**
   - Provide business information
   - Add bank account for payouts

2. **Switch to Live Mode**
   - Toggle to Live Mode in dashboard
   - Get new live API keys
   - Update `publishableKeyProduction` in constants

3. **Update Environment Variables**
   ```bash
   STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_LIVE_KEY_HERE
   STRIPE_SECRET_KEY=sk_live_YOUR_LIVE_SECRET_KEY_HERE
   ```

4. **Enable Production Features**
   - Set up webhook endpoints for production
   - Configure 3D Secure for European cards
   - Enable fraud detection

5. **Update App Configuration**
   ```dart
   // In stripe_constants.dart
   static String get activePublishableKey {
     return isProduction 
       ? publishableKeyProduction 
       : publishableKey;
   }
   ```

---

## 🔒 Security Best Practices

### DO ✅

1. **Use Environment Variables**
   - Never hardcode keys in source code
   - Use `.env` files (add to `.gitignore`)
   - Use Firebase Remote Config for production

2. **Secure Backend Operations**
   - Create customers via Cloud Functions
   - Process charges via Cloud Functions
   - Verify webhooks with signature

3. **Store Only Tokens**
   - Store Stripe payment method IDs
   - Store last 4 digits for display
   - Never store full card numbers

4. **Implement Proper Rules**
   - Use Firestore security rules
   - Restrict access to own data
   - Audit admin actions

5. **Use HTTPS**
   - All Stripe API calls over HTTPS
   - Secure webhooks with signature verification

### DON'T ❌

1. **Never Store Sensitive Data**
   - ❌ Full credit card numbers
   - ❌ CVV/CVC codes
   - ❌ Card PINs

2. **Never Use Secret Keys Client-Side**
   - ❌ Don't put `sk_test_` or `sk_live_` in mobile app
   - ❌ Don't commit keys to version control

3. **Never Skip Validation**
   - ❌ Don't skip 3D Secure when required
   - ❌ Don't skip webhook signature verification

4. **Never Log Sensitive Data**
   - ❌ Don't log card numbers
   - ❌ Don't log API keys
   - ❌ Don't log customer data in plain text

---

## ❓ Common Issues & Troubleshooting

### Issue 1: "Invalid API Key"

**Cause**: Wrong key or using test key in live mode

**Solution**:
```dart
// Check which key is active
print('Is test mode: ${StripeConstants.isTestMode}');
print('Active key: ${StripeConstants.activePublishableKey}');
```

### Issue 2: "No such customer"

**Cause**: Customer not created or wrong customer ID

**Solution**:
1. Check `stripeCustomers/{userId}` exists in Firestore
2. Verify `stripeCustomerId` matches Stripe dashboard
3. Ensure customer ID has `BTRP_` prefix in metadata

### Issue 3: "Card was declined"

**Cause**: Using wrong test card or real card in test mode

**Solution**:
- In test mode, use: `4242 4242 4242 4242`
- Check card expiry is in the future
- Try different test cards for specific scenarios

### Issue 4: "Authentication required"

**Cause**: 3D Secure needed

**Solution**:
```dart
// Confirm payment with 3D Secure
await Stripe.instance.confirmPayment(
  paymentIntentClientSecret: clientSecret,
);
```

### Issue 5: Customer IDs not showing with BTRP prefix in Stripe

**Cause**: Metadata not set during customer creation

**Solution**:
```javascript
// In Cloud Function when creating customer:
const customer = await stripe.customers.create({
  email: email,
  name: name,
  metadata: {
    prefix: 'BTRP',
    userId: userId,
    app: 'BTrips'
  }
});
```

To find BTRP customers in Stripe:
1. Go to **Customers** in dashboard
2. Use search or filter by metadata
3. Or prefix actual customer ID: `BTRP_cus_xxxxx`

---

## 📞 Getting Help

### Stripe Resources

- **Documentation**: [https://stripe.com/docs](https://stripe.com/docs)
- **API Reference**: [https://stripe.com/docs/api](https://stripe.com/docs/api)
- **Support**: [https://support.stripe.com](https://support.stripe.com)
- **Community**: [https://stripe.com/community](https://stripe.com/community)

### BTrips Support

If you have questions about the implementation:
1. Check this guide first
2. Review code comments in `stripe_repository.dart`
3. Check security rules in `firestore.rules`
4. Contact development team

---

## 📚 Next Steps

1. ✅ Get Stripe test API keys
2. ✅ Update `stripe_constants.dart` with your keys
3. ✅ Create `.env` file (don't commit!)
4. ✅ Deploy Firestore security rules
5. ✅ Test with test cards
6. ✅ Implement Cloud Functions for backend
7. ✅ Test end-to-end payment flow
8. ✅ Complete Stripe verification for production
9. ✅ Switch to live keys when ready

---

**Document Version**: 1.0.0  
**Last Updated**: November 2, 2025  
**Status**: ✅ Ready for Implementation

---

