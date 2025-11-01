/**
 * Fix Driver User Type in Firestore
 * 
 * This script checks the userType field for driver@bt.com and updates it to "driver"
 * if it's incorrectly set to "user".
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://trippo-42089.firebaseio.com'
  });
}

const db = admin.firestore();

async function fixDriverUserType() {
  try {
    console.log('🔍 Looking for driver@bt.com...');
    
    // Query users collection for driver@bt.com
    const usersSnapshot = await db.collection('users')
      .where('email', '==', 'driver@bt.com')
      .get();
    
    if (usersSnapshot.empty) {
      console.log('❌ driver@bt.com not found in users collection');
      return;
    }
    
    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();
    const userId = userDoc.id;
    
    console.log('\n📋 Current user data:');
    console.log(`   UID: ${userId}`);
    console.log(`   Email: ${userData.email}`);
    console.log(`   Name: ${userData.name}`);
    console.log(`   UserType: ${userData.userType} ${userData.userType === 'driver' ? '✅' : '❌'}`);
    
    // Check if user has driver document
    const driverDoc = await db.collection('drivers').doc(userId).get();
    const hasDriverDoc = driverDoc.exists;
    
    console.log(`   Driver document exists: ${hasDriverDoc ? '✅' : '❌'}`);
    
    if (hasDriverDoc) {
      const driverData = driverDoc.data();
      console.log(`   Car: ${driverData.carName || 'Not set'}`);
      console.log(`   Plate: ${driverData.carPlateNum || 'Not set'}`);
      console.log(`   Type: ${driverData.carType || 'Not set'}`);
    }
    
    // Fix userType if needed
    if (userData.userType !== 'driver') {
      console.log('\n⚠️  UserType is incorrect, fixing...');
      
      await db.collection('users').doc(userId).update({
        userType: 'driver'
      });
      
      console.log('✅ UserType updated to "driver"');
      
      // Create driver document if it doesn't exist
      if (!hasDriverDoc) {
        console.log('⚠️  Driver document missing, creating...');
        
        await db.collection('drivers').doc(userId).set({
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
        
        console.log('✅ Driver document created');
      }
    } else {
      console.log('\n✅ UserType is already correct!');
    }
    
    // Verify the fix
    console.log('\n🔍 Verifying fix...');
    const verifyDoc = await db.collection('users').doc(userId).get();
    const verifyData = verifyDoc.data();
    
    console.log(`   UserType: ${verifyData.userType} ${verifyData.userType === 'driver' ? '✅' : '❌'}`);
    
    if (verifyData.userType === 'driver') {
      console.log('\n🎉 driver@bt.com is now properly configured as a driver!');
      console.log('   You can now log in and should be redirected to the driver interface.');
    } else {
      console.log('\n❌ Fix failed - userType is still incorrect');
    }
    
  } catch (error) {
    console.error('❌ Error fixing driver userType:', error);
    throw error;
  }
}

// Run the script
fixDriverUserType()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });

