/**
 * One-time migration script to move completed deliveries to rideHistory
 * 
 * Run with: 
 *   cd trippo_user
 *   firebase firestore:get rideRequests --where 'isDelivery==true' --where 'status==completed'
 * 
 * Or use the Firebase Console to manually copy documents
 * 
 * This script uses Firebase Admin SDK
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials
// This works if you're running in Firebase environment or have GOOGLE_APPLICATION_CREDENTIALS set
try {
  admin.initializeApp({
    projectId: 'trippo-42089',
  });
} catch (e) {
  console.log('Using existing Firebase app');
}

const db = admin.firestore();

async function migrateCompletedDeliveries() {
  try {
    console.log('🔍 Searching for completed deliveries in rideRequests...');
    
    // Find all completed deliveries
    const completedDeliveries = await db.collection('rideRequests')
      .where('isDelivery', '==', true)
      .where('status', 'in', ['completed', 'cancelled'])
      .get();

    console.log(`📦 Found ${completedDeliveries.docs.length} completed/cancelled deliveries to migrate`);

    if (completedDeliveries.empty) {
      console.log('✅ No deliveries to migrate!');
      return;
    }

    let successCount = 0;
    let errorCount = 0;

    // Migrate each delivery
    for (const doc of completedDeliveries.docs) {
      try {
        const data = doc.data();
        
        console.log(`\n📝 Migrating delivery: ${doc.id}`);
        console.log(`   Category: ${data.deliveryCategory || 'N/A'}`);
        console.log(`   Status: ${data.status}`);
        console.log(`   User: ${data.userEmail}`);
        console.log(`   Fare: $${data.fare}`);

        // Check if already in history
        const historyDoc = await db.collection('rideHistory').doc(doc.id).get();
        
        if (historyDoc.exists) {
          console.log(`   ℹ️  Already in history - skipping`);
          continue;
        }

        // Copy to rideHistory
        await db.collection('rideHistory').doc(doc.id).set(data);
        
        console.log(`   ✅ Moved to rideHistory`);
        successCount++;

      } catch (error) {
        console.error(`   ❌ Error migrating ${doc.id}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n' + '='.repeat(50));
    console.log('📊 MIGRATION SUMMARY:');
    console.log(`   ✅ Successfully migrated: ${successCount}`);
    console.log(`   ❌ Failed: ${errorCount}`);
    console.log(`   📦 Total processed: ${completedDeliveries.docs.length}`);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    process.exit(0);
  }
}

// Run migration
migrateCompletedDeliveries();

