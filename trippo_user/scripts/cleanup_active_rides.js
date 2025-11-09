/**
 * Cleanup Script: Fix Corrupted Active Rides
 * 
 * This script fixes drivers who have multiple "active" rides.
 * A driver should only have at most 1 active ride (accepted or ongoing).
 * 
 * What it does:
 * 1. Finds all drivers with multiple active rides
 * 2. Keeps the most recent ride as active
 * 3. Marks older rides as completed (if they're really old) or cancelled
 * 4. Updates payment status appropriately
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupActiveRides() {
  console.log('🧹 Starting Active Rides Cleanup...\n');

  try {
    // Get all rides that are in rideRequests (not yet in history)
    const ridesSnapshot = await db.collection('rideRequests').get();
    
    console.log(`📊 Total rides in rideRequests: ${ridesSnapshot.size}\n`);

    // Group rides by driver
    const ridesByDriver = {};
    
    ridesSnapshot.forEach(doc => {
      const ride = doc.data();
      const driverId = ride.driverId;
      
      // Only process rides that have a driver assigned
      if (driverId) {
        if (!ridesByDriver[driverId]) {
          ridesByDriver[driverId] = [];
        }
        ridesByDriver[driverId].push({
          id: doc.id,
          ...ride,
          requestedAt: ride.requestedAt?.toDate() || new Date(),
          acceptedAt: ride.acceptedAt?.toDate() || null,
          startedAt: ride.startedAt?.toDate() || null,
          completedAt: ride.completedAt?.toDate() || null,
        });
      }
    });

    console.log(`👥 Total drivers with assigned rides: ${Object.keys(ridesByDriver).length}\n`);

    // Find drivers with multiple active rides
    const problemDrivers = [];
    
    for (const [driverId, rides] of Object.entries(ridesByDriver)) {
      const activeRides = rides.filter(ride => 
        ride.status === 'accepted' || ride.status === 'ongoing'
      );
      
      if (activeRides.length > 1) {
        problemDrivers.push({
          driverId,
          email: activeRides[0].driverEmail || 'unknown',
          activeCount: activeRides.length,
          rides: activeRides
        });
      }
    }

    if (problemDrivers.length === 0) {
      console.log('✅ No drivers with multiple active rides found!\n');
      return;
    }

    console.log(`⚠️  Found ${problemDrivers.length} driver(s) with multiple active rides:\n`);
    
    problemDrivers.forEach(driver => {
      console.log(`Driver: ${driver.email} (${driver.driverId})`);
      console.log(`  Active Rides: ${driver.activeCount}`);
    });

    console.log('\n🔧 Starting cleanup process...\n');

    // Process each problem driver
    for (const driver of problemDrivers) {
      console.log(`\n📧 Processing: ${driver.email}`);
      console.log(`   Found ${driver.activeCount} active rides`);

      // Sort rides by date (most recent first)
      const sortedRides = driver.rides.sort((a, b) => {
        // Sort by startedAt first (if exists), then acceptedAt, then requestedAt
        const aDate = a.startedAt || a.acceptedAt || a.requestedAt;
        const bDate = b.startedAt || b.acceptedAt || b.requestedAt;
        return bDate - aDate;
      });

      // Keep the most recent ride as active
      const keepActive = sortedRides[0];
      const toCleanup = sortedRides.slice(1);

      console.log(`   ✅ Keeping ride ${keepActive.id} as active (${keepActive.status})`);
      console.log(`   🧹 Cleaning up ${toCleanup.length} old rides`);

      // Cleanup old rides
      const batch = db.batch();
      let cleanedCount = 0;

      for (const ride of toCleanup) {
        const rideRef = db.collection('rideRequests').doc(ride.id);
        
        // Determine what to do with the ride
        const now = new Date();
        const rideAge = now - (ride.acceptedAt || ride.requestedAt);
        const hoursOld = rideAge / (1000 * 60 * 60);

        if (hoursOld > 24) {
          // If ride is more than 24 hours old, mark as completed
          console.log(`      - ${ride.id}: Completing (${Math.floor(hoursOld)}h old)`);
          batch.update(rideRef, {
            status: 'completed',
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            paymentStatus: ride.paymentMethod === 'cash' ? 'pending' : 'completed',
          });
        } else {
          // If recent, mark as cancelled
          console.log(`      - ${ride.id}: Cancelling (${Math.floor(hoursOld)}h old)`);
          batch.update(rideRef, {
            status: 'cancelled',
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            cancellationReason: 'Auto-cancelled: Multiple active rides cleanup',
          });
        }
        
        cleanedCount++;
      }

      // Commit the batch
      if (cleanedCount > 0) {
        await batch.commit();
        console.log(`   ✅ Cleaned up ${cleanedCount} rides for ${driver.email}`);
      }
    }

    console.log('\n✅ Cleanup completed!\n');
    console.log('📊 Summary:');
    console.log(`   Drivers processed: ${problemDrivers.length}`);
    console.log(`   Total rides cleaned: ${problemDrivers.reduce((sum, d) => sum + (d.activeCount - 1), 0)}`);

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  } finally {
    // Exit
    process.exit(0);
  }
}

// Run the cleanup
cleanupActiveRides();

