/**
 * Move Completed Rides to History
 * 
 * This script moves completed/cancelled rides from rideRequests to rideHistory.
 * They should have been moved automatically but weren't due to a bug.
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function moveCompletedRides() {
  console.log('🚚 Moving Completed Rides to History...\n');

  try {
    // Get all rides from rideRequests
    const ridesSnapshot = await db.collection('rideRequests').get();
    
    console.log(`📊 Total rides in rideRequests: ${ridesSnapshot.size}\n`);

    // Find completed/cancelled rides
    const ridesToMove = [];
    
    ridesSnapshot.forEach(doc => {
      const ride = doc.data();
      const status = ride.status || '';
      
      // Check if ride is finished (completed or cancelled)
      if (status === 'completed' || status === 'cancelled') {
        ridesToMove.push({
          id: doc.id,
          data: ride,
          status: status
        });
      }
    });

    if (ridesToMove.length === 0) {
      console.log('✅ No rides to move. All rides are in correct collections!\n');
      return;
    }

    console.log(`Found ${ridesToMove.length} completed/cancelled rides in rideRequests:`);
    console.log(`  - Completed: ${ridesToMove.filter(r => r.status === 'completed').length}`);
    console.log(`  - Cancelled: ${ridesToMove.filter(r => r.status === 'cancelled').length}`);
    console.log('\n🔄 Moving rides to rideHistory...\n');

    // Move rides in batches of 500 (Firestore limit)
    const batchSize = 500;
    let moved = 0;
    
    for (let i = 0; i < ridesToMove.length; i += batchSize) {
      const batch = db.batch();
      const batchRides = ridesToMove.slice(i, i + batchSize);
      
      for (const ride of batchRides) {
        // Check if ride already exists in history
        const historyDoc = await db.collection('rideHistory').doc(ride.id).get();
        
        if (!historyDoc.exists) {
          // Add to rideHistory
          const historyRef = db.collection('rideHistory').doc(ride.id);
          batch.set(historyRef, ride.data);
          
          console.log(`  ✅ Moving: ${ride.id} (${ride.status})`);
          moved++;
        } else {
          console.log(`  ⏭️  Skip: ${ride.id} (already in history)`);
        }
        
        // Delete from rideRequests (whether it existed in history or not)
        const requestRef = db.collection('rideRequests').doc(ride.id);
        batch.delete(requestRef);
      }
      
      // Commit batch
      await batch.commit();
      console.log(`  Batch ${Math.floor(i / batchSize) + 1} committed\n`);
    }

    console.log('\n✅ Move completed!\n');
    console.log('📊 Summary:');
    console.log(`   Total processed: ${ridesToMove.length}`);
    console.log(`   Moved to history: ${moved}`);
    console.log(`   Already in history: ${ridesToMove.length - moved}`);
    console.log(`   Deleted from rideRequests: ${ridesToMove.length}`);

    // Verify cleanup
    console.log('\n🔍 Verifying cleanup...');
    const remainingRides = await db.collection('rideRequests').get();
    console.log(`   Rides remaining in rideRequests: ${remainingRides.size}`);
    
    const historyRides = await db.collection('rideHistory').get();
    console.log(`   Rides now in rideHistory: ${historyRides.size}`);

  } catch (error) {
    console.error('❌ Error during move:', error);
  } finally {
    process.exit(0);
  }
}

// Run the cleanup
moveCompletedRides();

