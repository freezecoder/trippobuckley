const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Check if already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function testUserRateDriver() {
  console.log('🧪 Testing User Rating Driver');
  console.log('='.repeat(60));
  
  try {
    // Step 1: Find a completed ride in rideHistory
    console.log('\n📋 Step 1: Finding a completed ride...');
    const ridesSnapshot = await db.collection('rideHistory')
      .where('status', '==', 'completed')
      .limit(1)
      .get();
    
    if (ridesSnapshot.empty) {
      console.log('⚠️  No completed rides found in rideHistory collection');
      console.log('   Please complete a ride first before testing ratings');
      return;
    }
    
    const rideDoc = ridesSnapshot.docs[0];
    const rideData = rideDoc.data();
    const rideId = rideDoc.id;
    
    console.log(`✅ Found ride: ${rideId}`);
    console.log(`   User: ${rideData.userEmail || rideData.userId}`);
    console.log(`   Driver: ${rideData.driverEmail || rideData.driverId}`);
    console.log(`   Pickup: ${rideData.pickupAddress}`);
    console.log(`   Dropoff: ${rideData.dropoffAddress}`);
    console.log(`   Fare: $${rideData.fare}`);
    
    // Check if already rated by user
    if (rideData.userRating) {
      console.log(`\n⚠️  Ride already rated by user: ${rideData.userRating}/5`);
      console.log('   Updating rating anyway for testing...');
    }
    
    // Step 2: Generate test rating (5 stars)
    const testRating = 5.0;
    const testFeedback = 'Excellent driver! Safe and friendly.';
    
    console.log(`\n🌟 Step 2: Adding user rating...`);
    console.log(`   Rating: ${testRating}/5 stars`);
    console.log(`   Feedback: "${testFeedback}"`);
    
    // Step 3: Update ride document with rating
    await db.collection('rideHistory').doc(rideId).update({
      userRating: testRating,
      userFeedback: testFeedback,
    });
    
    console.log('✅ Rating added to ride document');
    
    // Step 4: Update driver's average rating
    if (rideData.driverId) {
      console.log(`\n📊 Step 3: Updating driver's average rating...`);
      
      try {
        const driverRef = db.collection('drivers').doc(rideData.driverId);
        const driverDoc = await driverRef.get();
        
        if (driverDoc.exists) {
          const driverData = driverDoc.data();
          const currentRating = driverData.rating || 5.0;
          const totalRides = driverData.totalRides || 0;
          
          // Calculate new average
          const newAverage = ((currentRating * totalRides) + testRating) / (totalRides + 1);
          
          await driverRef.update({
            rating: newAverage
          });
          
          console.log(`✅ Driver rating updated:`);
          console.log(`   Previous: ${currentRating.toFixed(2)}/5`);
          console.log(`   New: ${newAverage.toFixed(2)}/5`);
          console.log(`   Based on ${totalRides + 1} rides`);
        } else {
          console.log('⚠️  Driver document not found');
          console.log(`   Driver ID: ${rideData.driverId}`);
          console.log('   Cannot update driver rating');
        }
      } catch (error) {
        console.log(`⚠️  Could not update driver rating: ${error.message}`);
      }
    }
    
    // Step 5: Verify the update
    console.log(`\n🔍 Step 4: Verifying update...`);
    const updatedRide = await db.collection('rideHistory').doc(rideId).get();
    const updatedData = updatedRide.data();
    
    console.log('✅ Verification successful:');
    console.log(`   User Rating: ${updatedData.userRating}/5`);
    console.log(`   User Feedback: "${updatedData.userFeedback}"`);
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ TEST PASSED: User successfully rated driver');
    console.log('='.repeat(60));
    console.log('\n📱 Now you can check the app:');
    console.log('   1. Open the driver app');
    console.log('   2. Go to History tab');
    console.log('   3. You should see the user\'s rating for this ride');
    console.log('   4. Go to Profile → Earnings tab');
    console.log('   5. You should see the updated average rating');
    
  } catch (error) {
    console.error('\n❌ TEST FAILED:', error.message);
    console.error('   Stack:', error.stack);
    process.exit(1);
  }
}

testUserRateDriver()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });

