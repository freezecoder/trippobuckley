# Preset Locations - Quick Start 🚀

## 1. Deploy to Firebase (One-time setup)

```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user

# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

## 2. Seed Initial Data

```bash
# Add 4 default airports to Firestore
node scripts/seed_preset_locations.js
```

## 3. Test in App

```bash
flutter run
```

1. Open Home Screen
2. Tap "Preset Locations"
3. Should see 4 airports
4. Tap one → sets as destination

---

## ✅ That's It!

Now you can manage locations in Firebase Console without rebuilding the app.

---

## Add New Location (Firebase Console)

1. Go to Firestore → `presetLocations`
2. Click "Add Document"
3. Fill in:
   - `name`: "Times Square"
   - `latitude`: 40.7580
   - `longitude`: -73.9855
   - `category`: "landmark"
   - `isActive`: true
   - `order`: 4
   - `placeId`: ""
   - `createdAt`: [Use server timestamp]
4. Save

Location appears in app instantly! ⚡

---

## Useful Commands

```bash
# List all locations
node scripts/seed_preset_locations.js list

# Clear all
node scripts/seed_preset_locations.js clear

# Reseed
node scripts/seed_preset_locations.js reseed
```

---

## Categories & Icons

- `airport` → ✈️
- `station` → 🚂
- `landmark` → 📍

---

## Documentation

- **Full Guide**: `PRESET_LOCATIONS_GUIDE.md`
- **Migration Details**: `PRESET_LOCATIONS_MIGRATION.md`
- **This Quick Start**: `PRESET_LOCATIONS_QUICKSTART.md`

---

**Need help?** Read the full guide! 📖

