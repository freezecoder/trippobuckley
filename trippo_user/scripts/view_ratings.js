/**
 * View Ratings Script
 * 
 * Shows all ratings and feedback for rides
 * Can view by:
 * - Specific ride ID
 * - All rides for a driver
 * - All rides for a user
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

/**
 * View ratings for a specific ride
 */
async function viewRideRating(rideId) {
  console.log(`\n⭐ Viewing ratings for ride: ${rideId}\n`);
  console.log('=' .repeat(70));

  try {
    // Check ride history first
    let rideDoc = await db.collection('rideHistory').doc(rideId).get();
    
    if (!rideDoc.exists) {
      // Check rideRequests
      rideDoc = await db.collection('rideRequests').doc(rideId).get();
    }
    
    if (!rideDoc.exists) {
      console.log('❌ Ride not found\n');
      return;
    }

    const ride = rideDoc.data();
    
    // Ride info
    console.log('📍 Ride Information:');
    console.log(`   From: ${ride.pickupAddress?.substring(0, 50) || 'N/A'}...`);
    console.log(`   To: ${ride.dropoffAddress?.substring(0, 50) || 'N/A'}...`);
    console.log(`   Fare: $${ride.fare || 'N/A'}`);
    console.log(`   Status: ${ride.status || 'N/A'}`);
    if (ride.completedAt) {
      console.log(`   Completed: ${ride.completedAt.toDate()}`);
    }
    
    console.log('\n👤 USER Rating of DRIVER:');
    if (ride.userRating) {
      console.log(`   ⭐ Stars: ${ride.userRating}/5.0`);
      console.log(`   💬 Feedback: "${ride.userFeedback || 'No feedback provided'}"`);
    } else {
      console.log('   ⚠️  Not yet rated by user');
    }
    
    console.log('\n🚗 DRIVER Rating of USER:');
    if (ride.driverRating) {
      console.log(`   ⭐ Stars: ${ride.driverRating}/5.0`);
      console.log(`   💬 Feedback: "${ride.driverFeedback || 'No feedback provided'}"`);
    } else {
      console.log('   ⚠️  Not yet rated by driver');
    }
    
    console.log('\n' + '=' .repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * View all ratings for a driver
 */
async function viewDriverRatings(driverEmail) {
  console.log(`\n⭐ Viewing all ratings for driver: ${driverEmail}\n`);
  console.log('=' .repeat(70));

  try {
    // Get driver user ID
    const usersSnapshot = await db.collection('users')
      .where('email', '==', driverEmail)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('❌ Driver not found\n');
      return;
    }

    const driverId = usersSnapshot.docs[0].id;
    const driverData = usersSnapshot.docs[0].data();
    
    console.log(`\nDriver: ${driverData.name || 'N/A'}`);
    console.log(`ID: ${driverId}\n`);
    
    // Get driver's average rating
    const driverDoc = await db.collection('drivers').doc(driverId).get();
    if (driverDoc.exists) {
      const driver = driverDoc.data();
      console.log(`📊 Overall Statistics:`);
      console.log(`   Average Rating: ⭐ ${driver.rating || 'N/A'}/5.0`);
      console.log(`   Total Rides: ${driver.totalRides || 0}`);
      console.log(`   Total Earnings: $${driver.earnings || 0}\n`);
    }
    
    // Get all rides in history
    const ridesSnapshot = await db.collection('rideHistory')
      .where('driverId', '==', driverId)
      .where('userRating', '!=', null)  // Only rides that were rated
      .orderBy('userRating', 'desc')
      .orderBy('completedAt', 'desc')
      .limit(20)
      .get();
    
    if (ridesSnapshot.empty) {
      console.log('📝 No ratings found for this driver\n');
      return;
    }

    console.log(`📝 Recent Ratings (${ridesSnapshot.size} rides):\n`);
    
    ridesSnapshot.forEach((doc, index) => {
      const ride = doc.data();
      console.log(`${index + 1}. ⭐ ${ride.userRating}/5.0 - ${ride.completedAt?.toDate().toLocaleDateString() || 'N/A'}`);
      if (ride.userFeedback) {
        console.log(`   💬 "${ride.userFeedback}"`);
      }
      console.log('');
    });
    
    console.log('=' .repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * View all ratings given by a user
 */
async function viewUserRatings(userEmail) {
  console.log(`\n⭐ Viewing all ratings by user: ${userEmail}\n`);
  console.log('=' .repeat(70));

  try {
    // Get user ID
    const usersSnapshot = await db.collection('users')
      .where('email', '==', userEmail)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('❌ User not found\n');
      return;
    }

    const userId = usersSnapshot.docs[0].id;
    const userData = usersSnapshot.docs[0].data();
    
    console.log(`\nUser: ${userData.name || 'N/A'}`);
    console.log(`ID: ${userId}\n`);
    
    // Get user's average rating (from drivers)
    const profileDoc = await db.collection('userProfiles').doc(userId).get();
    if (profileDoc.exists) {
      const profile = profileDoc.data();
      console.log(`📊 Overall Statistics:`);
      console.log(`   Average Rating (from drivers): ⭐ ${profile.rating || 'N/A'}/5.0`);
      console.log(`   Total Rides: ${profile.totalRides || 0}\n`);
    }
    
    // Get all rides where user rated the driver
    const ridesSnapshot = await db.collection('rideHistory')
      .where('userId', '==', userId)
      .where('userRating', '!=', null)  // Only rides where user gave rating
      .orderBy('userRating', 'desc')
      .orderBy('completedAt', 'desc')
      .limit(20)
      .get();
    
    if (ridesSnapshot.empty) {
      console.log('📝 No ratings given by this user\n');
      return;
    }

    console.log(`📝 Ratings Given by User (${ridesSnapshot.size} rides):\n`);
    
    ridesSnapshot.forEach((doc, index) => {
      const ride = doc.data();
      console.log(`${index + 1}. ⭐ ${ride.userRating}/5.0 - ${ride.completedAt?.toDate().toLocaleDateString() || 'N/A'}`);
      console.log(`   Driver: ${ride.driverEmail || 'N/A'}`);
      if (ride.userFeedback) {
        console.log(`   💬 "${ride.userFeedback}"`);
      }
      console.log('');
    });
    
    console.log('=' .repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * Show recent ratings summary
 */
async function showRecentRatings(limit = 10) {
  console.log(`\n⭐ Recent ${limit} Ratings\n`);
  console.log('=' .repeat(70));

  try {
    const ridesSnapshot = await db.collection('rideHistory')
      .where('userRating', '!=', null)
      .orderBy('userRating', 'desc')
      .orderBy('completedAt', 'desc')
      .limit(limit)
      .get();
    
    if (ridesSnapshot.empty) {
      console.log('📝 No ratings found\n');
      return;
    }

    console.log(`\nFound ${ridesSnapshot.size} rated rides:\n`);
    
    ridesSnapshot.forEach((doc, index) => {
      const ride = doc.data();
      console.log(`${index + 1}. Ride ${doc.id.substring(0, 8)}... - ${ride.completedAt?.toDate().toLocaleDateString() || 'N/A'}`);
      console.log(`   User → Driver: ⭐ ${ride.userRating}/5.0`);
      if (ride.userFeedback) {
        console.log(`   💬 "${ride.userFeedback}"`);
      }
      if (ride.driverRating) {
        console.log(`   Driver → User: ⭐ ${ride.driverRating}/5.0`);
        if (ride.driverFeedback) {
          console.log(`   💬 "${ride.driverFeedback}"`);
        }
      }
      console.log('');
    });
    
    console.log('=' .repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Main execution
async function main() {
  const command = process.argv[2];
  const argument = process.argv[3];

  if (!command) {
    console.log('\n📚 Ratings Viewer - Usage:\n');
    console.log('View specific ride:');
    console.log('  node scripts/view_ratings.js ride <rideId>');
    console.log('\nView driver ratings:');
    console.log('  node scripts/view_ratings.js driver <email>');
    console.log('\nView user ratings:');
    console.log('  node scripts/view_ratings.js user <email>');
    console.log('\nView recent ratings:');
    console.log('  node scripts/view_ratings.js recent [limit]');
    console.log('\nExamples:');
    console.log('  node scripts/view_ratings.js ride abc123xyz');
    console.log('  node scripts/view_ratings.js driver driver@bt.com');
    console.log('  node scripts/view_ratings.js user user@bt.com');
    console.log('  node scripts/view_ratings.js recent 20');
    console.log('');
    process.exit(0);
  }

  switch (command.toLowerCase()) {
    case 'ride':
      if (!argument) {
        console.log('❌ Please provide a ride ID');
        process.exit(1);
      }
      await viewRideRating(argument);
      break;
    
    case 'driver':
      if (!argument) {
        console.log('❌ Please provide driver email');
        process.exit(1);
      }
      await viewDriverRatings(argument);
      break;
    
    case 'user':
      if (!argument) {
        console.log('❌ Please provide user email');
        process.exit(1);
      }
      await viewUserRatings(argument);
      break;
    
    case 'recent':
      const limit = argument ? parseInt(argument) : 10;
      await showRecentRatings(limit);
      break;
    
    default:
      console.log(`❌ Unknown command: ${command}`);
      console.log('Use: ride, driver, user, or recent');
      process.exit(1);
  }

  process.exit(0);
}

main();

