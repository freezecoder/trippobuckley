#!/usr/bin/env node

/**
 * Script to diagnose Firebase authentication and Firestore user data issues
 * Run with: node scripts/diagnose_auth.js <email>
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const auth = admin.auth();
const db = admin.firestore();

async function diagnoseUser(email) {
  console.log(`🔍 Diagnosing authentication for: ${email}\n`);

  try {
    // 1. Check Firebase Auth
    console.log('📋 Step 1: Checking Firebase Authentication...');
    let authUser;
    try {
      authUser = await auth.getUserByEmail(email);
      console.log('✅ Firebase Auth account exists');
      console.log(`   UID: ${authUser.uid}`);
      console.log(`   Email: ${authUser.email}`);
      console.log(`   Display Name: ${authUser.displayName || '(not set)'}`);
      console.log(`   Disabled: ${authUser.disabled}`);
      console.log(`   Email Verified: ${authUser.emailVerified}`);
    } catch (error) {
      console.log('❌ Firebase Auth account NOT FOUND');
      console.log(`   Error: ${error.message}`);
      process.exit(1);
    }

    const uid = authUser.uid;

    // 2. Check users collection
    console.log('\n📋 Step 2: Checking users collection...');
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      console.log('❌ User document NOT FOUND in users collection');
      console.log('   ⚠️  This is the problem! Creating user document...');
      
      // Create missing user document
      const userData = {
        email: authUser.email,
        name: authUser.displayName || email.split('@')[0],
        userType: 'user', // Default to user, can be changed
        phoneNumber: '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        fcmToken: '',
        profileImageUrl: ''
      };
      
      await db.collection('users').doc(uid).set(userData);
      console.log('✅ Created user document with userType: user');
      console.log('   You can update userType to "driver" if needed');
    } else {
      console.log('✅ User document exists in users collection');
      const userData = userDoc.data();
      console.log(`   User Type: ${userData.userType || '⚠️ MISSING'}`);
      console.log(`   Name: ${userData.name || '(not set)'}`);
      console.log(`   Phone: ${userData.phoneNumber || '(not set)'}`);
      console.log(`   Active: ${userData.isActive}`);
      
      if (!userData.userType) {
        console.log('\n⚠️  userType field is MISSING! Adding it now...');
        await db.collection('users').doc(uid).update({
          userType: 'user'
        });
        console.log('✅ Added userType: user');
      }
    }

    // 3. Check role-specific collections
    console.log('\n📋 Step 3: Checking role-specific collections...');
    
    const userDoc2 = await db.collection('users').doc(uid).get();
    const userType = userDoc2.data()?.userType;
    
    if (userType === 'driver') {
      const driverDoc = await db.collection('drivers').doc(uid).get();
      if (!driverDoc.exists) {
        console.log('❌ Driver document NOT FOUND in drivers collection');
        console.log('   Creating driver document...');
        await db.collection('drivers').doc(uid).set({
          carName: '',
          carPlateNum: '',
          carType: '',
          rate: 3.0,
          driverStatus: 'Offline',
          rating: 5.0,
          totalRides: 0,
          earnings: 0.0,
          isVerified: false
        });
        console.log('✅ Created driver document');
      } else {
        console.log('✅ Driver document exists');
        const driverData = driverDoc.data();
        console.log(`   Status: ${driverData.driverStatus}`);
        console.log(`   Vehicle: ${driverData.carName || '(not configured)'}`);
        console.log(`   Rating: ${driverData.rating}`);
      }
    } else {
      const profileDoc = await db.collection('userProfiles').doc(uid).get();
      if (!profileDoc.exists) {
        console.log('❌ User profile NOT FOUND in userProfiles collection');
        console.log('   Creating user profile...');
        await db.collection('userProfiles').doc(uid).set({
          homeAddress: '',
          workAddress: '',
          favoriteLocations: [],
          paymentMethods: [],
          preferences: {
            notifications: true,
            language: 'en',
            theme: 'dark'
          },
          totalRides: 0,
          rating: 5.0
        });
        console.log('✅ Created user profile document');
      } else {
        console.log('✅ User profile exists');
        const profileData = profileDoc.data();
        console.log(`   Home: ${profileData.homeAddress || '(not set)'}`);
        console.log(`   Total Rides: ${profileData.totalRides || 0}`);
      }
    }

    console.log('\n✅ Diagnosis complete! User should be able to log in now.');
    console.log('\n📝 Summary:');
    console.log(`   UID: ${uid}`);
    console.log(`   Email: ${email}`);
    console.log(`   Role: ${userType}`);
    console.log(`   Auth: ✅`);
    console.log(`   Firestore: ✅`);

  } catch (error) {
    console.error('❌ Error during diagnosis:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

// Get email from command line
const email = process.argv[2];
if (!email) {
  console.log('❌ Usage: node scripts/diagnose_auth.js <email>');
  process.exit(1);
}

diagnoseUser(email);

