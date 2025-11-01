#!/usr/bin/env node

/**
 * Script to create a test driver account in Firebase
 * Creates Auth account + proper Firestore structure
 * Run with: node scripts/create_test_driver.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'trippo-42089'
});

const auth = admin.auth();
const db = admin.firestore();

async function createTestDriver() {
  const email = 'driver@bt.com';
  const password = 'Test123!'; // Default password
  const name = 'Test Driver';

  console.log('🚕 Creating test driver account...\n');

  try {
    // 1. Check if auth account already exists
    console.log('📋 Step 1: Checking if auth account exists...');
    let authUser;
    let userExists = false;
    
    try {
      authUser = await auth.getUserByEmail(email);
      console.log(`✅ Auth account already exists with UID: ${authUser.uid}`);
      userExists = true;
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log('ℹ️  Auth account not found, creating...');
        authUser = await auth.createUser({
          email: email,
          password: password,
          displayName: name,
          emailVerified: true
        });
        console.log(`✅ Created auth account with UID: ${authUser.uid}`);
        console.log(`   Email: ${email}`);
        console.log(`   Password: ${password}`);
      } else {
        throw error;
      }
    }

    const uid = authUser.uid;

    // 2. Get existing driver data from Drivers collection (if any)
    console.log('\n📋 Step 2: Looking for existing driver data...');
    const driversSnapshot = await db.collection('Drivers').limit(1).get();
    
    let driverData = {
      carName: 'Toyota Camry',
      carPlateNum: 'TEST-123',
      carType: 'Car',
      rate: 3.0,
      driverStatus: 'Offline',
      rating: 5.0,
      totalRides: 0,
      earnings: 0.0,
      isVerified: true
    };

    if (!driversSnapshot.empty) {
      const existingDriver = driversSnapshot.docs[0].data();
      console.log(`✅ Found existing driver data, using as template`);
      driverData = {
        carName: existingDriver.carName || driverData.carName,
        carPlateNum: existingDriver.carPlateNum || driverData.carPlateNum,
        carType: existingDriver.carType || driverData.carType,
        rate: existingDriver.rate || driverData.rate,
        driverStatus: 'Offline', // Always start offline
        rating: existingDriver.rating || driverData.rating,
        totalRides: existingDriver.totalRides || 0,
        earnings: existingDriver.earnings || 0.0,
        isVerified: true // Make test driver verified
      };
      console.log(`   Vehicle: ${driverData.carName} (${driverData.carPlateNum})`);
    } else {
      console.log('ℹ️  No existing drivers, using default data');
    }

    // 3. Create/update users collection
    console.log('\n📋 Step 3: Creating users document...');
    const userData = {
      email: email,
      name: name,
      userType: 'driver', // Important!
      phoneNumber: '+1-555-DRIVER',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      fcmToken: '',
      profileImageUrl: ''
    };

    await db.collection('users').doc(uid).set(userData, { merge: true });
    console.log(`✅ Created users/${uid}`);
    console.log(`   userType: driver`);

    // 4. Create drivers collection document
    console.log('\n📋 Step 4: Creating drivers document...');
    await db.collection('drivers').doc(uid).set(driverData, { merge: true });
    console.log(`✅ Created drivers/${uid}`);
    console.log(`   Vehicle: ${driverData.carName}`);
    console.log(`   Plate: ${driverData.carPlateNum}`);
    console.log(`   Type: ${driverData.carType}`);
    console.log(`   Status: ${driverData.driverStatus}`);

    // 5. Summary
    console.log('\n✅ SUCCESS! Test driver created!\n');
    console.log('═══════════════════════════════════════');
    console.log('🚕 TEST DRIVER LOGIN CREDENTIALS');
    console.log('═══════════════════════════════════════');
    console.log(`Email:    ${email}`);
    console.log(`Password: ${password}`);
    console.log(`UID:      ${uid}`);
    console.log(`Name:     ${name}`);
    console.log(`Vehicle:  ${driverData.carName} (${driverData.carPlateNum})`);
    console.log(`Type:     ${driverData.carType}`);
    console.log(`Status:   ${driverData.driverStatus}`);
    console.log('═══════════════════════════════════════\n');

    console.log('📱 TESTING STEPS:');
    console.log('1. Open the app');
    console.log('2. Login with:');
    console.log(`   - Email: ${email}`);
    console.log(`   - Password: ${password}`);
    console.log('3. Should navigate to Driver Main (4 tabs)');
    console.log('4. Try going online from Home tab');
    console.log('5. Check Earnings, History, and Profile tabs\n');

    console.log('🔍 FIREBASE VERIFICATION:');
    console.log('- Authentication: https://console.firebase.google.com/project/trippo-42089/authentication/users');
    console.log('- Firestore users: https://console.firebase.google.com/project/trippo-42089/firestore/data/~2Fusers');
    console.log('- Firestore drivers: https://console.firebase.google.com/project/trippo-42089/firestore/data/~2Fdrivers\n');

  } catch (error) {
    console.error('❌ Error creating driver:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

createTestDriver();

