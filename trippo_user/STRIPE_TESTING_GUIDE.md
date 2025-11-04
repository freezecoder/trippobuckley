# 🧪 Stripe Payment Integration - Testing Guide

**Date**: November 2, 2025  
**Status**: ✅ Ready for Testing  
**Phase**: Development/Testing

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Run the Test Script](#step-1-run-the-test-script)
3. [Step 2: Test in the App](#step-2-test-in-the-app)
4. [Step 3: Verify in Stripe Dashboard](#step-3-verify-in-stripe-dashboard)
5. [Test Scenarios](#test-scenarios)
6. [Troubleshooting](#troubleshooting)
7. [What's Been Implemented](#whats-been-implemented)

---

## ✅ Prerequisites

Before testing, ensure you have:

1. ✅ **Node.js installed** (for running the test script)
2. ✅ **Firebase credentials** (`firestore_credentials.json` in project root)
3. ✅ **Stripe test API keys** configured in `stripe_constants.dart`
4. ✅ **At least one test user account** created in the app (userType = "user")
5. ✅ **Dependencies installed**:
   ```bash
   cd trippo_user
   flutter pub get
   
   # For the script
   npm install firebase-admin node-fetch
   ```

---

## 🚀 Step 1: Run the Test Script

The test script creates Stripe customers for all existing users in Firestore.

### Run the Script

```bash
cd trippo_user
node scripts/create_stripe_test_customers.js
```

### Expected Output

```
🚀 Starting Stripe customer creation for test users...

📊 Found 2 user(s) to process

📝 Processing user: test@example.com
✅ Created Stripe customer: cus_Pq7RsTuVwXyZ1234 for test@example.com
✅ Saved Stripe customer to Firestore for user abc123xyz789
✅ Successfully processed test@example.com

📝 Processing user: john@example.com
✅ Created Stripe customer: cus_Mn5OpQrStUvWx890 for john@example.com
✅ Saved Stripe customer to Firestore for user def456uvw012
✅ Successfully processed john@example.com

============================================================
📊 SUMMARY
============================================================
✅ Successfully created: 2
⏭️  Skipped (already exists): 0
❌ Errors: 0
📊 Total users processed: 2
============================================================

🎉 Success! Stripe customers created.
📝 Next steps:
   1. Check Stripe Dashboard: https://dashboard.stripe.com/test/customers
   2. Check Firestore Console: stripeCustomers collection
   3. Test adding payment methods in the app
```

### Verify in Firestore

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Go to Firestore Database
3. Look for `stripeCustomers` collection
4. Each document should have:
   - `userId`: Firebase user ID
   - `stripeCustomerId`: Stripe customer ID (e.g., `cus_xxxxx`)
   - `email`: User email
   - `name`: User name
   - `paymentMethods`: Empty array (initially)
   - `createdAt`: Timestamp

### Verify in Stripe Dashboard

1. Go to [Stripe Test Dashboard](https://dashboard.stripe.com/test/customers)
2. You should see customers with:
   - Name and email matching your Firestore users
   - Metadata: `prefix: BTRP`, `userId: {Firebase UID}`
   - No payment methods yet

---

## 📱 Step 2: Test in the App

Now test the full payment flow in your Flutter app.

### Test Flow

#### 1. Login as a User (Passenger)

```bash
flutter run
```

- Login with: `test@example.com`
- Should navigate to User Main screen

#### 2. Navigate to Payment Methods

```
Profile Tab → Payment Methods
```

You should see:
- Empty state with icon and message
- Blue "Add Payment Method" button

#### 3. Add a Test Card

Click "Add Payment Method"

**Test Cards to Use**:

| Card Number | CVC | Expiry | Result |
|-------------|-----|--------|--------|
| `4242 4242 4242 4242` | Any 3 digits | Any future | ✅ Success |
| `4000 0000 0000 0002` | Any 3 digits | Any future | ❌ Declined |
| `4000 0000 0000 9995` | Any 3 digits | Any future | ❌ Insufficient Funds |

**Fill in the form**:
- Cardholder Name: `John Doe`
- Card Number: `4242 4242 4242 4242`
- Expiry: `12/25`
- CVC: `123`

**Expected Behavior**:
1. Bottom sheet appears with card input
2. Enter cardholder name and card details
3. "Add Card" button becomes enabled when card is valid
4. Click "Add Card"
5. Loading indicator shows
6. Success message: "✅ Payment method added successfully"
7. Sheet closes
8. Card appears in list:
   ```
   Visa •••• 4242
   Expires 12/25
   [Default]
   ```

#### 4. Test Card Actions

**Set as Default** (if you have multiple cards):
- Click ⋮ (more menu) on a card
- Select "Set as default"
- Card should show blue "Default" badge

**Remove Card**:
- Click ⋮ (more menu) on a card
- Select "Remove"
- Confirmation dialog appears
- Click "Remove"
- Success message: "✅ Payment method removed"
- Card disappears from list

#### 5. Test Multiple Cards

Add 2-3 different cards:
1. First card: `4242 4242 4242 4242` (Visa)
2. Second card: `5555 5555 5555 4444` (Mastercard)
3. Third card: `3782 822463 10005` (Amex)

**Expected**:
- All cards appear in list
- Each shows correct brand and last 4 digits
- Default badge on the first/default card
- Can switch default
- Can remove any card

---

## 🔍 Step 3: Verify in Stripe Dashboard

After adding payment methods in the app:

### 1. Check Customer Details

Go to: [Stripe Test Dashboard > Customers](https://dashboard.stripe.com/test/customers)

1. Find your customer (search by email)
2. Click to view details
3. Under "Payment methods" section:
   - Should see the cards you added
   - Shows brand, last 4, expiry
   - One marked as default

### 2. Check Metadata

In customer details, scroll to "Metadata":
- `prefix`: BTRP
- `userId`: {Your Firebase User ID}
- `app`: BTrips
- `createdVia`: script or mobile_app

### 3. Test Payments (Optional)

For a complete test, you can create a test payment:
```javascript
// This would be done via Cloud Functions in production
// For now, just verify payment methods are attached
```

---

## 🧪 Test Scenarios

### Scenario 1: New User First Time

**Steps**:
1. Create new user account in app
2. Login as that user
3. Go to Payment Methods
4. See empty state
5. Click "Add Payment Method"
6. If customer doesn't exist:
   - Should show "Creating Stripe account..."
   - Then show card input form
7. Add card: `4242 4242 4242 4242`
8. Should succeed and show card in list

**Expected Firestore Changes**:
- New document in `stripeCustomers/{userId}`
- Contains `stripeCustomerId`
- `paymentMethods` array with 1 item

**Expected Stripe Changes**:
- New customer created
- Payment method attached
- Set as default

### Scenario 2: Existing Customer Adds Second Card

**Steps**:
1. Login with user who already has 1 card
2. Go to Payment Methods
3. See existing card
4. Click "Add Payment Method"
5. Add different card: `5555 5555 5555 4444`
6. New card should appear in list

**Expected**:
- First card still shows "Default"
- Second card added without "Default" badge
- Can set second card as default

### Scenario 3: Remove Default Card

**Steps**:
1. Have 2+ cards, one is default
2. Remove the default card
3. System should handle gracefully

**Expected**:
- Default card removed
- No card marked as default (or oldest becomes default)
- Can set any remaining card as default

### Scenario 4: Expired Card

**Steps**:
1. Add card with past expiry: `01/20`
2. Card should show "Expired" badge in red

**Expected**:
- Card saved successfully
- Red "Expired" badge appears
- Can still remove the card

### Scenario 5: Card Declined

**Steps**:
1. Try to add: `4000 0000 0000 0002`
2. Should get error from Stripe

**Expected**:
- Error message shown
- Card NOT added to list
- Can try again with valid card

---

## ❌ Troubleshooting

### Issue: "No such customer" error

**Cause**: Stripe customer not created yet

**Solution**:
1. Run the test script: `node scripts/create_stripe_test_customers.js`
2. Or wait for app to create customer on first add payment method

### Issue: "Invalid API Key"

**Cause**: Wrong Stripe key or key not set

**Solution**:
1. Check `lib/core/constants/stripe_constants.dart`
2. Ensure `publishableKey` starts with `pk_test_`
3. Get key from [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)

### Issue: Script fails with "Cannot find module"

**Cause**: Dependencies not installed

**Solution**:
```bash
cd trippo_user
npm install firebase-admin node-fetch
```

### Issue: "Card was declined" for test card

**Cause**: Using wrong test card or wrong environment

**Solution**:
- In test mode, use: `4242 4242 4242 4242`
- Check Stripe dashboard shows "TEST MODE" orange banner
- Verify expiry is in the future

### Issue: Payment methods not loading

**Cause**: Provider not refreshing

**Solution**:
1. Pull to refresh on screen
2. Or tap refresh icon in app bar
3. Check Firestore rules allow read access

### Issue: "stripeCustomers" collection doesn't exist

**Cause**: Script not run or no users in database

**Solution**:
1. Create test users first
2. Run the script
3. Or add payment method in app (creates customer automatically)

---

## ✅ What's Been Implemented

### ✅ Backend/Data Layer

1. **Stripe Repository** (`stripe_repository.dart`)
   - ✅ Create customer
   - ✅ Get customer
   - ✅ Add payment method
   - ✅ Remove payment method
   - ✅ Set default payment method
   - ✅ List payment methods

2. **Stripe Providers** (`stripe_providers.dart`)
   - ✅ `stripeRepositoryProvider`
   - ✅ `stripeCustomerProvider`
   - ✅ `paymentMethodsProvider`
   - ✅ `defaultPaymentMethodProvider`
   - ✅ `hasPaymentMethodsProvider`

3. **Models**
   - ✅ `StripeCustomerModel`
   - ✅ `PaymentMethodModel`
   - ✅ `BillingAddress`

4. **Firebase Collections**
   - ✅ `stripeCustomers` collection schema
   - ✅ `stripePaymentIntents` collection schema
   - ✅ `stripeTransactions` collection schema

### ✅ Frontend/UI Layer

1. **Payment Methods Screen** (`payment_methods_screen.dart`)
   - ✅ List all payment methods
   - ✅ Empty state
   - ✅ Loading state
   - ✅ Error state with retry
   - ✅ Refresh functionality
   - ✅ Card display with brand icon
   - ✅ Default badge
   - ✅ Expired badge
   - ✅ More menu (set default, remove)

2. **Add Payment Method Sheet** (`_AddPaymentMethodSheet`)
   - ✅ Stripe CardField integration
   - ✅ Cardholder name input
   - ✅ Form validation
   - ✅ Card completion detection
   - ✅ Loading states
   - ✅ Error handling
   - ✅ Success feedback
   - ✅ Auto-create customer if needed

3. **Features**
   - ✅ Add new payment method
   - ✅ Remove payment method (with confirmation)
   - ✅ Set default payment method
   - ✅ View all payment methods
   - ✅ Refresh payment methods
   - ✅ Secure card input (via Stripe SDK)
   - ✅ Brand detection (Visa, Mastercard, Amex, etc.)
   - ✅ Expiry validation

### ✅ Testing Tools

1. **Test Script** (`create_stripe_test_customers.js`)
   - ✅ Bulk create Stripe customers
   - ✅ Sync with Firestore
   - ✅ Skip existing customers
   - ✅ Error handling
   - ✅ Summary report

2. **Documentation**
   - ✅ Stripe Setup Guide
   - ✅ Testing Guide (this document)
   - ✅ Code comments

---

## 🎯 Next Steps

### Immediate (Testing)
- ✅ Run test script
- ✅ Test adding payment methods
- ✅ Test removing payment methods
- ✅ Test setting default
- ✅ Verify in Stripe Dashboard

### Soon (Production Prep)
- ⏳ Create Firebase Cloud Functions for:
  - Creating customers (optional, app does it)
  - Charging cards
  - Webhooks handling
  - Refunds
- ⏳ Deploy Firestore security rules
- ⏳ Add billing address collection
- ⏳ Implement actual payment processing

### Later (Enhancements)
- ⏳ Apple Pay / Google Pay integration
- ⏳ Saved billing addresses
- ⏳ Payment history view
- ⏳ Receipt generation
- ⏳ Refund management UI

---

## 🔐 Security Notes

### ✅ What's Secure

1. **Card Data**:
   - ✅ Never stored in Firestore
   - ✅ Only Stripe tokens stored
   - ✅ Only last 4 digits visible
   - ✅ Uses Stripe SDK (PCI compliant)

2. **API Keys**:
   - ✅ Publishable key in app (safe)
   - ✅ Secret key ONLY in backend (not in app)
   - ✅ Test keys for development

3. **Data Access**:
   - ⚠️ Need to deploy Firestore rules (TODO)
   - ✅ Repository pattern limits access
   - ✅ User can only access own data

### ⚠️ Before Production

1. Deploy Firestore security rules:
```javascript
// stripeCustomers collection
match /stripeCustomers/{userId} {
  allow read, write: if request.auth.uid == userId;
}
```

2. Move API keys to environment variables

3. Implement Cloud Functions for charges

4. Set up webhook endpoints

5. Enable Stripe fraud detection

---

## 📞 Support

### If You Get Stuck

1. **Check Logs**:
   - Flutter console for app errors
   - Stripe Dashboard > Logs for API errors
   - Firebase Console > Firestore for data

2. **Common Solutions**:
   - Re-run test script
   - Clear app data and reinstall
   - Check API keys are correct
   - Verify test mode is enabled

3. **Resources**:
   - Stripe Docs: https://stripe.com/docs
   - Flutter Stripe Plugin: https://pub.dev/packages/flutter_stripe
   - Firebase Console: https://console.firebase.google.com

---

## ✅ Success Criteria

You'll know it's working when:

✅ Test script creates customers successfully  
✅ Firestore shows `stripeCustomers` collection  
✅ Stripe Dashboard shows test customers  
✅ App can add cards using test card numbers  
✅ Cards appear in Payment Methods screen  
✅ Can set default payment method  
✅ Can remove payment methods  
✅ Stripe Dashboard shows attached payment methods  
✅ No errors in console  

---

**Happy Testing! 🎉**

---

**Last Updated**: November 2, 2025  
**Version**: 1.0.0  
**Status**: ✅ Ready for Testing

