#!/usr/bin/env node

/**
 * Script to simulate a ride request for testing driver features
 * Creates a pending ride request in Firestore that drivers can see and accept
 * 
 * Usage:
 *   node scripts/simulate_ride_request.js           (immediate ride)
 *   node scripts/simulate_ride_request.js now       (immediate ride)
 *   node scripts/simulate_ride_request.js 30m       (scheduled in 30 minutes)
 *   node scripts/simulate_ride_request.js 1h        (scheduled in 1 hour)
 *   node scripts/simulate_ride_request.js 2h        (scheduled in 2 hours)
 *   node scripts/simulate_ride_request.js tomorrow  (scheduled tomorrow)
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

// Parse scheduling argument
function parseScheduleTime(arg) {
  if (!arg || arg === 'now') {
    return null; // Immediate ride
  }

  const now = new Date();
  
  if (arg === 'tomorrow') {
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(9, 0, 0, 0); // 9 AM tomorrow
    return tomorrow;
  }

  // Parse time format like "30m", "1h", "2h"
  const match = arg.match(/^(\d+)(m|h)$/);
  if (match) {
    const value = parseInt(match[1]);
    const unit = match[2];
    
    const scheduled = new Date(now);
    if (unit === 'm') {
      scheduled.setMinutes(scheduled.getMinutes() + value);
    } else if (unit === 'h') {
      scheduled.setHours(scheduled.getHours() + value);
    }
    return scheduled;
  }

  console.log('⚠️  Invalid schedule format. Using "now".');
  return null;
}

// Sample pickup/dropoff locations (you can customize these)
const sampleLocations = [
  {
    pickup: {
      lat: 40.7128,
      lng: -74.0060,
      address: 'Times Square, New York, NY 10036'
    },
    dropoff: {
      lat: 40.7580,
      lng: -73.9855,
      address: 'Central Park, New York, NY 10024'
    },
    fare: 25.50,
    distance: 2.5,
    duration: 15
  },
  {
    pickup: {
      lat: 40.7614,
      lng: -73.9776,
      address: 'Rockefeller Center, New York, NY 10020'
    },
    dropoff: {
      lat: 40.7489,
      lng: -73.9680,
      address: 'Grand Central Terminal, New York, NY 10017'
    },
    fare: 18.75,
    distance: 1.8,
    duration: 10
  },
  {
    pickup: {
      lat: 40.7589,
      lng: -73.9851,
      address: 'Columbus Circle, New York, NY 10019'
    },
    dropoff: {
      lat: 40.7484,
      lng: -73.9857,
      address: 'Empire State Building, New York, NY 10001'
    },
    fare: 32.00,
    distance: 3.2,
    duration: 18
  },
];

async function simulateRideRequest() {
  const scheduleArg = process.argv[2];
  const scheduledTime = parseScheduleTime(scheduleArg);
  const isScheduled = scheduledTime !== null;

  console.log('🚕 Simulating ride request for testing...\n');

  try {
    // Get a random location pair
    const location = sampleLocations[Math.floor(Math.random() * sampleLocations.length)];

    // Get the test user (your account)
    const testUserEmail = 'zayed.albertyn@gmail.com';
    const testUserAuth = await admin.auth().getUserByEmail(testUserEmail);
    const testUserId = testUserAuth.uid;

    console.log('📋 Creating ride request...');
    console.log(`   Type: ${isScheduled ? '📅 SCHEDULED' : '⚡ IMMEDIATE'}`);
    if (isScheduled) {
      console.log(`   Scheduled For: ${scheduledTime.toLocaleString()}`);
    }
    console.log(`   From: ${location.pickup.address}`);
    console.log(`   To: ${location.dropoff.address}`);
    console.log(`   Fare: $${location.fare.toFixed(2)}`);
    console.log(`   Distance: ${location.distance} km`);
    console.log(`   Duration: ${location.duration} min\n`);

    // Create the ride request
    const rideData = {
      // User info
      userId: testUserId,
      userEmail: testUserEmail,
      
      // Driver info (will be assigned when accepted)
      driverId: null,
      driverEmail: null,
      
      // Status
      status: 'pending',
      
      // Locations (using GeoPoint for proper Firestore format)
      pickupLocation: new admin.firestore.GeoPoint(
        location.pickup.lat,
        location.pickup.lng
      ),
      pickupAddress: location.pickup.address,
      
      dropoffLocation: new admin.firestore.GeoPoint(
        location.dropoff.lat,
        location.dropoff.lng
      ),
      dropoffAddress: location.dropoff.address,
      
      // Scheduling
      scheduledTime: isScheduled ? admin.firestore.Timestamp.fromDate(scheduledTime) : null,
      
      // Timestamps
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      acceptedAt: null,
      startedAt: null,
      completedAt: null,
      
      // Ride details
      vehicleType: 'Car',
      fare: location.fare,
      distance: location.distance,
      duration: location.duration,
      route: null,
    };

    // Add to Firestore
    const docRef = await db.collection('rideRequests').add(rideData);

    console.log('✅ Ride request created successfully!\n');
    console.log('═══════════════════════════════════════');
    console.log('📊 RIDE REQUEST DETAILS');
    console.log('═══════════════════════════════════════');
    console.log(`Ride ID:  ${docRef.id}`);
    console.log(`Type:     ${isScheduled ? '📅 SCHEDULED' : '⚡ NOW'}`);
    if (isScheduled) {
      console.log(`When:     ${scheduledTime.toLocaleString()}`);
    }
    console.log(`User:     ${testUserEmail}`);
    console.log(`Status:   pending`);
    console.log(`Pickup:   ${location.pickup.address}`);
    console.log(`Dropoff:  ${location.dropoff.address}`);
    console.log(`Fare:     $${location.fare.toFixed(2)}`);
    console.log(`Distance: ${location.distance} km`);
    console.log(`Duration: ${location.duration} min`);
    console.log('═══════════════════════════════════════\n');

    console.log('🧪 TESTING STEPS:');
    console.log('1. Open driver app (or refresh if already open)');
    console.log('2. Login as: driver@bt.com / Test123!');
    console.log('3. Go to Home tab');
    console.log('4. Tap "Go Online"');
    console.log('5. ✅ Card should appear at bottom of screen!');
    console.log('   OR');
    console.log('6. Go to Rides tab → Pending subtab');
    console.log('7. ✅ Should see the ride request in the list!\n');

    console.log('📱 DRIVER ACTIONS:');
    console.log('- Tap "Accept Ride" to accept');
    console.log('- Tap "Decline" to reject');
    console.log('- Check Active tab after accepting\n');

    console.log('🔍 FIREBASE CONSOLE:');
    console.log(`https://console.firebase.google.com/project/trippo-42089/firestore/data/~2FrideRequests~2F${docRef.id}\n`);

    console.log('💡 EXAMPLES:');
    console.log('   node scripts/simulate_ride_request.js       (immediate ride)');
    console.log('   node scripts/simulate_ride_request.js 30m   (in 30 minutes)');
    console.log('   node scripts/simulate_ride_request.js 1h    (in 1 hour)');
    console.log('   node scripts/simulate_ride_request.js 2h    (in 2 hours)');
    console.log('   node scripts/simulate_ride_request.js tomorrow (9 AM tomorrow)');

  } catch (error) {
    console.error('❌ Error creating ride request:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

simulateRideRequest();

