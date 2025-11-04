# 🔍 Web Payment Debugging Guide

**Date**: November 3, 2025  
**Status**: Enhanced with detailed logging

---

## 🎯 What to Check

### Before Testing

1. **Hard Refresh Browser**
   ```
   Chrome/Firefox/Safari: Ctrl/Cmd + Shift + R
   ```
   This ensures JavaScript changes are loaded.

2. **Open Developer Console**
   ```
   Chrome: F12 or Ctrl/Cmd + Option + J
   Safari: Develop → Show JavaScript Console
   Firefox: F12
   ```

3. **Clear Console**
   - Click the 🚫 (clear) button
   - Start with a clean slate

---

## 🧪 Test Flow with Logging

### Step 1: Open Payment Screen

```
Profile → Payment Methods → Add Payment Method
```

**Check console for:**
```
✅ Stripe.js loaded successfully
```

If you see this, Stripe is ready!

### Step 2: Fill Out Card Form

```
Card Number: 4242 4242 4242 4242
Expiry: 12 / 25
CVC: 123
Name: Test User
```

### Step 3: Click "Add Card"

**Watch console - you should see:**

```
🌐 ===== WEB PAYMENT FLOW START =====
📝 Card details:
   Name: Test User
   Card: 4242424242424242
   Exp: 12/25

🔒 Step 1: Creating Stripe token...
🔍 Calling JavaScript function: createStripeToken
   Args: [Test User, 4242424242424242, 12, 2025, 123]
✅ Function found: createStripeToken
📞 JavaScript function called, waiting for promise...
Creating card token...
✅ Card token created: tok_xxxxxxxxxxxx
✅ JavaScript promise resolved
   Result type: ...
✅ Result converted: {success: true, token: tok_xxxx, ...}
📦 Token result: {success: true, token: tok_xxxx, ...}
✅ Token created successfully: tok_xxxxxxxxxxxx

📤 Step 2: Sending token to Cloud Function...
   URL: https://us-central1-trippo-42089.cloudfunctions.net/attachPaymentMethod
   User ID: your_user_id
   Token: tok_xxxxxxxxxxxx
   Request body: {userId: ..., token: ..., cardholderName: ..., setAsDefault: true}
📥 Cloud Function response:
   Status: 200
   Body: {success: true, message: ..., paymentMethod: {...}}
✅ Payment method created and attached!
   Payment Method ID: pm_xxxxxxxxxxxx
   Card: visa •••• 4242
🌐 ===== WEB PAYMENT FLOW COMPLETE =====
```

---

## ❌ Common Errors and Fixes

### Error 1: "JavaScript function createStripeToken not found"

**Console shows:**
```
❌ JavaScript function createStripeToken not found in window object
```

**Cause:** JavaScript not loaded or wrong function name

**Fix:**
1. Hard refresh: Ctrl/Cmd + Shift + R
2. Check browser console for:
   ```javascript
   console.log(typeof window.createStripeToken)
   // Should show: "function"
   ```
3. If undefined, rebuild web:
   ```bash
   flutter clean
   flutter run -d chrome
   ```

### Error 2: "Stripe not initialized"

**Console shows:**
```
❌ Stripe token creation failed: Stripe not initialized
```

**Cause:** Stripe.js didn't load or failed to initialize

**Fix:**
1. Check network tab - did `https://js.stripe.com/v3/` load?
2. Check for ad blockers blocking Stripe
3. Check browser console for:
   ```javascript
   console.log(window.stripe)
   // Should NOT be null
   ```

### Error 3: "Your card number is invalid"

**Console shows:**
```
❌ Token creation error: Your card number is invalid
```

**Cause:** Invalid card format

**Fix:**
- Use test card: `4242 4242 4242 4242`
- Ensure spaces are stripped before sending
- Check console shows: `Card: 4242424242424242` (no spaces)

### Error 4: "Customer not found"

**Console shows:**
```
❌ Cloud Function error: Customer not found
```

**Cause:** Stripe customer doesn't exist for this user

**Fix:**
```bash
# Run the customer creation script
node scripts/create_stripe_test_customers.js

# Or trigger auto-creation (should happen automatically)
# Cloud Function should create customer first
```

### Error 5: "Failed to attach payment method"

**Check Cloud Function logs:**
```bash
firebase functions:log --only attachPaymentMethod
```

Look for specific Stripe errors.

---

## 🔍 Debugging Checklist

### In Browser Console

- [ ] `✅ Stripe.js loaded successfully` appears on page load
- [ ] `✅ Google Maps API loaded successfully` appears
- [ ] No red errors before clicking "Add Card"
- [ ] `window.stripe` is not null
- [ ] `typeof window.createStripeToken` is "function"

### When Adding Card

- [ ] See: `🌐 ===== WEB PAYMENT FLOW START =====`
- [ ] See: Card details printed correctly
- [ ] See: `Creating card token...`
- [ ] See: `✅ Card token created: tok_xxx`
- [ ] See: `📤 Step 2: Sending token to Cloud Function...`
- [ ] See: `Status: 200`
- [ ] See: `✅ Payment method created and attached!`
- [ ] See: `🌐 ===== WEB PAYMENT FLOW COMPLETE =====`

### In Firestore

After successful addition:
- [ ] Go to: https://console.firebase.google.com
- [ ] Collection: `stripeCustomers`
- [ ] Find your user document
- [ ] Check: `paymentMethods` array has new card
- [ ] Check: `defaultPaymentMethodId` is set

### In Stripe Dashboard

- [ ] Go to: https://dashboard.stripe.com/test/customers
- [ ] Find customer by email
- [ ] Check: Payment method attached
- [ ] Check: Card shows correct last 4 digits

---

## 🛠️ Manual JavaScript Test

Open browser console and run:

```javascript
// Test 1: Check Stripe is loaded
console.log('Stripe:', window.stripe);
console.log('Function:', typeof window.createStripeToken);

// Test 2: Try creating a token manually
window.createStripeToken('Test User', '4242424242424242', 12, 2025, '123')
  .then(result => {
    console.log('✅ Token created:', result);
  })
  .catch(error => {
    console.error('❌ Error:', error);
  });
```

**Expected result:**
```javascript
✅ Token created: {
  success: true,
  token: "tok_...",
  last4: "4242",
  brand: "Visa",
  expMonth: 11,
  expYear: 2026
}
```

---

## 📊 What Each Log Means

### `🌐 WEB PAYMENT FLOW START`
- Triggered when you click "Add Card"
- Shows you're using web implementation

### `🔒 Step 1: Creating Stripe token`
- About to call Stripe.js
- Card details shown (for debugging)

### `🔍 Calling JavaScript function: createStripeToken`
- Dart calling into JavaScript
- Shows arguments being passed

### `Creating card token...`
- **FROM JavaScript** (in index.html)
- Stripe.js is actually processing the card

### `✅ Card token created: tok_xxx`
- **FROM JavaScript**
- Token successfully created by Stripe

### `📤 Step 2: Sending token to Cloud Function`
- Dart received token
- About to call Firebase Cloud Function

### `📥 Cloud Function response: Status: 200`
- Cloud Function executed successfully
- Payment method created and attached

### `✅ Payment method created and attached!`
- Complete success!
- Card should appear in list

---

## 🚨 Red Flags

### Bad Signs (Fix These)

❌ **No Stripe.js log on page load**
- Stripe didn't load
- Check network tab

❌ **"function not found"**
- JavaScript not loaded
- Hard refresh browser

❌ **"Stripe token creation failed:" with no details**
- Check browser console for JavaScript errors
- May be blocked by ad blocker

❌ **Status: 400 or 500 from Cloud Function**
- Check function logs: `firebase functions:log`
- May be missing customer or config issue

### Good Signs (Working Correctly)

✅ **"Card token created: tok_xxxx"**
- Stripe.js working

✅ **"Status: 200"**
- Cloud Function working

✅ **"Payment method created and attached!"**
- Everything working!

---

## 🔧 Quick Fixes

### If Nothing Shows in Console

```bash
# Rebuild from scratch
flutter clean
flutter pub get
flutter run -d chrome
```

### If Stripe.js Errors

Check `web/index.html`:
- Stripe script before Flutter script? ✅
- Correct publishable key? ✅
- Function defined? ✅

### If Cloud Function Errors

```bash
# Check if deployed
firebase functions:list

# Check logs
firebase functions:log --only attachPaymentMethod --limit 10

# Redeploy if needed
firebase deploy --only functions
```

---

## ✅ Success Criteria

You know it's working when you see:

1. ✅ Token created in browser
2. ✅ Cloud Function returns 200
3. ✅ Card appears in payment methods list
4. ✅ Firestore has payment method data
5. ✅ Stripe Dashboard shows attached payment method

---

## 📞 Next Steps

1. **Hard refresh** your browser
2. **Open console** (F12)
3. **Try adding card** again
4. **Share console logs** if issues persist

With all the logging added, we can now see exactly where it's failing!

---

**Run the app and check console output - let's see what's happening!** 🔍

