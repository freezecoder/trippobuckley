#!/usr/bin/env node

/**
 * Script to fix Firestore structure and migrate user data
 * Fixes the issue where collections are named by email instead of proper structure
 * Run with: node scripts/fix_firestore_structure.js <your-email>
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin with correct project
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'trippo-42089'  // Correct project ID
});

const auth = admin.auth();
const db = admin.firestore();

async function fixUserData(email) {
  console.log(`🔧 Fixing Firestore structure for: ${email}\n`);

  try {
    // 1. Get Firebase Auth user
    console.log('📋 Step 1: Fetching Firebase Auth user...');
    let authUser;
    try {
      authUser = await auth.getUserByEmail(email);
      console.log(`✅ Found auth user with UID: ${authUser.uid}`);
    } catch (error) {
      console.log('❌ Firebase Auth user NOT FOUND');
      console.log(`   Please create an account first or check the email: ${email}`);
      process.exit(1);
    }

    const uid = authUser.uid;
    const displayName = authUser.displayName || email.split('@')[0];

    // 2. Create/Update users collection document
    console.log('\n📋 Step 2: Creating/updating users collection...');
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    const userData = {
      email: authUser.email,
      name: displayName,
      userType: 'user',  // Default to user, change to 'driver' if needed
      phoneNumber: '',
      createdAt: userDoc.exists && userDoc.data().createdAt 
        ? userDoc.data().createdAt 
        : admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      fcmToken: '',
      profileImageUrl: ''
    };

    await userRef.set(userData, { merge: true });
    console.log('✅ Created/updated users/' + uid);

    // 3. Create userProfiles collection document
    console.log('\n📋 Step 3: Creating userProfiles document...');
    const profileRef = db.collection('userProfiles').doc(uid);
    const profileDoc = await profileRef.get();

    if (!profileDoc.exists) {
      await profileRef.set({
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
      console.log('✅ Created userProfiles/' + uid);
    } else {
      console.log('✅ userProfiles/' + uid + ' already exists');
    }

    // 4. Check if user should be a driver
    console.log('\n📋 Step 4: Checking for driver data...');
    const driversCollection = await db.collection('Drivers').get();
    let isDriver = false;

    for (const doc of driversCollection.docs) {
      xxconst driverData = doc.data();
      if (driverData.email === email || driverData.uid === uid) {
        isDriver = true;
        console.log('✅ Found driver data, migrating...');

        // Update user to be a driver
        await userRef.update({ userType: 'driver' });

        // Create/update driver document
        const driverRef = db.collection('drivers').doc(uid);
        await driverRef.set({
          carName: driverData.carName || '',
          carPlateNum: driverData.carPlateNum || '',
          carType: driverData.carType || '',
          rate: driverData.rate || 3.0,
          driverStatus: driverData.driverStatus || 'Offline',
          rating: driverData.rating || 5.0,
          totalRides: driverData.totalRides || 0,
          earnings: driverData.earnings || 0.0,
          isVerified: driverData.isVerified || false,
          ...(driverData.driverLoc && { driverLoc: driverData.driverLoc }),
          ...(driverData.geohash && { geohash: driverData.geohash })
        }, { merge: true });

        console.log('✅ Migrated to drivers/' + uid);
        break;
      }
    }

    if (!isDriver) {
      console.log('ℹ️  No driver data found, user set as regular user');
    }

    // 5. Clean up old email-based collections (optional)
    console.log('\n📋 Step 5: Checking for email-based collections to migrate...');
    const emailCollection = await db.collection(email).get();
    if (!emailCollection.empty) {
      console.log(`⚠️  Found old collection named '${email}'`);
      console.log('   You may want to manually delete this after verification');
      // Don't auto-delete to be safe
    }

    console.log('\n✅ DONE! Firestore structure fixed.');
    console.log('\n📊 Summary:');
    console.log(`   UID: ${uid}`);
    console.log(`   Email: ${email}`);
    console.log(`   Name: ${displayName}`);
    console.log(`   Role: ${isDriver ? 'driver' : 'user'}`);
    console.log(`   users/${uid}: ✅`);
    console.log(`   ${isDriver ? 'drivers' : 'userProfiles'}/${uid}: ✅`);
    console.log('\n🎉 You should now be able to log in!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }

  process.exit(0);
}

// Get email from command line
const email = process.argv[2];
if (!email) {
  console.log('❌ Usage: node scripts/fix_firestore_structure.js <your-email>');
  console.log('   Example: node scripts/fix_firestore_structure.js zayed.albertyn@gmail.com');
  process.exit(1);
}

fixUserData(email);

