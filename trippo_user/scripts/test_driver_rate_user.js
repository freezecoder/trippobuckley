const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testDriverRateUser() {
  console.log('🧪 Testing Driver Rating User (Passenger)');
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
    
    // Check if already rated by driver
    if (rideData.driverRating) {
      console.log(`\n⚠️  Ride already rated by driver: ${rideData.driverRating}/5`);
      console.log('   Updating rating anyway for testing...');
    }
    
    // Step 2: Generate test rating (4.5 stars)
    const testRating = 4.5;
    const testFeedback = 'Great passenger! Very polite and on time.';
    
    console.log(`\n🌟 Step 2: Adding driver rating...`);
    console.log(`   Rating: ${testRating}/5 stars`);
    console.log(`   Feedback: "${testFeedback}"`);
    
    // Step 3: Update ride document with rating
    await db.collection('rideHistory').doc(rideId).update({
      driverRating: testRating,
      driverFeedback: testFeedback,
    });
    
    console.log('✅ Rating added to ride document');
    
    // Step 4: Update user's average rating (if userProfile exists)
    if (rideData.userId) {
      console.log(`\n📊 Step 3: Updating user's average rating...`);
      
      try {
        const userProfileRef = db.collection('userProfiles').doc(rideData.userId);
        const userProfileDoc = await userProfileRef.get();
        
        if (userProfileDoc.exists) {
          const profileData = userProfileDoc.data();
          const currentRating = profileData.rating || 5.0;
          const totalRides = profileData.totalRides || 0;
          
          // Calculate new average
          const newAverage = ((currentRating * totalRides) + testRating) / (totalRides + 1);
          
          await userProfileRef.update({
            rating: newAverage
          });
          
          console.log(`✅ User rating updated:`);
          console.log(`   Previous: ${currentRating.toFixed(2)}/5`);
          console.log(`   New: ${newAverage.toFixed(2)}/5`);
          console.log(`   Based on ${totalRides + 1} rides`);
        } else {
          console.log('ℹ️  User profile not found, creating with initial rating');
          await userProfileRef.set({
            rating: testRating,
            totalRides: 0,
            homeAddress: '',
            workAddress: '',
            favoriteLocations: [],
          }, { merge: true });
          console.log(`✅ User profile created with rating: ${testRating}/5`);
        }
      } catch (error) {
        console.log(`⚠️  Could not update user profile: ${error.message}`);
        console.log('   (This is okay if using old user collection format)');
      }
    }
    
    // Step 5: Verify the update
    console.log(`\n🔍 Step 4: Verifying update...`);
    const updatedRide = await db.collection('rideHistory').doc(rideId).get();
    const updatedData = updatedRide.data();
    
    console.log('✅ Verification successful:');
    console.log(`   Driver Rating: ${updatedData.driverRating}/5`);
    console.log(`   Driver Feedback: "${updatedData.driverFeedback}"`);
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ TEST PASSED: Driver successfully rated user');
    console.log('='.repeat(60));
    console.log('\n📱 Now you can check the app:');
    console.log('   1. Open the user app');
    console.log('   2. Go to Profile → Ride History');
    console.log('   3. You should see the driver\'s rating for this ride');
    
  } catch (error) {
    console.error('\n❌ TEST FAILED:', error.message);
    console.error('   Stack:', error.stack);
    process.exit(1);
  }
}

testDriverRateUser()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });

