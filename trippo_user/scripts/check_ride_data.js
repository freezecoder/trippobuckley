const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function checkRideData() {
  console.log('🔍 Checking recent ride requests for passenger location data...\n');
  
  const ridesSnapshot = await db.collection('rideRequests')
    .orderBy('requestedAt', 'desc')
    .limit(3)
    .get();
  
  if (ridesSnapshot.empty) {
    console.log('⚠️  No ride requests found');
    return;
  }
  
  ridesSnapshot.forEach((doc, index) => {
    const data = doc.data();
    console.log(`\nRide ${index + 1}: ${doc.id}`);
    console.log('─'.repeat(60));
    console.log(`Status: ${data.status}`);
    console.log(`User: ${data.userEmail || 'N/A'}`);
    console.log(`Driver: ${data.driverEmail || 'None assigned'}`);
    console.log(`\n📍 Pickup:`);
    console.log(`   Address: "${data.pickupAddress || 'BLANK/MISSING'}"`);
    console.log(`   Location: ${data.pickupLocation ? `${data.pickupLocation.latitude}, ${data.pickupLocation.longitude}` : 'MISSING'}`);
    console.log(`\n📍 Dropoff:`);
    console.log(`   Address: "${data.dropoffAddress || 'BLANK/MISSING'}"`);
    console.log(`   Location: ${data.dropoffLocation ? `${data.dropoffLocation.latitude}, ${data.dropoffLocation.longitude}` : 'MISSING'}`);
    console.log(`\nFare: $${data.fare}`);
    console.log(`Distance: ${data.distance} km`);
  });
  
  console.log('\n' + '='.repeat(60));
  console.log('✅ Check complete');
}

checkRideData()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
