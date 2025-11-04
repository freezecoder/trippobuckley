# 💳 Stripe Payment Setup Guide

**Date**: November 3, 2025  
**Status**: ✅ Setup Complete with Script-Based Workflow

---

## 🎯 Overview

Your BTrips app uses Stripe for secure payment processing. Due to security requirements, Stripe customer accounts must be created **server-side** using your **secret API key**, not from the mobile app.

---

## 🔒 Why This Approach?

### Security Architecture

```
❌ INSECURE (Don't do this):
Mobile App → Stripe API (with secret key)
└─ Exposes your secret key in the app!

✅ SECURE (Current approach):
Mobile App → Firestore ← Script with Secret Key → Stripe API
└─ Secret key stays on server/backend only
```

**Key Points:**
- 🔑 **Secret keys** can create customers and charge cards
- 🌐 **Publishable keys** can only collect card details (safe in app)
- 💳 Apps use publishable keys to securely collect card info
- 🖥️ Backend (scripts/Cloud Functions) use secret keys to process payments

---

## 🚀 Current Setup (Script-Based)

### How It Works

1. **User Registration**: User creates account in app
2. **Firestore Record**: User document created in `users` collection
3. **Script Setup**: Admin runs script to create Stripe customers
4. **Add Payment Method**: User can now add cards in the app

### The Script

**Location**: `scripts/create_stripe_test_customers.js`

**What it does**:
- ✅ Reads all users from Firestore (userType = "user")
- ✅ Creates Stripe customer for each user
- ✅ Stores customer ID in Firestore (`stripeCustomers` collection)
- ✅ Skips users who already have Stripe customers

---

## 📋 Setup Instructions

### Step 1: Ensure Script is Ready

```bash
cd trippo_user
```

Check that your Stripe secret key is configured in the script:
```javascript
// In scripts/create_stripe_test_customers.js
const STRIPE_TEST_SECRET_KEY = process.env.STRIPE_SECRET_KEY || 'sk_test_...'
```

### Step 2: Install Dependencies

```bash
npm install firebase-admin node-fetch
```

### Step 3: Run the Script

```bash
node scripts/create_stripe_test_customers.js
```

**Expected Output:**
```
🚀 Starting Stripe customer creation for test users...

📊 Found 3 user(s) to process

📝 Processing user: user@example.com
✅ Created Stripe customer: cus_ABC123 for user@example.com
✅ Saved Stripe customer to Firestore for user abc123

✅ Successfully processed user@example.com

============================================================
📊 SUMMARY
============================================================
✅ Successfully created: 3
⏭️  Skipped (already exists): 0
❌ Errors: 0
📊 Total users processed: 3
============================================================
```

### Step 4: Verify in Stripe Dashboard

