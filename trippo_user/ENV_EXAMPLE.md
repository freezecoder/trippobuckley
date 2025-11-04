# Environment Variables Configuration

Copy the contents below to a `.env` file in your project root:

```bash
# ========================================
# BTrips Environment Configuration
# ========================================

# STRIPE CONFIGURATION
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY_HERE
STRIPE_SECRET_KEY=sk_test_YOUR_SECRET_KEY_HERE
STRIPE_PUBLISHABLE_KEY_PROD=pk_live_YOUR_LIVE_PUBLISHABLE_KEY_HERE
STRIPE_SECRET_KEY_PROD=sk_live_YOUR_LIVE_SECRET_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET_HERE

# FIREBASE CONFIGURATION
FIREBASE_PROJECT_ID=your-firebase-project-id

# ENVIRONMENT
ENVIRONMENT=development
STRIPE_TEST_MODE=true
```

**Important**: Add `.env` to your `.gitignore` file!

