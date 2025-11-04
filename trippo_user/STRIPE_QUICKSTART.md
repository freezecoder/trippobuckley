# ⚡ Stripe Payment - Quick Start

**Time to setup**: 5 minutes  
**User experience**: Fully automatic  
**Manual steps**: None after deployment

---

## 🎯 What You're Getting

✅ **Automatic** Stripe customer creation  
✅ **One-click** payment method addition  
✅ **Secure** server-side key management  
✅ **Production-ready** architecture  
✅ **Zero friction** for end users

---

## 🚀 Setup (One Time)

### Option 1: Automated Script (Easiest)

```bash
cd trippo_user
./deploy-stripe-functions.sh
```

The script will:
1. Install dependencies
2. Ask for your Stripe secret key
3. Deploy Cloud Functions
4. Verify deployment

**That's it!** 🎉

### Option 2: Manual Setup

```bash
# 1. Install dependencies
cd trippo_user/functions
npm install

# 2. Configure Stripe key
cd ..
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY_HERE"

# 3. Deploy
firebase deploy --only functions
```

**Get your key**: [Stripe Dashboard → API Keys](https://dashboard.stripe.com/test/apikeys)

---

## 🧪 Test It

```bash
# 1. Run the app
flutter run

# 2. Test flow
- Register/Login as passenger
- Go to: Profile → Payment Methods
- Click: "Add Payment Method"
- ✅ Account created automatically!
- Add card: 4242 4242 4242 4242
- ✅ Success!
```

---

## 🎉 What Happens Now

### User Experience

```
User clicks "Add Payment Method"
  ↓
Shows: "Creating payment account..." (2 sec)
  ↓
Shows: "✅ Account created!"
  ↓
Card input form appears
  ↓
User adds card
  ↓
Done! No scripts, no manual steps
```

### Behind the Scenes

1. **App** checks if Stripe customer exists
2. **App** calls Cloud Function (if needed)
3. **Cloud Function** creates customer in Stripe
4. **Cloud Function** saves to Firestore
5. **App** proceeds with adding card
6. **All automatic!** ✨

---

## 📋 Requirements

### Firebase

- ✅ Firebase project (you have: trippo-42089)
- ✅ Blaze plan (pay-as-you-go) for Cloud Functions
- ⚠️ First 2M function calls/month are FREE

**Cost estimate**: $0-1/month for typical usage

### Stripe

- ✅ Stripe account (test mode)
- ✅ Publishable key (in app - already set)
- ✅ Secret key (for Cloud Functions)

**Get keys**: [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)

---

## 🐛 Troubleshooting

### "Unable to connect to payment server"

```bash
# Functions not deployed yet
cd trippo_user
./deploy-stripe-functions.sh
```

### "Stripe key not configured"

```bash
# Set the key
firebase functions:config:set stripe.secret_key="sk_test_..."
firebase deploy --only functions
```

### "Billing not enabled"

1. Go to: [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Upgrade to Blaze plan (pay-as-you-go)
4. First 2M calls/month are FREE

---

## 📚 Documentation

- **AUTOMATIC_STRIPE_SETUP.md** - Complete setup guide
- **STRIPE_SETUP_GUIDE.md** - Initial Stripe configuration
- **STRIPE_TESTING_GUIDE.md** - Testing scenarios
- **STRIPE_INTEGRATION_COMPLETE.md** - Technical details

---

## ✅ Checklist

Setup complete when:

- [ ] Ran deployment script or manual setup
- [ ] Functions show "Active" in Firebase Console
- [ ] Tested: New user can add payment method
- [ ] Tested: No manual script needed
- [ ] Tested: Customer created automatically

---

## 🎯 Summary

**Before**: Users needed to run terminal scripts ❌  
**Now**: Everything automatic ✅

**Setup time**: 5 minutes  
**User friction**: Zero  
**Production ready**: Yes  
**Scalable**: Yes (2M free calls/month)

---

**Need help?** Check the detailed guides or Cloud Function logs:

```bash
# View logs
firebase functions:log

# View specific function
firebase functions:log --only createStripeCustomer
```

---

**Created**: November 3, 2025  
**Status**: ✅ **READY TO USE**  
**Time saved**: Hours → Minutes → Automatic

