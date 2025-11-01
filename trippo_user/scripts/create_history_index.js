#!/usr/bin/env node

/**
 * Script to trigger Firestore index creation for rideHistory collection
 * Creates a sample completed ride to trigger the index creation
 * Run with: node scripts/create_history_index.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'trippo-42089'
  });
}

const db = admin.firestore();
const auth = admin.auth();

async function createHistoryIndex() {
  console.log('🔧 Creating sample ride history to trigger index...\n');

  try {
    // Get user and driver IDs
    const userAuth = await auth.getUserByEmail('zayed.albertyn@gmail.com');
    const driverAuth = await auth.getUserByEmail('driver@bt.com');
    
    const userId = userAuth.uid;
    const driverId = driverAuth.uid;

    console.log('📋 Creating sample completed ride in history...');

    // Create a sample completed ride in history
    const sampleRideId = 'sample_' + Date.now();
    const now = admin.firestore.Timestamp.now();

    const sampleRide = {
      userId: userId,
      userEmail: 'zayed.albertyn@gmail.com',
      driverId: driverId,
      driverEmail: 'driver@bt.com',
      status: 'completed',
      
      pickupLocation: new admin.firestore.GeoPoint(40.7128, -74.0060),
      pickupAddress: 'Sample Pickup Location, NY',
      dropoffLocation: new admin.firestore.GeoPoint(40.7580, -73.9855),
      dropoffAddress: 'Sample Dropoff Location, NY',
      
      scheduledTime: null,
      requestedAt: now,
      acceptedAt: now,
      startedAt: now,
      completedAt: now,
      
      vehicleType: 'Car',
      fare: 25.00,
      distance: 2.5,
      duration: 15,
      route: null,
      
      // Sample ratings
      driverRating: null,
      userRating: null,
    };

    await db.collection('rideHistory').doc(sampleRideId).set(sampleRide);
    console.log('✅ Sample ride created in rideHistory collection\n');

    // Now try the query that requires the index
    console.log('📋 Testing driver history query...');
    
    try {
      const result = await db.collection('rideHistory')
        .where('driverId', '==', driverId)
        .orderBy('completedAt', 'desc')
        .limit(10)
        .get();

      console.log('✅ Query successful! Index already exists or was auto-created.');
      console.log(`   Found ${result.size} ride(s) in history\n`);
      
      // Clean up the sample ride
      console.log('🧹 Cleaning up sample ride...');
      await db.collection('rideHistory').doc(sampleRideId).delete();
      console.log('✅ Sample ride deleted\n');
      
      console.log('🎉 Index is ready! You can now complete rides and they will appear in history.');

    } catch (error) {
      if (error.message.includes('index')) {
        console.log('⚠️  Index does not exist yet. Creating it now...\n');
        console.log('🔗 Click this link to create the index:');
        
        // Extract the URL from the error message
        const urlMatch = error.message.match(/(https:\/\/console\.firebase\.google\.com[^\s]+)/);
        if (urlMatch) {
          console.log('\n' + urlMatch[1] + '\n');
        }
        
        console.log('📝 OR create manually:');
        console.log('   1. Go to: https://console.firebase.google.com/project/trippo-42089/firestore/indexes');
        console.log('   2. Click "Add Index"');
        console.log('   3. Collection: rideHistory');
        console.log('   4. Add fields:');
        console.log('      - driverId (Ascending)');
        console.log('      - completedAt (Descending)');
        console.log('   5. Click "Create Index"');
        console.log('   6. Wait 2-5 minutes for index to build\n');
        
        console.log('💡 TIP: Keep the sample ride in the database to help index creation.');
        console.log('   (Not deleting it - you can remove it later from Firebase Console)\n');
        
        console.log('🎯 NEXT STEPS:');
        console.log('   1. Click the link above to create the index');
        console.log('   2. Wait for index to build (Firebase will email you)');
        console.log('   3. Test completing a ride in the app');
        console.log('   4. Ride should appear in History tab\n');
      } else {
        throw error;
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

createHistoryIndex();

