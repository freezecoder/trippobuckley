/**
 * Script to create Stripe test customers for users in Firestore
 * 
 * Usage:
 * node scripts/create_stripe_test_customers.js
 * 
 * This script:
 * 1. Reads users from Firestore with userType = "user" (passengers)
 * 2. Creates a Stripe customer for each user
 * 3. Stores the Stripe customer ID in the stripeCustomers collection
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Stripe test configuration
// IMPORTANT: Get your secret key from Stripe Dashboard > Developers > API keys
// The secret key must start with 'sk_test_' for test mode
// You can also set it as an environment variable: export STRIPE_SECRET_KEY=sk_test_...
const STRIPE_TEST_SECRET_KEY = process.env.STRIPE_SECRET_KEY || 'YOUR_STRIPE_SECRET_KEY_HERE'

// Validate API key before proceeding
if (STRIPE_TEST_SECRET_KEY === 'YOUR_STRIPE_SECRET_KEY_HERE' || !STRIPE_TEST_SECRET_KEY.startsWith('sk_test_')) {
  console.error('❌ ERROR: Invalid or missing Stripe secret key!');
  console.error('');
  console.error('📝 To fix this:');
  console.error('');
  console.error('Option 1: Set environment variable (Recommended)');
  console.error('  export STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE');
  console.error('  node scripts/create_stripe_test_customers.js');
  console.error('');
  console.error('Option 2: Edit the script directly');
  console.error('  Open: scripts/create_stripe_test_customers.js');
  console.error('  Replace: YOUR_STRIPE_SECRET_KEY_HERE');
  console.error('  With your Stripe test secret key from:');
  console.error('  https://dashboard.stripe.com/test/apikeys');
  console.error('');
  console.error('💡 Note: Your publishable key starts with pk_test_...');
  console.error('          Your SECRET key starts with sk_test_...');
  console.error('          You need the SECRET key for this script.');
  console.error('');
  process.exit(1);
}

/**
 * Create Stripe customer using test API
 */
async function createStripeCustomer(email, name, userId) {
  try {
    const fetch = (await import('node-fetch')).default;
    
    const response = await fetch('https://api.stripe.com/v1/customers', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${STRIPE_TEST_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        email: email,
        name: name,
        'metadata[prefix]': 'BTRP',
        'metadata[userId]': userId,
        'metadata[app]': 'BTrips',
        'metadata[createdVia]': 'script'
      })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Stripe API error: ${error}`);
    }

    const customer = await response.json();
    console.log(`✅ Created Stripe customer: ${customer.id} for ${email}`);
    return customer;
  } catch (error) {
    console.error(`❌ Failed to create Stripe customer for ${email}:`, error.message);
    throw error;
  }
}

/**
 * Save Stripe customer to Firestore
 */
async function saveStripeCustomerToFirestore(userId, stripeCustomer, email, name) {
  try {
    const customerData = {
      userId: userId,
      stripeCustomerId: stripeCustomer.id,
      email: email,
      name: name,
      billingAddress: null,
      paymentMethods: [],
      defaultPaymentMethodId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      metadata: {
        prefix: 'BTRP',
        createdVia: 'script',
        stripeCreatedAt: stripeCustomer.created
      }
    };

    await db.collection('stripeCustomers').doc(userId).set(customerData);
    console.log(`✅ Saved Stripe customer to Firestore for user ${userId}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to save to Firestore:`, error.message);
    throw error;
  }
}

/**
 * Main function
 */
async function main() {
  console.log('🚀 Starting Stripe customer creation for test users...\n');

  try {
    // Fetch all users with userType = "user" (passengers)
    const usersSnapshot = await db
      .collection('users')
      .where('userType', '==', 'user')
      .get();

    if (usersSnapshot.empty) {
      console.log('⚠️  No users found with userType = "user"');
      console.log('💡 Create some users first, then run this script again.\n');
      return;
    }

    console.log(`📊 Found ${usersSnapshot.size} user(s) to process\n`);

    let successCount = 0;
    let skipCount = 0;
    let errorCount = 0;

    for (const doc of usersSnapshot.docs) {
      const user = doc.data();
      const userId = doc.id;

      console.log(`\n📝 Processing user: ${user.email}`);

      // Check if Stripe customer already exists
      const existingCustomer = await db.collection('stripeCustomers').doc(userId).get();
      if (existingCustomer.exists) {
        console.log(`⏭️  Stripe customer already exists for ${user.email}`);
        skipCount++;
        continue;
      }

      try {
        // Create Stripe customer
        const stripeCustomer = await createStripeCustomer(
          user.email,
          user.name || user.email.split('@')[0],
          userId
        );

        // Save to Firestore
        await saveStripeCustomerToFirestore(
          userId,
          stripeCustomer,
          user.email,
          user.name || user.email.split('@')[0]
        );

        successCount++;
        console.log(`✅ Successfully processed ${user.email}\n`);
      } catch (error) {
        errorCount++;
        console.error(`❌ Error processing ${user.email}:`, error.message, '\n');
      }
    }

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 SUMMARY');
    console.log('='.repeat(60));
    console.log(`✅ Successfully created: ${successCount}`);
    console.log(`⏭️  Skipped (already exists): ${skipCount}`);
    console.log(`❌ Errors: ${errorCount}`);
    console.log(`📊 Total users processed: ${usersSnapshot.size}`);
    console.log('='.repeat(60) + '\n');

    if (successCount > 0) {
      console.log('🎉 Success! Stripe customers created.');
      console.log('📝 Next steps:');
      console.log('   1. Check Stripe Dashboard: https://dashboard.stripe.com/test/customers');
      console.log('   2. Check Firestore Console: stripeCustomers collection');
      console.log('   3. Test adding payment methods in the app\n');
    }

  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  } finally {
    // Cleanup
    await admin.app().delete();
  }
}

// Run the script
main().catch(console.error);

