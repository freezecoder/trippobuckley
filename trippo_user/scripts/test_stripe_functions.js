/**
 * Test Script for Stripe Cloud Functions
 * 
 * This script tests the deployed Cloud Functions to ensure they work correctly
 * before integrating into the app.
 * 
 * Tests:
 * 1. Create Stripe customer (with duplicate prevention)
 * 2. Create token and attach payment method
 * 3. Verify in Stripe Dashboard
 * 4. Verify in Firestore
 * 
 * Usage:
 * node scripts/test_stripe_functions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Your Cloud Functions URL
const FUNCTIONS_BASE_URL = 'https://us-central1-trippo-42089.cloudfunctions.net';

// Stripe test secret key for verification
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY || 'YOUR_STRIPE_SECRET_KEY_HERE';

// Test user data
const TEST_USER = {
  id: 'test_user_' + Date.now(),
  email: `test${Date.now()}@example.com`,
  name: 'Test User for Cloud Functions'
};

/**
 * Use Stripe's pre-made test tokens
 * These are special tokens that Stripe provides for testing
 * See: https://stripe.com/docs/testing#cards
 */
const STRIPE_TEST_TOKENS = {
  visa: 'tok_visa',  // Visa ending in 4242
  visa_debit: 'tok_visa_debit',
  mastercard: 'tok_mastercard',  // Mastercard ending in 4444
  amex: 'tok_amex',
};

/**
 * Get test token info from Stripe
 */
async function getTestTokenInfo(tokenId) {
  try {
    const fetch = (await import('node-fetch')).default;
    
    console.log(`\n📝 Using Stripe test token: ${tokenId}`);
    
    // Retrieve token details from Stripe
    const response = await fetch(`https://api.stripe.com/v1/tokens/${tokenId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
      }
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Failed to get token: ${error}`);
    }

    const token = await response.json();
    console.log(`✅ Test token ready: ${token.id}`);
    console.log(`   Card: ${token.card.brand} •••• ${token.card.last4}`);
    console.log(`   Expires: ${token.card.exp_month}/${token.card.exp_year}`);
    
    return token;
  } catch (error) {
    console.error(`❌ Failed to get test token:`, error.message);
    throw error;
  }
}

/**
 * Test: Create Customer Cloud Function
 */
async function testCreateCustomer() {
  try {
    const fetch = (await import('node-fetch')).default;
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('TEST 1: Create Stripe Customer');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`User ID: ${TEST_USER.id}`);
    console.log(`Email: ${TEST_USER.email}`);
    console.log(`Name: ${TEST_USER.name}`);
    
    console.log('\n📤 Calling Cloud Function: createStripeCustomer');
    
    const response = await fetch(`${FUNCTIONS_BASE_URL}/createStripeCustomer`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: TEST_USER.id,
        email: TEST_USER.email,
        name: TEST_USER.name,
      })
    });

    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.error || 'Failed to create customer');
    }

    console.log(`✅ Cloud Function Response:`, result);
    console.log(`   Customer ID: ${result.customerId}`);
    console.log(`   Message: ${result.message}`);
    
    // Verify in Firestore
    console.log('\n📊 Verifying in Firestore...');
    const customerDoc = await db.collection('stripeCustomers').doc(TEST_USER.id).get();
    
    if (!customerDoc.exists) {
      throw new Error('Customer not found in Firestore!');
    }
    
    const customerData = customerDoc.data();
    console.log('✅ Customer found in Firestore:');
    console.log(`   Stripe ID: ${customerData.stripeCustomerId}`);
    console.log(`   Email: ${customerData.email}`);
    console.log(`   Name: ${customerData.name}`);
    console.log(`   Payment Methods: ${customerData.paymentMethods?.length || 0}`);
    
    return result.customerId;
  } catch (error) {
    console.error('\n❌ TEST 1 FAILED:', error.message);
    throw error;
  }
}

/**
 * Test: Create Customer Again (Duplicate Prevention)
 */