1. Go to [Stripe Test Dashboard](https://dashboard.stripe.com/test/customers)
2. You should see your customers with email addresses
3. Metadata should show:
   - `prefix`: BTRP
   - `app`: BTrips
   - `createdVia`: script

### Step 5: Verify in Firestore

1. Open [Firebase Console](https://console.firebase.google.com)
2. Go to Firestore Database
3. Check `stripeCustomers` collection
4. Each user should have:
   - `userId`: Firebase UID
   - `stripeCustomerId`: Starts with `cus_`
   - `email`: User's email
   - `name`: User's name

---

## 🧪 Testing the Payment Flow

### For Existing Users (Created via Script)

1. **Login** to the app as a passenger
2. **Go to**: Profile → Payment Methods
3. **Click**: "Add Payment Method"
4. **Enter card details**:
   - Card: `4242 4242 4242 4242`
   - Expiry: `12/25`
   - CVC: `123`
   - Name: `Test User`
5. **Success!** ✅ Card should be added

### For New Users (Not Yet in Script)

1. **Register** new account in app
2. **Go to**: Profile → Payment Methods
3. **Click**: "Add Payment Method"
4. **See dialog**: "🔧 Setup Required"
5. **Action**: Run the script as shown in dialog
6. **Try again**: Payment method will now work

---

## 🐛 Troubleshooting

### Error: "Failed to create Stripe customer"

**Cause**: App tried to create customer without Cloud Functions

**Solution**: This is expected behavior! Run the script:
```bash
cd trippo_user
node scripts/create_stripe_test_customers.js
```

### Error: "Stripe customer not found"

**Symptoms**:
- User exists in app
- Can't add payment methods
- Dialog shows "Setup Required"

**Solution**:
```bash
# Run the script to create missing customers
node scripts/create_stripe_test_customers.js
```

### Error: "Invalid API key"

**Cause**: Stripe secret key not configured

**Solution**:
1. Get your secret key from [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)
2. Set as environment variable:
   ```bash
   export STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
   node scripts/create_stripe_test_customers.js
   ```

### Script Shows "No users found"

**Cause**: No users with `userType = "user"` in Firestore

**Solution**:
1. Register at least one passenger account in the app
2. Verify in Firestore that user has `userType: "user"`
3. Run script again

---

## 📦 Firestore Collections

### `stripeCustomers/`

**Document ID**: Firebase User UID  
**Created by**: Script (`create_stripe_test_customers.js`)

**Structure**:
```javascript
{
  userId: "abc123xyz789",
  stripeCustomerId: "cus_ABC123DEF456",
  email: "user@example.com",
  name: "John Doe",
  billingAddress: null,
  paymentMethods: [],
  defaultPaymentMethodId: null,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  isActive: true,
  metadata: {
    prefix: "BTRP",
    createdVia: "script",
    stripeCreatedAt: 1699012345
  }
}
```

---

## 🔄 Workflow Comparison

### Current Workflow (Script-Based) ✅

```
1. User registers in app
   └─ Creates user in Firestore

2. Admin runs script
   ├─ Reads users from Firestore
   ├─ Creates Stripe customers (secret key)
   └─ Saves customer IDs to Firestore

3. User adds payment method
   ├─ App checks if customer exists ✓
   ├─ Collects card (publishable key)
   └─ Attaches to Stripe customer
```

**Pros:**
- ✅ Simple setup
- ✅ No backend required
- ✅ Secure (secret key not in app)
- ✅ Works for testing

**Cons:**
- ⚠️ Manual script run required for new users
- ⚠️ Not automatic
- ⚠️ Not ideal for production scale

### Future Workflow (Cloud Functions) 🚀

```
1. User registers in app
   └─ Triggers Cloud Function
      ├─ Creates user in Firestore
      └─ Creates Stripe customer (secret key)

2. User adds payment method
   ├─ App checks if customer exists ✓
   ├─ Collects card (publishable key)
   └─ Attaches to Stripe customer
```

**Pros:**
- ✅ Fully automatic
- ✅ Scales to production
- ✅ Secure
- ✅ Professional setup

**Cons:**
- ⚠️ Requires Cloud Functions setup
- ⚠️ Requires Firebase Blaze plan
- ⚠️ More complex

---

## 🎯 Production Recommendations

### Short-Term (Testing Phase)

**Keep using the script approach:**
1. Register test users in app
2. Run script periodically:
   ```bash
   node scripts/create_stripe_test_customers.js
   ```
3. Test payment flows

**Best for:**
- Development
- Testing
- Small user base
- Quick prototyping

### Long-Term (Production)

**Migrate to Cloud Functions:**

1. **Create Cloud Function**: `createStripeCustomer`
   ```javascript
   exports.createStripeCustomer = functions.auth.user().onCreate(async (user) => {
     // Create Stripe customer
     // Save to Firestore
   });
   ```

2. **Update Repository**: Point to Cloud Function URL
   ```dart
   final String _functionsBaseUrl = 'https://us-central1-YOUR-PROJECT.cloudfunctions.net';
   ```

3. **Deploy**:
   ```bash
   firebase deploy --only functions
   ```

**Best for:**
- Production apps
- Large user base
- Automatic customer creation
- Professional deployment

---

## 🧪 Test Cards

Use these cards in test mode:

| Card Number | Type | Result |
|------------|------|--------|
| `4242 4242 4242 4242` | Visa | ✅ Success |
| `5555 5555 5555 4444` | Mastercard | ✅ Success |
| `3782 822463 10005` | Amex | ✅ Success |
| `4000 0000 0000 0002` | Visa | ❌ Declined |
| `4000 0000 0000 9995` | Visa | ❌ Insufficient Funds |

**Always use:**
- Any 3-digit CVC (4 for Amex)
- Any future expiry date

---

## 🔑 API Keys Reference

### Publishable Key (in app)
```dart
// lib/core/constants/stripe_constants.dart
static const String stripeTestPublishableKey = 'pk_test_...';
```

**Used for:**
- ✅ Collecting card details in app
- ✅ Creating payment methods
- ✅ Safe to expose in client code

### Secret Key (server-side only)
```javascript
// scripts/create_stripe_test_customers.js
const STRIPE_TEST_SECRET_KEY = 'sk_test_...';
```

**Used for:**
- ✅ Creating customers
- ✅ Charging cards
- ✅ Refunds
- ❌ **NEVER expose in client code**

---

## 📚 Related Documentation

- [STRIPE_SETUP_GUIDE.md](STRIPE_SETUP_GUIDE.md) - Initial setup instructions
- [STRIPE_TESTING_GUIDE.md](STRIPE_TESTING_GUIDE.md) - Testing scenarios
- [STRIPE_INTEGRATION_COMPLETE.md](STRIPE_INTEGRATION_COMPLETE.md) - Integration summary

---

## ✨ Summary

**Current Setup:**
- ✅ Script-based Stripe customer creation
- ✅ Secure (secret key not in app)
- ✅ Works for development/testing
- ⚠️ Requires manual script run for new users

**To Use:**
1. Register users in app
2. Run: `node scripts/create_stripe_test_customers.js`
3. Users can now add payment methods

**For Production:**
- Migrate to Firebase Cloud Functions
- Automatic customer creation
- Fully scalable solution

---

**Last Updated**: November 3, 2025  
**Status**: ✅ Working Solution for Development  
**Next Step**: Add payment methods and test!

