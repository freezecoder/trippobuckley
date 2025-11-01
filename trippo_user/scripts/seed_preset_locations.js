#!/usr/bin/env node

/**
 * Script to seed preset locations into Firestore
 * 
 * This script populates the 'presetLocations' collection with initial
 * airport and popular destination data.
 * 
 * Usage: node scripts/seed_preset_locations.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '../firestore_credentials.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Preset locations data
const presetLocations = [
  {
    name: 'Newark Liberty Airport',
    placeId: '',
    latitude: 40.6895,
    longitude: -74.1745,
    category: 'airport',
    isActive: true,
    order: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    name: 'New York JFK Airport',
    placeId: '',
    latitude: 40.6413,
    longitude: -73.7781,
    category: 'airport',
    isActive: true,
    order: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    name: 'New York La Guardia',
    placeId: '',
    latitude: 40.7769,
    longitude: -73.8740,
    category: 'airport',
    isActive: true,
    order: 2,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    name: 'Philadelphia Airport',
    placeId: '',
    latitude: 39.8719,
    longitude: -75.2411,
    category: 'airport',
    isActive: true,
    order: 3,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function seedPresetLocations() {
  console.log('🌱 Starting preset locations seeding...\n');

  try {
    // Check if collection already has data
    const snapshot = await db.collection('presetLocations').limit(1).get();
    
    if (!snapshot.empty) {
      console.log('⚠️  Collection already has data. Do you want to:');
      console.log('   1. Skip seeding (keep existing data)');
      console.log('   2. Add new locations (merge with existing)');
      console.log('   3. Clear and reseed (delete all and add fresh)\n');
      
      // For now, we'll skip if data exists
      console.log('⏭️  Skipping seeding to preserve existing data.');
      console.log('   To force reseed, delete the collection first or modify this script.\n');
      return;
    }

    // Use batch for atomic writes
    const batch = db.batch();
    let count = 0;

    for (const location of presetLocations) {
      const docRef = db.collection('presetLocations').doc();
      batch.set(docRef, location);
      count++;
      console.log(`✓ Added: ${location.name} (${location.category})`);
    }

    await batch.commit();

    console.log(`\n✅ Successfully seeded ${count} preset locations!`);
    console.log('\n📍 Preset locations are now available in the app.');
    console.log('   Users can see them by tapping "Preset Locations" on the home screen.\n');

  } catch (error) {
    console.error('\n❌ Error seeding preset locations:', error);
    process.exit(1);
  }
}

// Additional utility functions

async function listPresetLocations() {
  console.log('\n📋 Current Preset Locations:\n');
  
  const snapshot = await db.collection('presetLocations')
    .orderBy('order')
    .get();

  if (snapshot.empty) {
    console.log('   (No locations found)\n');
    return;
  }

  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`   ${data.order + 1}. ${data.name}`);
    console.log(`      Category: ${data.category}`);
    console.log(`      Active: ${data.isActive}`);
    console.log(`      Coords: ${data.latitude}, ${data.longitude}`);
    console.log(`      ID: ${doc.id}\n`);
  });
}

async function clearPresetLocations() {
  console.log('\n🗑️  Clearing all preset locations...\n');
  
  const snapshot = await db.collection('presetLocations').get();
  const batch = db.batch();
  
  snapshot.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`✅ Deleted ${snapshot.size} preset locations.\n`);
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'seed':
      await seedPresetLocations();
      break;
    case 'list':
      await listPresetLocations();
      break;
    case 'clear':
      await clearPresetLocations();
      break;
    case 'reseed':
      await clearPresetLocations();
      await seedPresetLocations();
      break;
    default:
      // Default action is to seed
      await seedPresetLocations();
  }

  process.exit(0);
}

// Run the script
main();

