# 🚀 Payment System Deployment Guide

**Quick Reference**: Deploy the new ride payment system

---

## ⚡ Quick Deploy (5 minutes)

### Step 1: Deploy Cloud Function

```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user/functions

# Install dependencies (if not already done)
npm install

# Deploy the new payment function
firebase deploy --only functions:processRidePayment
```

Expected output:
```
✔  functions[processRidePayment(us-central1)] Successful create operation.
Function URL: https://us-central1-trippo-42089.cloudfunctions.net/processRidePayment
```

### Step 2: Verify Stripe Configuration

```bash
# Check if Stripe secret key is configured
firebase functions:config:get stripe
```

**If not configured**, set it:
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY_HERE"
firebase deploy --only functions
```

### Step 3: Test the System

```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user

# Run the app
flutter run
```

**Test scenarios**:
1. Create a cash ride → Complete it → Click "Accept Cash Payment"
2. Create a card ride → Complete it → Wait 5 seconds → See payment processed

---

## 📋 Pre-Deployment Checklist

- [ ] Stripe account is active
- [ ] Test mode secret key is available (`sk_test_...`)
- [ ] Firebase project has Blaze (pay-as-you-go) plan for Cloud Functions
- [ ] Node.js and npm are installed
- [ ] Firebase CLI is installed (`npm install -g firebase-tools`)
- [ ] Logged into Firebase CLI (`firebase login`)

---

## 🔑 Stripe Keys

### Get Your Keys:

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)
2. Copy your **Secret key** (starts with `sk_test_...`)
3. Keep it secure - never commit to git!

### Configure Firebase:

```bash
# For TEST mode (recommended for development)
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"

# For PRODUCTION mode (only when ready for live payments)
firebase functions:config:set stripe.secret_key="sk_live_YOUR_KEY"

# Deploy after setting config
firebase deploy --only functions
```

---

## 🧪 Testing After Deployment

### Test Cash Payment:

1. **Book a ride as user**:
   - Select "Cash" as payment method
   - Complete booking

2. **Accept as driver**:
   - See orange "Cash" badge
   - Complete ride
   - Click "Accept Cash Payment"

3. **Verify**:
   - Check Firestore: `paymentStatus` = 'completed'
   - Ride should move to history

### Test Card Payment:

1. **Ensure user has saved payment method**:
   - Go to Profile → Payment Methods
   - Add a test card: `4242 4242 4242 4242`

2. **Book a ride as user**:
   - Select "Card" as payment method
   - Complete booking

3. **Accept as driver**:
   - See blue "Card" badge
   - Complete ride
   - Wait 5 seconds

4. **Verify**:
   - Should see "Payment processed successfully!"
   - Check Firestore: `paymentStatus` = 'completed', `stripePaymentIntentId` = 'pi_...'
   - Check Stripe Dashboard: Payment should appear

### Test Error Handling:

1. **Card with insufficient funds**:
   - Use test card: `4000 0000 0000 9995`
   - Should show error message

2. **Invalid payment method**:
   - Manually set `paymentMethodId` to invalid value
   - Should show error, Firestore should have `paymentStatus` = 'failed'

---

## 📊 Monitoring

### View Cloud Function Logs:

```bash
# Real-time logs
firebase functions:log --only processRidePayment

# Last 100 logs
firebase functions:log --only processRidePayment --limit 100

# Filter by time
firebase functions:log --only processRidePayment --since 1h
```

### Check Stripe Dashboard:

1. Go to [Stripe Dashboard > Payments](https://dashboard.stripe.com/test/payments)
2. Look for recent payment intents
3. Check metadata for `rideId` to match with your test

### Firestore Verification:

1. Go to [Firebase Console > Firestore](https://console.firebase.google.com)
2. Navigate to `rideRequests` or `rideHistory` collection
3. Find your test ride
4. Check these fields:
   - `paymentMethod`: 'cash' or 'card'
   - `paymentStatus`: 'pending', 'completed', or 'failed'
   - `stripePaymentIntentId`: Should exist for card payments
   - `paymentProcessedAt`: Timestamp when payment completed

---

## 🐛 Troubleshooting

### "Function deployment failed"

**Solution**:
```bash
# Check you're logged in
firebase login

# Check you're in the right project
firebase use --add

# Try deploying all functions
firebase deploy --only functions
```

### "Stripe key not configured"

**Solution**:
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"
firebase deploy --only functions
```

### "Payment processing failed"

**Possible causes**:
1. User doesn't have a saved payment method
2. Stripe key is invalid
3. Payment method is expired or declined

**Check**:
- Cloud function logs: `firebase functions:log --only processRidePayment`
- Stripe Dashboard for error details
- User's payment methods in Firestore: `stripeCustomers/{userId}`

### "Accept Cash Payment button not showing"

**Check**:
- Ride status is 'completed': `ride.status == RideStatus.completed`
- Payment method is 'cash': `ride.paymentMethod == 'cash'`
- Payment status is 'pending': `ride.paymentStatus == 'pending'`
- Driver is viewing their active rides tab

---

## 🎯 Production Deployment

### Before Going Live:

1. **Switch to Live Stripe Keys**:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_live_YOUR_LIVE_KEY"
   firebase deploy --only functions
   ```

2. **Update Stripe Constants** (in app):
   ```dart
   // In lib/core/constants/stripe_constants.dart
   static const String publishableKey = 'pk_live_YOUR_LIVE_KEY';
   ```

3. **Build Release App**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

4. **Test with Real Card**:
   - Use a real (low-value) transaction
   - Verify payment appears in Stripe
   - Verify ride status updates correctly

5. **Monitor First Few Transactions**:
   - Watch cloud function logs
   - Check Stripe Dashboard
   - Verify customer receipts

---

## 💰 Cost Estimation

### Firebase Cloud Functions:

- **Free Tier**: 2M invocations/month
- **Cost**: $0.40 per million invocations
- **Estimate**: ~$0.40/month for 1000 rides

### Stripe Fees:

- **Per Transaction**: 2.9% + $0.30
- **Example**: $25 ride = $1.03 fee
- **Note**: Only applies to card payments, not cash

### Total Monthly Cost:

For 1000 rides (50% cash, 50% card):
- Firebase: ~$0.40
- Stripe (500 card payments @ $25 avg): ~$515
- **Total**: ~$515.40/month

---

## 📞 Support

### Need Help?

1. Check logs: `firebase functions:log`
2. Review Firestore data structure
3. Check Stripe Dashboard for payment details
4. Review `RIDE_PAYMENT_SYSTEM.md` for full documentation

### Report Issues:

Include in your report:
- Error message from app
- Cloud function logs
- Ride ID
- User ID
- Payment method used
- Expected vs actual behavior

---

## ✅ Post-Deployment Checklist

After deploying, verify:

- [ ] Cloud function deployed successfully
- [ ] Stripe configuration verified
- [ ] Test cash payment works
- [ ] Test card payment works
- [ ] Error handling works
- [ ] Logs are accessible
- [ ] Firestore updates correctly
- [ ] Stripe charges appear in dashboard
- [ ] Driver sees payment status correctly
- [ ] Earnings update correctly

---

## 🎉 Success!

Once all checks pass, your payment system is **live and operational**!

**Quick Test Command**:
```bash
# Deploy and test in one go
firebase deploy --only functions:processRidePayment && flutter run
```

---

**Last Updated**: November 4, 2025  
**Deployment Time**: ~5 minutes  
**Status**: 🟢 **READY FOR PRODUCTION**

