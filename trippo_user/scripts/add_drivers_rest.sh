#!/bin/bash
# Add drivers using Firebase REST API
# Uses access token from Firebase CLI

PROJECT_ID="btrips-42089"
COLLECTION="Drivers"

# Get access token from Firebase CLI
TOKEN=$(firebase login:ci --no-localhost 2>/dev/null | grep -o 'token.*' | cut -d' ' -f2 || firebase login:list 2>/dev/null | head -1)

if [ -z "$TOKEN" ]; then
    echo "⚠️  Note: Firebase CLI doesn't have direct Firestore write commands"
    echo ""
    echo "📋 Easiest method: Use Firebase Console"
    echo "   1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
    echo "   2. Add 'Drivers' collection (if needed)"
    echo "   3. Add documents (see scripts/add_drivers_via_console.md)"
    echo ""
    echo "OR use the Python script with a service account key"
    exit 0
fi

echo "Using REST API method..."
echo "This requires additional setup. Using Firebase Console is recommended."
echo "See: scripts/add_drivers_via_console.md"

