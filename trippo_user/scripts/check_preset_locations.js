const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function checkPresetLocations() {
  console.log('🔍 Checking Preset Locations Collection\n');
  
  const snapshot = await db.collection('presetLocations').get();
  
  console.log(`📊 Total preset locations: ${snapshot.size}\n`);
  
  if (snapshot.empty) {
    console.log('⚠️  No preset locations found in database!');
    console.log('   This is why the app shows "Error fetching preset locations"\n');
    console.log('💡 Solution: Run the seed script to add preset locations');
    return;
  }
  
  snapshot.forEach((doc, index) => {
    const data = doc.data();
    console.log(`${index + 1}. ${data.name || 'Unnamed'}`);
    console.log(`   Category: ${data.category || 'N/A'}`);
    console.log(`   Active: ${data.isActive ? 'Yes' : 'No'}`);
    console.log(`   Order: ${data.order || 0}`);
    console.log(`   Location: ${data.latitude}, ${data.longitude}`);
    console.log('');
  });
}

checkPresetLocations()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
