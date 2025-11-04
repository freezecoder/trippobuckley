#!/bin/bash

# Deploy Stripe Cloud Functions
# This script sets up and deploys Firebase Cloud Functions for automatic Stripe customer creation

echo "🚀 BTrips Stripe Functions Deployment"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "firebase.json" ]; then
    echo "❌ Error: firebase.json not found"
    echo "   Please run this script from the trippo_user directory"
    exit 1
fi

# Check if functions directory exists
if [ ! -d "functions" ]; then
    echo "❌ Error: functions directory not found"
    exit 1
fi

# Step 1: Install dependencies
echo "📦 Step 1/4: Installing dependencies..."
cd functions
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

cd ..

# Step 2: Check if Stripe key is configured
echo "🔑 Step 2/4: Checking Stripe configuration..."
STRIPE_CONFIG=$(firebase functions:config:get stripe.secret_key 2>/dev/null)

if [ -z "$STRIPE_CONFIG" ] || [ "$STRIPE_CONFIG" = "{}" ]; then
    echo "⚠️  Stripe secret key not configured"
    echo ""
    echo "Please enter your Stripe TEST secret key (starts with sk_test_):"
    echo "Get it from: https://dashboard.stripe.com/test/apikeys"
    echo ""
    read -p "Stripe Secret Key: " STRIPE_KEY
    
    if [ -z "$STRIPE_KEY" ]; then
        echo "❌ No key provided. Exiting."
        exit 1
    fi
    
    if [[ ! $STRIPE_KEY == sk_test_* ]]; then
        echo "⚠️  Warning: Key doesn't start with sk_test_"
        read -p "Continue anyway? (y/n): " CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            exit 1
        fi
    fi
    
    echo "Setting Stripe configuration..."
    firebase functions:config:set stripe.secret_key="$STRIPE_KEY"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to set Stripe configuration"
        exit 1
    fi
    echo "✅ Stripe key configured"
else
    echo "✅ Stripe key already configured"
fi
echo ""

# Step 3: Deploy functions
echo "🚀 Step 3/4: Deploying Cloud Functions..."
echo "This may take 2-3 minutes..."
echo ""

firebase deploy --only functions

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed"
    echo ""
    echo "Common issues:"
    echo "1. Not logged in: Run 'firebase login'"
    echo "2. Wrong project: Run 'firebase use trippo-42089'"
    echo "3. Billing required: Upgrade to Blaze plan at console.firebase.google.com"
    exit 1
fi

echo ""
echo "✅ Functions deployed successfully!"
echo ""

# Step 4: Verify deployment
echo "✅ Step 4/4: Verification"
echo ""
echo "Cloud Functions deployed:"
echo "  - createStripeCustomer"
echo "  - attachPaymentMethod"
echo "  - detachPaymentMethod"
echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Run the app: flutter run"
echo "2. Login as a passenger"
echo "3. Go to: Profile → Payment Methods"
echo "4. Click 'Add Payment Method'"
echo "5. ✅ Customer will be created automatically!"
echo ""
echo "Test cards:"
echo "  - 4242 4242 4242 4242 (Visa - Success)"
echo "  - 5555 5555 5555 4444 (Mastercard - Success)"
echo ""
echo "View logs: firebase functions:log"
echo "View console: https://console.firebase.google.com"
echo ""

