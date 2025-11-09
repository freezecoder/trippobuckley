/**
 * Check Driver Rides Script
 * 
 * Shows all rides for a specific driver email
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkDriverRides(driverEmail) {
  console.log(`🔍 Checking rides for: ${driverEmail}\n`);

  try {
    // Get driver document to find driverId
    const usersSnapshot = await db.collection('users')
      .where('email', '==', driverEmail)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('❌ Driver not found in users collection\n');
      return;
    }

    const driverId = usersSnapshot.docs[0].id;
    const driverData = usersSnapshot.docs[0].data();
    
    console.log(`Driver ID: ${driverId}`);
    console.log(`Driver Name: ${driverData.name || 'N/A'}`);
    console.log(`User Type: ${driverData.userType}\n`);

    // Check rideRequests collection
    console.log('📋 RIDE REQUESTS (Active rides):');
    console.log('=' .repeat(60));
    
    const requestsSnapshot = await db.collection('rideRequests')
      .where('driverId', '==', driverId)
      .get();
    
    if (requestsSnapshot.empty) {
      console.log('  No rides found in rideRequests\n');
    } else {
      console.log(`  Total: ${requestsSnapshot.size} rides\n`);
      
      const ridesByStatus = {};
      
      requestsSnapshot.forEach(doc => {
        const ride = doc.data();
        const status = ride.status || 'unknown';
        
        if (!ridesByStatus[status]) {
          ridesByStatus[status] = [];
        }
        
        ridesByStatus[status].push({
          id: doc.id,
          pickupAddress: ride.pickupAddress?.substring(0, 40) + '...' || 'N/A',
          fare: ride.fare,
          paymentMethod: ride.paymentMethod,
          paymentStatus: ride.paymentStatus,
          requestedAt: ride.requestedAt?.toDate() || 'N/A',
          acceptedAt: ride.acceptedAt?.toDate() || 'N/A',
          startedAt: ride.startedAt?.toDate() || 'N/A',
          completedAt: ride.completedAt?.toDate() || 'N/A',
        });
      });

      for (const [status, rides] of Object.entries(ridesByStatus)) {
        console.log(`\n  Status: ${status.toUpperCase()} (${rides.length} rides)`);
        rides.forEach((ride, idx) => {
          console.log(`    ${idx + 1}. ID: ${ride.id}`);
          console.log(`       Pickup: ${ride.pickupAddress}`);
          console.log(`       Fare: $${ride.fare}`);
          console.log(`       Payment: ${ride.paymentMethod} (${ride.paymentStatus})`);
          console.log(`       Requested: ${ride.requestedAt}`);
          if (ride.acceptedAt !== 'N/A') {
            console.log(`       Accepted: ${ride.acceptedAt}`);
          }
          if (ride.startedAt !== 'N/A') {
            console.log(`       Started: ${ride.startedAt}`);
          }
          if (ride.completedAt !== 'N/A') {
            console.log(`       Completed: ${ride.completedAt}`);
          }
        });
      }
    }

    // Check rideHistory collection
    console.log('\n\n📚 RIDE HISTORY (Completed rides):');
    console.log('=' .repeat(60));
    
    const historySnapshot = await db.collection('rideHistory')
      .where('driverId', '==', driverId)
      .get();
    
    if (historySnapshot.empty) {
      console.log('  No rides found in rideHistory\n');
    } else {
      console.log(`  Total: ${historySnapshot.size} rides\n`);
      
      const ridesByStatus = {};
      
      historySnapshot.forEach(doc => {
        const ride = doc.data();
        const status = ride.status || 'unknown';
        
        if (!ridesByStatus[status]) {
          ridesByStatus[status] = [];
        }
        
        ridesByStatus[status].push({
          id: doc.id,
          fare: ride.fare,
          paymentMethod: ride.paymentMethod,
          paymentStatus: ride.paymentStatus,
          completedAt: ride.completedAt?.toDate() || 'N/A',
        });
      });

      for (const [status, rides] of Object.entries(ridesByStatus)) {
        console.log(`  Status: ${status.toUpperCase()} (${rides.length} rides)`);
      }
    }

    // Summary
    console.log('\n\n📊 SUMMARY:');
    console.log('=' .repeat(60));
    console.log(`Total in rideRequests: ${requestsSnapshot.size}`);
    console.log(`Total in rideHistory: ${historySnapshot.size}`);
    console.log(`Grand Total: ${requestsSnapshot.size + historySnapshot.size}`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

// Get driver email from command line or use default
const driverEmail = process.argv[2] || 'driver@bt.com';
checkDriverRides(driverEmail);
