/**
 * Script to set a user as admin
 * Usage: node set_admin_user.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firestore_credentials.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setAdminUser(email) {
  try {
    console.log(`🔍 Looking for user with email: ${email}`);
    
    // Find user by email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', email)
      .get();
    
    if (usersSnapshot.empty) {
      console.log(`❌ No user found with email: ${email}`);
      console.log('   Please check the email address is correct');
      process.exit(1);
    }
    
    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    console.log(`✅ Found user: ${userData.name || 'No name'}`);
    console.log(`   Current userType: ${userData.userType}`);
    
    if (userData.userType === 'admin') {
      console.log('ℹ️  User is already an admin!');
      process.exit(0);
    }
    
    // Update to admin
    await db.collection('users').doc(userId).update({
      userType: 'admin',
      isActive: true,
      isVerified: true,
      isSuspended: false,
    });
    
    console.log('✅ User updated successfully!');
    console.log(`   userType: user → admin`);
    console.log(`   isActive: true`);
    console.log(`   isVerified: true`);
    console.log(`\n🎉 ${email} is now an admin!`);
    console.log('\n📝 Next steps:');
    console.log('   1. Restart your Flutter app (press R in terminal)');
    console.log('   2. Login with this email');
    console.log('   3. You should be redirected to /admin dashboard');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

// Run for your email
const adminEmail = 'zayed.albertyn@gmail.com';
setAdminUser(adminEmail);

