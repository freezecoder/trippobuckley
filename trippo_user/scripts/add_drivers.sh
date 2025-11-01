#!/bin/bash
# Script to add 4 drivers to Firestore using Firebase CLI
# 
# Prerequisites:
#   1. Install Firebase CLI: npm install -g firebase-tools
#   2. Login: firebase login
#   3. Select project: firebase use btrips-42089
#
# Run: ./scripts/add_drivers.sh

set -e  # Exit on error

PROJECT_ID="btrips-42089"
COLLECTION="Drivers"

echo "🚀 Adding 4 drivers to Firestore..."
echo "📋 Project: $PROJECT_ID"
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo ""
    echo "Install it with:"
    echo "  npm install -g firebase-tools"
    echo ""
    echo "Then login and select project:"
    echo "  firebase login"
    echo "  firebase use $PROJECT_ID"
    exit 1
fi

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase!"
    echo ""
    echo "Login with:"
    echo "  firebase login"
    exit 1
fi

# Function to add a driver
add_driver() {
    local email=$1
    local name=$2
    local car_name=$3
    local plate=$4
    local car_type=$5
    local lat=$6
    local lng=$7
    
    echo "📝 Adding: $name ($car_name)..."
    
    firebase firestore:set "$COLLECTION/$email" \
        "Car Name=$car_name" \
        "Car Plate Num=$plate" \
        "Car Type=$car_type" \
        "name=$name" \
        "email=$email" \
        "driverStatus=Idle" \
        "driverLoc.geopoint._latitude=$lat" \
        "driverLoc.geopoint._longitude=$lng" \
        --project "$PROJECT_ID" \
        --yes \
        > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Added: $name"
    else
        echo "❌ Failed to add: $name"
    fi
}

# Add 4 drivers
add_driver "ahmed.khan@driver.com" "Ahmed Khan" "Toyota Camry" "ABC-1234" "Car" 40.6895 -74.1745
add_driver "sara.ali@driver.com" "Sara Ali" "Honda Civic" "XYZ-5678" "Car" 40.6413 -73.7781
add_driver "mohammed.hassan@driver.com" "Mohammed Hassan" "Toyota RAV4" "SUV-9012" "SUV" 40.7769 -73.8740
add_driver "fatima.ahmed@driver.com" "Fatima Ahmed" "Yamaha R15" "MOT-3456" "MotorCycle" 39.8719 -75.2411

echo ""
echo "✨ Done! 4 drivers added to Firestore."
echo ""
echo "💡 Verify in Firebase Console:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/firestore"

