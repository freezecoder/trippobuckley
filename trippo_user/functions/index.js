/**
 * Firebase Cloud Functions for BTrips
 * 
 * - Stripe Payment Processing
 * - Google Places API Proxy (for web CORS)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const placesProxy = require('./placesProxy');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Stripe with secret key from environment variable
// Set this with: firebase functions:config:set stripe.secret_key="sk_test_..."
const stripeSecretKey = functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY;

if (!stripeSecretKey) {
  console.error('⚠️  WARNING: Stripe secret key not configured!');
  console.error('Set it with: firebase functions:config:set stripe.secret_key="sk_test_..."');
}

const stripe = require('stripe')(stripeSecretKey);

/**
 * Create Stripe Customer
 * 
 * Called when a user tries to add a payment method for the first time.
 * Creates a Stripe customer and saves the customer ID to Firestore.
 * 
 * Request body:
 * {
 *   userId: string,
 *   email: string,
 *   name: string,
 *   billingAddress?: {
 *     line1: string,
 *     city: string,
 *     state: string,
 *     postalCode: string,
 *     country: string
 *   }
 * }
 * 
 * Response:
 * {
 *   success: true,
 *   customerId: "cus_...",
 *   message: "Customer created successfully"
 * }
 */
exports.createStripeCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      // Only allow POST requests
      if (request.method !== 'POST') {
        response.status(405).json({
          success: false,
          error: 'Method not allowed. Use POST.'
        });
        return;
      }

      const { userId, email, name, billingAddress } = request.body;

      // Validate required fields
      if (!userId || !email || !name) {
        response.status(400).json({
          success: false,
          error: 'Missing required fields: userId, email, name'
        });
        return;
      }

      // DUPLICATE PREVENTION - Check multiple ways
      
      // 1. Check Firestore first (fastest)
      const existingCustomerDoc = await admin.firestore()
        .collection('stripeCustomers')
        .doc(userId)
        .get();

      if (existingCustomerDoc.exists) {
        const existingData = existingCustomerDoc.data();
        console.log(`ℹ️  Customer already exists in Firestore: ${existingData.stripeCustomerId}`);
        
        response.status(200).json({
          success: true,
          customerId: existingData.stripeCustomerId,
          message: 'Customer already exists',
          existing: true
        });
        return;
      }

      // 2. Check Stripe for existing customer with this email (extra safety)
      try {
        const existingCustomers = await stripe.customers.list({
          email: email,
          limit: 1
        });

        if (existingCustomers.data.length > 0) {
          const existingCustomer = existingCustomers.data[0];
          
          // Check if this customer belongs to our app (has our metadata)
          if (existingCustomer.metadata?.prefix === 'BTRP' || 
              existingCustomer.metadata?.app === 'BTrips') {
            
            console.log(`ℹ️  Found existing customer in Stripe: ${existingCustomer.id}`);
            console.log('   Syncing to Firestore...');
            
            // Sync to Firestore
            const firestoreData = {
              userId: userId,
              stripeCustomerId: existingCustomer.id,
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
                createdVia: 'cloud_function_sync',
                note: 'Found existing customer in Stripe'
              }
            };

            await admin.firestore()
              .collection('stripeCustomers')
              .doc(userId)
              .set(firestoreData);
            
            response.status(200).json({
              success: true,
              customerId: existingCustomer.id,
              message: 'Existing Stripe customer linked to user',
              existing: true,
              synced: true
            });
            return;
          }
        }
      } catch (stripeCheckError) {
        // If Stripe check fails, continue with creation
        console.log('⚠️  Could not check Stripe for existing customer:', stripeCheckError.message);
      }

      // Create Stripe customer
      const customerData = {
        email: email,
        name: name,
        metadata: {
          userId: userId,
          prefix: 'BTRP',
          app: 'BTrips',
          createdVia: 'cloud_function'
        }
      };

      // Add billing address if provided
      if (billingAddress) {
        customerData.address = {
          line1: billingAddress.line1,
          city: billingAddress.city,
          state: billingAddress.state,
          postal_code: billingAddress.postalCode,
          country: billingAddress.country
        };
      }

      const customer = await stripe.customers.create(customerData);

      // Save to Firestore
      const firestoreData = {
        userId: userId,
        stripeCustomerId: customer.id,
        email: email,
        name: name,
        billingAddress: billingAddress || null,
        paymentMethods: [],
        defaultPaymentMethodId: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        metadata: {
          prefix: 'BTRP',
          createdVia: 'cloud_function',
          stripeCreatedAt: customer.created
        }
      };

      await admin.firestore()
        .collection('stripeCustomers')
        .doc(userId)
        .set(firestoreData);

      console.log(`✅ Created Stripe customer ${customer.id} for user ${userId}`);

      response.status(200).json({
        success: true,
        customerId: customer.id,
        message: 'Customer created successfully'
      });

    } catch (error) {
      console.error('❌ Error creating Stripe customer:', error);
      
      response.status(500).json({
        success: false,
        error: error.message || 'Failed to create Stripe customer'
      });
    }
  });
});

/**
 * Create and Attach Payment Method to Customer
 * 
 * This function can work with either:
 * 1. A Stripe token (from Stripe.js createToken) - RECOMMENDED for web
 * 2. A payment method ID (already created) - for mobile
 * 
 * Request body:
 * {
 *   userId: string,
 *   token?: string,              // Stripe token (tok_xxx) from browser
 *   paymentMethodId?: string,    // OR existing payment method ID
 *   cardholderName?: string,     // For token approach
 *   setAsDefault: boolean
 * }
 */
exports.attachPaymentMethod = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        response.status(405).json({
          success: false,
          error: 'Method not allowed. Use POST.'
        });
        return;
      }

      const { userId, token, paymentMethodId, cardholderName, setAsDefault } = request.body;

      if (!userId || (!token && !paymentMethodId)) {
        response.status(400).json({
          success: false,
          error: 'Missing required fields: userId and (token OR paymentMethodId)'
        });
        return;
      }

      // Get customer from Firestore
      const customerDoc = await admin.firestore()
        .collection('stripeCustomers')
        .doc(userId)
        .get();

      if (!customerDoc.exists) {
        response.status(404).json({
          success: false,
          error: 'Customer not found. Create customer first.'
        });
        return;
      }

      const customerData = customerDoc.data();
      const stripeCustomerId = customerData.stripeCustomerId;

      let finalPaymentMethodId;

      // If token provided, create payment method from token (Web approach)
      if (token) {
        console.log(`Creating payment method from token for customer ${stripeCustomerId}`);
        
        const paymentMethod = await stripe.paymentMethods.create({
          type: 'card',
          card: {
            token: token,
          },
          billing_details: {
            name: cardholderName || customerData.name,
          },
        });

        finalPaymentMethodId = paymentMethod.id;
        console.log(`✅ Created payment method ${finalPaymentMethodId} from token`);
      } else {
        // Payment method already exists (Mobile approach)
        finalPaymentMethodId = paymentMethodId;
        console.log(`Using existing payment method ${finalPaymentMethodId}`);
      }

      // Attach payment method to customer in Stripe
      await stripe.paymentMethods.attach(finalPaymentMethodId, {
        customer: stripeCustomerId,
      });

      // Get payment method details
      const paymentMethod = await stripe.paymentMethods.retrieve(finalPaymentMethodId);

      // Update in Firestore
      // Note: Cannot use FieldValue.serverTimestamp() inside arrays
      // Use Date.now() instead
      const paymentMethodData = {
        id: finalPaymentMethodId,
        type: paymentMethod.type,
        last4: paymentMethod.card.last4,
        brand: paymentMethod.card.brand,
        expiryMonth: paymentMethod.card.exp_month.toString(),
        expiryYear: paymentMethod.card.exp_year.toString().slice(-2),
        cardholderName: paymentMethod.billing_details?.name || '',
        isDefault: setAsDefault || false,
        addedAt: Date.now(), // Use timestamp instead of FieldValue
        isActive: true,
        stripePaymentMethodId: finalPaymentMethodId
      };

      const currentPaymentMethods = customerData.paymentMethods || [];
      
      // If setting as default, unmark others
      if (setAsDefault) {
        currentPaymentMethods.forEach(pm => pm.isDefault = false);
      }
      
      currentPaymentMethods.push(paymentMethodData);

      await admin.firestore()
        .collection('stripeCustomers')
        .doc(userId)
        .update({
          paymentMethods: currentPaymentMethods,
          defaultPaymentMethodId: setAsDefault ? finalPaymentMethodId : customerData.defaultPaymentMethodId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

      console.log(`✅ Attached payment method ${finalPaymentMethodId} to customer ${stripeCustomerId}`);

      response.status(200).json({
        success: true,
        message: 'Payment method attached successfully',
        paymentMethod: paymentMethodData
      });

    } catch (error) {
      console.error('❌ Error attaching payment method:', error);
      
      response.status(500).json({
        success: false,
        error: error.message || 'Failed to attach payment method'
      });
    }
  });
});

/**
 * Detach Payment Method from Customer
 * 
 * Removes a payment method from a Stripe customer.
 * 
 * Request body:
 * {
 *   userId: string,
 *   paymentMethodId: string
 * }
 */
exports.detachPaymentMethod = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        response.status(405).json({
          success: false,
          error: 'Method not allowed. Use POST.'
        });
        return;
      }

      const { userId, paymentMethodId } = request.body;

      if (!userId || !paymentMethodId) {
        response.status(400).json({
          success: false,
          error: 'Missing required fields: userId, paymentMethodId'
        });
        return;
      }

      // Detach from Stripe
      await stripe.paymentMethods.detach(paymentMethodId);

      // Update Firestore
      const customerDoc = await admin.firestore()
        .collection('stripeCustomers')
        .doc(userId)
        .get();

      if (customerDoc.exists) {
        const customerData = customerDoc.data();
        const updatedMethods = (customerData.paymentMethods || [])
          .filter(pm => pm.id !== paymentMethodId);

        await admin.firestore()
          .collection('stripeCustomers')
          .doc(userId)
          .update({
            paymentMethods: updatedMethods,
            defaultPaymentMethodId: customerData.defaultPaymentMethodId === paymentMethodId 
              ? null 
              : customerData.defaultPaymentMethodId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
      }

      console.log(`✅ Detached payment method ${paymentMethodId}`);

      response.status(200).json({
        success: true,
        message: 'Payment method removed successfully'
      });

    } catch (error) {
      console.error('❌ Error detaching payment method:', error);
      
      response.status(500).json({
        success: false,
        error: error.message || 'Failed to remove payment method'
      });
    }
  });
});

// ============================================================================
// GOOGLE PLACES API PROXY (for web to bypass CORS)
// ============================================================================

/**
 * Places Autocomplete - Search for places
 * Called from Flutter web app to bypass CORS restrictions
 */
exports.placesAutocomplete = placesProxy.placesAutocomplete;

/**
 * Place Details - Get coordinates for a place
 * Called from Flutter web app to bypass CORS restrictions
 */
exports.placeDetails = placesProxy.placeDetails;

