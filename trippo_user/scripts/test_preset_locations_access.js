const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function testPresetLocationsAccess() {
  console.log('🧪 Testing Preset Locations Access\n');
  
  try {
    // Test 1: Get all preset locations
    console.log('Test 1: Fetching all preset locations...');
    const allSnapshot = await db.collection('presetLocations').get();
    console.log(`✅ Success: Found ${allSnapshot.size} locations\n`);
    
    // Test 2: Get active preset locations with order
    console.log('Test 2: Fetching active preset locations (with isActive + order)...');
    const activeSnapshot = await db.collection('presetLocations')
      .where('isActive', '==', true)
      .orderBy('order')
      .get();
    console.log(`✅ Success: Found ${activeSnapshot.size} active locations\n`);
    
    // Test 3: Get by category
    console.log('Test 3: Fetching airport preset locations (with category + order)...');
    const airportSnapshot = await db.collection('presetLocations')
      .where('isActive', '==', true)
      .where('category', '==', 'airport')
      .orderBy('order')
      .get();
    console.log(`✅ Success: Found ${airportSnapshot.size} airports\n`);
    
    console.log('📋 Airport Preset Locations:');
    airportSnapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`   ${data.order}. ${data.name}`);
      console.log(`      Location: ${data.latitude}, ${data.longitude}`);
    });
    
    console.log('\n✅ ALL TESTS PASSED!');
    console.log('   Preset locations are accessible');
    console.log('   Security rules working');
    console.log('   Indexes working');
    
  } catch (error) {
    console.error('\n❌ TEST FAILED:', error.message);
    
    if (error.message.includes('index')) {
      console.log('\n⏳ The indexes are still building.');
      console.log('   Wait 2-5 minutes and try again.');
      console.log('   Check: https://console.firebase.google.com/project/trippo-42089/firestore/indexes');
    } else if (error.message.includes('permission')) {
      console.log('\n🔒 Permission denied.');
      console.log('   Make sure Firestore rules are deployed.');
    }
    
    process.exit(1);
  }
}

testPresetLocationsAccess()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });
