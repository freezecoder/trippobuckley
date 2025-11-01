const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function fixBlankPickupAddresses() {
  console.log('🔧 Fixing Blank Pickup Addresses in Ride Requests');
  console.log('='.repeat(70));
  
  try {
    // Get all rides with blank or missing pickup addresses
    const ridesSnapshot = await db.collection('rideRequests').get();
    
    console.log(`\n📊 Found ${ridesSnapshot.size} total ride(s)`);
    
    let fixed = 0;
    let alreadyOk = 0;
    let failed = 0;
    
    for (const doc of ridesSnapshot.docs) {
      const data = doc.data();
      const rideId = doc.id;
      
      const pickupAddr = data.pickupAddress || '';
      const dropoffAddr = data.dropoffAddress || '';
      
      const pickupNeedsfix = !pickupAddr || pickupAddr.trim() === '';
      const dropoffNeedsFix = !dropoffAddr || dropoffAddr.trim() === '';
      
      if (!pickupNeedsfix && !dropoffNeedsFix) {
        alreadyOk++;
        continue;
      }
      
      console.log(`\n🔄 Fixing ride: ${rideId}`);
      console.log(`   Status: ${data.status}`);
      
      const updates = {};
      
      // Fix pickup address using reverse geocoding or default
      if (pickupNeedsfix && data.pickupLocation) {
        const lat = data.pickupLocation.latitude;
        const lng = data.pickupLocation.longitude;
        
        // Use coordinates as fallback address
        const fallbackPickup = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
        updates.pickupAddress = fallbackPickup;
        
        console.log(`   ✅ Pickup: "${fallbackPickup}" (from coordinates)`);
      }
      
      // Fix dropoff address if needed
      if (dropoffNeedsFix && data.dropoffLocation) {
        const lat = data.dropoffLocation.latitude;
        const lng = data.dropoffLocation.longitude;
        
        const fallbackDropoff = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
        updates.dropoffAddress = fallbackDropoff;
        
        console.log(`   ✅ Dropoff: "${fallbackDropoff}" (from coordinates)`);
      }
      
      if (Object.keys(updates).length > 0) {
        try {
          await doc.ref.update(updates);
          console.log(`   ✅ Updated successfully`);
          fixed++;
        } catch (error) {
          console.log(`   ❌ Failed to update: ${error.message}`);
          failed++;
        }
      }
    }
    
    // Also check rideHistory collection
    console.log('\n📚 Checking rideHistory collection...');
    const historySnapshot = await db.collection('rideHistory').get();
    console.log(`   Found ${historySnapshot.size} historical ride(s)`);
    
    for (const doc of historySnapshot.docs) {
      const data = doc.data();
      const rideId = doc.id;
      
      const pickupAddr = data.pickupAddress || '';
      const pickupNeedsFix = !pickupAddr || pickupAddr.trim() === '';
      
      if (!pickupNeedsFix) continue;
      
      if (data.pickupLocation) {
        const lat = data.pickupLocation.latitude;
        const lng = data.pickupLocation.longitude;
        const fallbackPickup = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
        
        try {
          await doc.ref.update({ pickupAddress: fallbackPickup });
          console.log(`   ✅ Fixed history ride: ${rideId}`);
          fixed++;
        } catch (error) {
          console.log(`   ❌ Failed history ride: ${rideId}`);
          failed++;
        }
      }
    }
    
    console.log('\n' + '='.repeat(70));
    console.log('📊 Summary:');
    console.log('='.repeat(70));
    console.log(`   Rides fixed: ${fixed}`);
    console.log(`   Already OK: ${alreadyOk}`);
    console.log(`   Failed: ${failed}`);
    console.log(`   Total processed: ${ridesSnapshot.size + historySnapshot.size}`);
    console.log('='.repeat(70));
    
    if (fixed > 0) {
      console.log('\n✅ Success! Blank addresses have been fixed.');
      console.log('   Drivers can now see passenger pickup locations.');
    } else {
      console.log('\n✅ All rides already have pickup addresses.');
    }
    
    console.log('\n💡 Note: Future rides will automatically have proper addresses.');
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  }
}

fixBlankPickupAddresses()
  .then(() => {
    console.log('\n✅ Script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

