const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Valid vehicle types according to FirebaseConstants
const VALID_VEHICLE_TYPES = ['Sedan', 'SUV', 'Luxury SUV'];

/**
 * Validate and fix driver vehicle types
 */
async function validateDrivers() {
  console.log('\n🚗 === VALIDATING DRIVERS ===\n');
  
  const driversSnapshot = await db.collection('drivers').get();
  
  if (driversSnapshot.empty) {
    console.log('⚠️  No drivers found in Firestore');
    return;
  }
  
  let validCount = 0;
  let invalidCount = 0;
  let fixedCount = 0;
  
  for (const doc of driversSnapshot.docs) {
    const driverId = doc.id;
    const driverData = doc.data();
    const carType = driverData.carType;
    
    // Get user email for better logging
    const userDoc = await db.collection('users').doc(driverId).get();
    const email = userDoc.exists ? userDoc.data().email : 'unknown';
    
    console.log(`\nDriver: ${email} (${driverId})`);
    console.log(`  Current carType: "${carType}"`);
    console.log(`  Car Name: ${driverData.carName || 'N/A'}`);
    console.log(`  Status: ${driverData.driverStatus || 'N/A'}`);
    
    if (!carType) {
      console.log(`  ❌ carType is missing!`);
      invalidCount++;
      
      // Default to 'Sedan' if missing
      console.log(`  🔧 Setting carType to "Sedan"`);
      await doc.ref.update({ carType: 'Sedan' });
      fixedCount++;
      
    } else if (!VALID_VEHICLE_TYPES.includes(carType)) {
      console.log(`  ❌ Invalid carType: "${carType}"`);
      console.log(`  Valid types: ${VALID_VEHICLE_TYPES.join(', ')}`);
      invalidCount++;
      
      // Try to fix common variations
      let fixedType = null;
      if (carType.toLowerCase() === 'car' || carType.toLowerCase() === 'sedan') {
        fixedType = 'Sedan';
      } else if (carType.toLowerCase() === 'suv' && !carType.toLowerCase().includes('luxury')) {
        fixedType = 'SUV';
      } else if (carType.toLowerCase().includes('luxury') && carType.toLowerCase().includes('suv')) {
        fixedType = 'Luxury SUV';
      } else if (carType.toLowerCase().includes('motor') || carType.toLowerCase().includes('bike')) {
        fixedType = 'Sedan'; // Convert old motorcycles to Sedan
      } else {
        // Default to Sedan if we can't determine
        fixedType = 'Sedan';
      }
      
      console.log(`  🔧 Fixing carType to "${fixedType}"`);
      await doc.ref.update({ carType: fixedType });
      fixedCount++;
      
    } else {
      console.log(`  ✅ Valid carType`);
      validCount++;
    }
  }
  
  console.log('\n📊 Driver Validation Summary:');
  console.log(`  ✅ Valid: ${validCount}`);
  console.log(`  ❌ Invalid: ${invalidCount}`);
  console.log(`  🔧 Fixed: ${fixedCount}`);
}

/**
 * Validate and fix ride request vehicle types
 */
async function validateRideRequests() {
  console.log('\n\n🎫 === VALIDATING RIDE REQUESTS ===\n');
  
  const ridesSnapshot = await db.collection('rideRequests').get();
  
  if (ridesSnapshot.empty) {
    console.log('ℹ️  No ride requests found in Firestore');
    return;
  }
  
  let validCount = 0;
  let invalidCount = 0;
  let fixedCount = 0;
  
  for (const doc of ridesSnapshot.docs) {
    const rideId = doc.id;
    const rideData = doc.data();
    const vehicleType = rideData.vehicleType;
    const status = rideData.status;
    
    console.log(`\nRide: ${rideId.substring(0, 8)}...`);
    console.log(`  Status: ${status}`);
    console.log(`  Current vehicleType: "${vehicleType}"`);
    console.log(`  User: ${rideData.userEmail || 'N/A'}`);
    console.log(`  Driver: ${rideData.driverEmail || 'Not assigned'}`);
    
    if (!vehicleType) {
      console.log(`  ❌ vehicleType is missing!`);
      invalidCount++;
      
      // Default to 'Sedan' if missing
      console.log(`  🔧 Setting vehicleType to "Sedan"`);
      await doc.ref.update({ vehicleType: 'Sedan' });
      fixedCount++;
      
    } else if (!VALID_VEHICLE_TYPES.includes(vehicleType)) {
      console.log(`  ❌ Invalid vehicleType: "${vehicleType}"`);
      console.log(`  Valid types: ${VALID_VEHICLE_TYPES.join(', ')}`);
      invalidCount++;
      
      // Try to fix common variations
      let fixedType = null;
      if (vehicleType.toLowerCase() === 'car' || vehicleType.toLowerCase() === 'sedan') {
        fixedType = 'Sedan';
      } else if (vehicleType.toLowerCase() === 'suv' && !vehicleType.toLowerCase().includes('luxury')) {
        fixedType = 'SUV';
      } else if (vehicleType.toLowerCase().includes('luxury') && vehicleType.toLowerCase().includes('suv')) {
        fixedType = 'Luxury SUV';
      } else if (vehicleType.toLowerCase().includes('motor') || vehicleType.toLowerCase().includes('bike')) {
        fixedType = 'Sedan'; // Convert old motorcycles to Sedan
      } else {
        // Default to Sedan if we can't determine
        fixedType = 'Sedan';
      }
      
      console.log(`  🔧 Fixing vehicleType to "${fixedType}"`);
      await doc.ref.update({ vehicleType: fixedType });
      fixedCount++;
      
    } else {
      console.log(`  ✅ Valid vehicleType`);
      validCount++;
    }
  }
  
  console.log('\n📊 Ride Request Validation Summary:');
  console.log(`  ✅ Valid: ${validCount}`);
  console.log(`  ❌ Invalid: ${invalidCount}`);
  console.log(`  🔧 Fixed: ${fixedCount}`);
}

/**
 * Check specific test driver
 */
async function checkTestDriver(email = 'driver@bt.com') {
  console.log('\n\n🔍 === CHECKING TEST DRIVER ===\n');
  
  // Find user by email
  const usersSnapshot = await db.collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();
  
  if (usersSnapshot.empty) {
    console.log(`❌ User not found with email: ${email}`);
    console.log('Available users:');
    const allUsers = await db.collection('users').get();
    allUsers.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${data.email} (${data.userType})`);
    });
    return;
  }
  
  const userId = usersSnapshot.docs[0].id;
  const userData = usersSnapshot.docs[0].data();
  
  console.log(`✅ Found user: ${email}`);
  console.log(`  User ID: ${userId}`);
  console.log(`  User Type: ${userData.userType}`);
  console.log(`  Name: ${userData.name}`);
  
  if (userData.userType !== 'driver') {
    console.log(`\n⚠️  WARNING: User is not a driver! User type is: ${userData.userType}`);
    return;
  }
  
  // Get driver data
  const driverDoc = await db.collection('drivers').doc(userId).get();
  
  if (!driverDoc.exists) {
    console.log('\n❌ Driver document not found!');
    console.log('Creating driver document with default values...');
    
    await db.collection('drivers').doc(userId).set({
      carName: '',
      carPlateNum: '',
      carType: 'Sedan',
      rate: 3.0,
      driverStatus: 'Offline',
      rating: 5.0,
      totalRides: 0,
      earnings: 0.0,
      licenseNumber: '',
      vehicleRegistration: '',
      isVerified: false
    });
    
    console.log('✅ Created driver document with carType: "Sedan"');
    return;
  }
  
  const driverData = driverDoc.data();
  
  console.log('\n📋 Driver Details:');
  console.log(`  Car Name: ${driverData.carName || 'Not set'}`);
  console.log(`  Car Plate: ${driverData.carPlateNum || 'Not set'}`);
  console.log(`  Car Type: ${driverData.carType || 'Not set'}`);
  console.log(`  Status: ${driverData.driverStatus || 'Not set'}`);
  console.log(`  Rating: ${driverData.rating || 0}`);
  console.log(`  Total Rides: ${driverData.totalRides || 0}`);
  console.log(`  Earnings: $${driverData.earnings || 0}`);
  
  // Validate and fix if needed
  if (!driverData.carType || !VALID_VEHICLE_TYPES.includes(driverData.carType)) {
    console.log(`\n⚠️  Invalid or missing carType: "${driverData.carType}"`);
    console.log(`Valid types: ${VALID_VEHICLE_TYPES.join(', ')}`);
    console.log('🔧 Setting to "Sedan"');
    await driverDoc.ref.update({ carType: 'Sedan' });
    console.log('✅ Fixed!');
  } else {
    console.log(`\n✅ Car type is valid: ${driverData.carType}`);
  }
  
  // Check if driver has rides
  console.log('\n📊 Checking ride assignments...');
  const assignedRides = await db.collection('rideRequests')
    .where('driverId', '==', userId)
    .get();
  
  console.log(`  Total rides assigned: ${assignedRides.size}`);
  
  if (assignedRides.size > 0) {
    const statuses = {};
    assignedRides.forEach(doc => {
      const status = doc.data().status;
      statuses[status] = (statuses[status] || 0) + 1;
    });
    console.log('  By status:');
    Object.entries(statuses).forEach(([status, count]) => {
      console.log(`    - ${status}: ${count}`);
    });
  }
}

/**
 * Show matching statistics
 */
async function showMatchingStats() {
  console.log('\n\n📊 === VEHICLE TYPE MATCHING ANALYSIS ===\n');
  
  // Get all drivers grouped by vehicle type
  const driversSnapshot = await db.collection('drivers').get();
  const driversByType = {};
  
  for (const doc of driversSnapshot.docs) {
    const carType = doc.data().carType || 'Not Set';
    if (!driversByType[carType]) {
      driversByType[carType] = [];
    }
    driversByType[carType].push(doc.id);
  }
  
  console.log('Drivers by Vehicle Type:');
  Object.entries(driversByType).forEach(([type, drivers]) => {
    const valid = VALID_VEHICLE_TYPES.includes(type) ? '✅' : '❌';
    console.log(`  ${valid} ${type}: ${drivers.length} driver(s)`);
  });
  
  // Get all pending rides grouped by vehicle type
  const ridesSnapshot = await db.collection('rideRequests')
    .where('status', '==', 'pending')
    .get();
  
  const ridesByType = {};
  
  ridesSnapshot.forEach(doc => {
    const vehicleType = doc.data().vehicleType || 'Not Set';
    if (!ridesByType[vehicleType]) {
      ridesByType[vehicleType] = [];
    }
    ridesByType[vehicleType].push(doc.id);
  });
  
  console.log('\nPending Rides by Vehicle Type:');
  if (Object.keys(ridesByType).length === 0) {
    console.log('  (No pending rides)');
  } else {
    Object.entries(ridesByType).forEach(([type, rides]) => {
      const valid = VALID_VEHICLE_TYPES.includes(type) ? '✅' : '❌';
      const matchingDrivers = driversByType[type] || [];
      console.log(`  ${valid} ${type}: ${rides.length} ride(s) → ${matchingDrivers.length} matching driver(s)`);
    });
  }
}

/**
 * Main execution
 */
async function main() {
  console.log('🚀 Starting Firestore Vehicle Type Validation...\n');
  console.log(`Valid Vehicle Types: ${VALID_VEHICLE_TYPES.join(', ')}\n`);
  console.log('=' .repeat(60));
  
  try {
    // Check specific test driver first
    await checkTestDriver('driver@bt.com');
    
    // Validate all drivers
    await validateDrivers();
    
    // Validate all ride requests
    await validateRideRequests();
    
    // Show matching statistics
    await showMatchingStats();
    
    console.log('\n' + '='.repeat(60));
    console.log('\n✅ Validation complete!');
    console.log('\n💡 Next steps:');
    console.log('   1. Restart your Flutter app');
    console.log('   2. Log in as driver@bt.com');
    console.log('   3. Go online to see pending rides matching your vehicle type');
    console.log('   4. Create a test ride from a user account with matching vehicle type\n');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    // Terminate the app
    process.exit(0);
  }
}

// Run the script
main();

