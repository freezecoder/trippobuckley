const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixDriverEarningsFields() {
  console.log('🔍 Checking all drivers for missing earnings fields...\n');
  
  const driversSnapshot = await db.collection('drivers').get();
  
  if (driversSnapshot.empty) {
    console.log('⚠️  No drivers found in database');
    console.log('   Make sure you have registered as a driver first.');
    return;
  }
  
  console.log(`📊 Found ${driversSnapshot.size} driver(s)\n`);
  
  let fixed = 0;
  let alreadyOk = 0;
  
  for (const doc of driversSnapshot.docs) {
    const data = doc.data();
    const updates = {};
    const missing = [];
    
    // Check and add missing fields
    if (data.earnings === undefined || data.earnings === null) {
      updates.earnings = 0.0;
      missing.push('earnings');
    }
    if (data.totalRides === undefined || data.totalRides === null) {
      updates.totalRides = 0;
      missing.push('totalRides');
    }
    if (data.rating === undefined || data.rating === null) {
      updates.rating = 5.0;
      missing.push('rating');
    }
    
    if (Object.keys(updates).length > 0) {
      await doc.ref.update(updates);
      console.log(`✅ Fixed driver ${doc.id}`);
      console.log(`   Added fields: ${missing.join(', ')}`);
      console.log(`   Values:`, updates);
      console.log('');
      fixed++;
    } else {
      console.log(`✓  Driver ${doc.id} already has all required fields`);
      console.log(`   earnings: ${data.earnings}, totalRides: ${data.totalRides}, rating: ${data.rating}`);
      console.log('');
      alreadyOk++;
    }
  }
  
  console.log('\n' + '='.repeat(50));
  console.log('📊 Summary:');
  console.log('='.repeat(50));
  console.log(`   Drivers fixed: ${fixed}`);
  console.log(`   Already OK: ${alreadyOk}`);
  console.log(`   Total drivers: ${fixed + alreadyOk}`);
  console.log('='.repeat(50));
  
  if (fixed > 0) {
    console.log('\n✅ Success! Driver earnings fields have been initialized.');
    console.log('   Now restart your app and check the Earnings tab.');
  } else {
    console.log('\n✅ All drivers already have the required fields.');
    console.log('   If Earnings tab is still empty, check the troubleshooting guide.');
  }
}

fixDriverEarningsFields()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error.message);
    console.error('\nMake sure:');
    console.error('  1. firestore_credentials.json exists');
    console.error('  2. You have internet connection');
    console.error('  3. Firebase credentials are valid');
    process.exit(1);
  });