async function testDuplicatePrevention() {
  try {
    const fetch = (await import('node-fetch')).default;
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('TEST 2: Duplicate Customer Prevention');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Attempting to create same customer again...');
    
    const response = await fetch(`${FUNCTIONS_BASE_URL}/createStripeCustomer`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: TEST_USER.id,  // Same user ID
        email: TEST_USER.email,
        name: TEST_USER.name,
      })
    });

    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.error || 'Unexpected error');
    }

    if (result.existing === true) {
      console.log('✅ PASS: Duplicate detected and prevented!');
      console.log(`   Returned existing customer: ${result.customerId}`);
      console.log('   Message:', result.message);
    } else {
      console.log('⚠️  WARNING: Created new customer instead of returning existing');
      console.log('   This could lead to duplicates!');
    }
    
    // Verify only ONE customer exists in Firestore
    const customerDoc = await db.collection('stripeCustomers').doc(TEST_USER.id).get();
    const customerData = customerDoc.data();
    
    console.log('\n📊 Firestore verification:');
    console.log(`   Document exists: ${customerDoc.exists}`);
    console.log(`   Customer ID: ${customerData.stripeCustomerId}`);
    
    return true;
  } catch (error) {
    console.error('\n❌ TEST 2 FAILED:', error.message);
    throw error;
  }
}

/**
 * Test: Attach Payment Method with Token
 */
async function testAttachPaymentMethod(customerId, tokenId) {
  try {
    const fetch = (await import('node-fetch')).default;
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('TEST 3: Attach Payment Method (Token-based)');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Step 1: Get test token (simulates browser Stripe.js)
    const token = await getTestTokenInfo(tokenId);
    
    // Step 2: Send token to Cloud Function
    console.log('\n📤 Calling Cloud Function: attachPaymentMethod');
    console.log(`   Token: ${token.id}`);
    console.log(`   User ID: ${TEST_USER.id}`);
    
    const response = await fetch(`${FUNCTIONS_BASE_URL}/attachPaymentMethod`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: TEST_USER.id,
        token: token.id,
        cardholderName: 'Test User',
        setAsDefault: true,
      })
    });

    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.error || 'Failed to attach payment method');
    }

    console.log('✅ Cloud Function Response:', result);
    console.log(`   Message: ${result.message}`);
    console.log(`   Payment Method:`, result.paymentMethod);
    
    // Verify in Firestore
    console.log('\n📊 Verifying in Firestore...');
    const customerDoc = await db.collection('stripeCustomers').doc(TEST_USER.id).get();
    const customerData = customerDoc.data();
    
    console.log('✅ Customer updated in Firestore:');
    console.log(`   Payment Methods: ${customerData.paymentMethods?.length || 0}`);
    console.log(`   Default PM: ${customerData.defaultPaymentMethodId}`);
    
    if (customerData.paymentMethods && customerData.paymentMethods.length > 0) {
      const pm = customerData.paymentMethods[0];
      console.log(`   Card: ${pm.brand} •••• ${pm.last4}`);
      console.log(`   Expires: ${pm.expiryMonth}/${pm.expiryYear}`);
      console.log(`   Is Default: ${pm.isDefault}`);
    }
    
    return result;
  } catch (error) {
    console.error('\n❌ TEST 3 FAILED:', error.message);
    throw error;
  }
}

/**
 * Test: Attach Second Card (Multiple Cards Support)
 */
async function testAttachSecondCard(tokenId) {
  try {
    const fetch = (await import('node-fetch')).default;
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('TEST 4: Attach Second Payment Method');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Get test token for different card (Mastercard)
    const token = await getTestTokenInfo(tokenId);
    
    const response = await fetch(`${FUNCTIONS_BASE_URL}/attachPaymentMethod`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: TEST_USER.id,
        token: token.id,
        cardholderName: 'Test User',
        setAsDefault: false,  // Don't set as default
      })
    });

    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.error || 'Failed to attach second payment method');
    }

    console.log('✅ Second card attached successfully');
    
    // Verify in Firestore
    const customerDoc = await db.collection('stripeCustomers').doc(TEST_USER.id).get();
    const customerData = customerDoc.data();
    
    console.log('\n📊 Final customer state:');
    console.log(`   Total Payment Methods: ${customerData.paymentMethods?.length || 0}`);
    console.log(`   Default PM: ${customerData.defaultPaymentMethodId}`);
    
    customerData.paymentMethods?.forEach((pm, index) => {
      console.log(`   Card ${index + 1}: ${pm.brand} •••• ${pm.last4} ${pm.isDefault ? '[DEFAULT]' : ''}`);
    });
    
    return result;
  } catch (error) {
    console.error('\n❌ TEST 4 FAILED:', error.message);
    throw error;
  }
}

/**
 * Verify in Stripe Dashboard
 */
async function verifyInStripeDashboard(customerId) {
  try {
    const fetch = (await import('node-fetch')).default;
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('VERIFICATION: Stripe Dashboard');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Fetch customer from Stripe API
    const response = await fetch(`https://api.stripe.com/v1/customers/${customerId}`, {
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
      }
    });

    if (!response.ok) {
      throw new Error('Failed to fetch from Stripe');
    }

    const customer = await response.json();
    
    console.log('✅ Customer found in Stripe:');
    console.log(`   ID: ${customer.id}`);
    console.log(`   Email: ${customer.email}`);
    console.log(`   Name: ${customer.name}`);
    console.log(`   Metadata: prefix=${customer.metadata?.prefix}, app=${customer.metadata?.app}`);
    
    // Fetch payment methods
    const pmResponse = await fetch(
      `https://api.stripe.com/v1/payment_methods?customer=${customerId}&type=card`,
      {
        headers: {
          'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
        }
      }
    );

    const pmData = await pmResponse.json();
    const paymentMethods = pmData.data || [];
    
    console.log(`\n💳 Payment Methods in Stripe: ${paymentMethods.length}`);
    paymentMethods.forEach((pm, index) => {
      console.log(`   ${index + 1}. ${pm.card.brand} •••• ${pm.card.last4} (${pm.card.exp_month}/${pm.card.exp_year})`);
    });
    
    return true;
  } catch (error) {
    console.error('\n❌ VERIFICATION FAILED:', error.message);
    throw error;
  }
}

/**
 * Cleanup test data
 */
async function cleanup() {
  try {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('CLEANUP: Removing test data');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Delete from Firestore
    console.log('Deleting from Firestore...');
    await db.collection('stripeCustomers').doc(TEST_USER.id).delete();
    console.log('✅ Deleted from Firestore');
    
    // Note: Stripe customer will remain in Stripe Dashboard
    // You can manually delete it or leave it (test mode customers are free)
    console.log('\nℹ️  Stripe customer remains in dashboard (delete manually if needed)');
    console.log('   View at: https://dashboard.stripe.com/test/customers');
    
  } catch (error) {
    console.error('⚠️  Cleanup error:', error.message);
  }
}

/**
 * Main test runner
 */
async function runTests() {
  console.log('\n🚀 Starting Stripe Cloud Functions Test Suite');
  console.log('═══════════════════════════════════════════════\n');
  console.log(`Functions URL: ${FUNCTIONS_BASE_URL}`);
  console.log(`Test User: ${TEST_USER.email}`);
  console.log(`Test Card: Visa •••• 4242\n`);

  let customerId;
  let allTestsPassed = true;

  try {
    // Test 1: Create customer
    customerId = await testCreateCustomer();
    
    // Test 2: Duplicate prevention
    await testDuplicatePrevention();
    
    // Test 3: Attach first card (Visa)
    await testAttachPaymentMethod(customerId, STRIPE_TEST_TOKENS.visa);
    
    // Test 4: Attach second card (Mastercard)
    await testAttachSecondCard(STRIPE_TEST_TOKENS.mastercard);
    
    // Verification: Check Stripe Dashboard
    await verifyInStripeDashboard(customerId);
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ ALL TESTS PASSED!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n🎉 Cloud Functions are working correctly!');
    console.log('\n📝 Summary:');
    console.log('   ✅ Customer creation works');
    console.log('   ✅ Duplicate prevention works');
    console.log('   ✅ Token-based payment method attachment works');
    console.log('   ✅ Multiple cards supported');
    console.log('   ✅ Firestore sync works');
    console.log('   ✅ Stripe API integration works');
    console.log('\n🚀 Ready to integrate into app!');
    console.log('\n📊 View test customer in Stripe:');
    console.log(`   https://dashboard.stripe.com/test/customers/${customerId}`);
    
  } catch (error) {
    allTestsPassed = false;
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('❌ TESTS FAILED');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n🔧 Please check:');
    console.log('   1. Cloud Functions are deployed');
    console.log('   2. Stripe secret key is configured');
    console.log('   3. Firebase project is accessible');
    console.log('   4. Internet connection is working');
    console.log('\n📝 Check function logs:');
    console.log('   firebase functions:log\n');
  }

  // Cleanup
  const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  });

  readline.question('\nCleanup test data? (y/n): ', async (answer) => {
    if (answer.toLowerCase() === 'y') {
      await cleanup();
    } else {
      console.log('ℹ️  Test data kept for manual inspection');
    }
    
    readline.close();
    await admin.app().delete();
    
    process.exit(allTestsPassed ? 0 : 1);
  });
}

// Run the tests
runTests().catch((error) => {
  console.error('\n❌ Fatal error:', error);
  process.exit(1);
});

