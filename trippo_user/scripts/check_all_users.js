/**
 * Check All Users in Firestore
 * 
 * This script lists all users and their userType values
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

async function checkAllUsers() {
  try {
    console.log('🔍 Checking all users in Firestore...\n');
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    
    console.log(`Found ${usersSnapshot.size} users:\n`);
    console.log('=' .repeat(80));
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userId = doc.id;
      
      // Check if has driver document
      const driverDoc = await db.collection('drivers').doc(userId).get();
      const hasDriverDoc = driverDoc.exists;
      
      // Check if has userProfile document
      const profileDoc = await db.collection('userProfiles').doc(userId).get();
      const hasProfileDoc = profileDoc.exists;
      
      console.log(`📧 Email: ${userData.email}`);
      console.log(`   UID: ${userId}`);
      console.log(`   Name: ${userData.name || 'Not set'}`);
      console.log(`   UserType: "${userData.userType}" ${userData.userType === 'driver' ? '🚗' : '👤'}`);
      console.log(`   Driver document: ${hasDriverDoc ? '✅' : '❌'}`);
      console.log(`   UserProfile document: ${hasProfileDoc ? '✅' : '❌'}`);
      
      if (hasDriverDoc) {
        const driverData = driverDoc.data();
        console.log(`   🚗 Car: ${driverData.carName || 'Not set'}`);
      }
      
      // Check for mismatch
      if (userData.userType === 'driver' && !hasDriverDoc) {
        console.log('   ⚠️  WARNING: userType is "driver" but no driver document!');
      }
      if (userData.userType === 'user' && !hasProfileDoc) {
        console.log('   ⚠️  WARNING: userType is "user" but no userProfile document!');
      }
      if (userData.userType === 'driver' && hasProfileDoc) {
        console.log('   ⚠️  WARNING: userType is "driver" but has userProfile (should only have driver doc)!');
      }
      
      console.log('=' .repeat(80));
    }
    
    // Summary
    console.log('\n📊 Summary:');
    const drivers = usersSnapshot.docs.filter(doc => doc.data().userType === 'driver').length;
    const users = usersSnapshot.docs.filter(doc => doc.data().userType === 'user').length;
    const others = usersSnapshot.docs.filter(doc => !['driver', 'user'].includes(doc.data().userType)).length;
    
    console.log(`   Drivers: ${drivers}`);
    console.log(`   Users: ${users}`);
    console.log(`   Other/Invalid: ${others}`);
    
  } catch (error) {
    console.error('❌ Error checking users:', error);
    throw error;
  }
}

// Run the script
checkAllUsers()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });

