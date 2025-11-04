# Quick Test Guide - Profile Picture Upload

## 🧪 Easy Testing Methods

Since I can't directly run the app, here are **3 easy ways** you can test the Storage:

---

## Method 1: Quick App Test (Recommended - 2 minutes)

### Step 1: Run the App
```bash
cd /Users/azayed/aidev/btripsbuckley/btrips_user
flutter run
```

### Step 2: Login/Register
- If new: Choose "Passenger" role → Register
- If existing: Login with your account

### Step 3: Upload Profile Picture
1. Navigate to **Profile** tab (bottom navigation)
2. You'll see a large profile circle with a camera icon
3. **Tap the circle**
4. Modal appears with options:
   - 📷 Camera
   - 🖼️ Gallery
   - 🗑️ Remove Photo
5. Choose **Gallery**
6. Select any image from your device
7. Watch for:
   - ⏳ Loading spinner on camera badge
   - ✅ Success message: "Profile picture updated successfully!"
   - 🖼️ Image displays in the circle

### Step 4: Verify in Firebase
1. Open: https://console.firebase.google.com/project/btrips-42089/storage
2. Click **Files** tab
3. You should see:
   ```
   profile_pictures/
   └── {your-user-id}/
       └── profile.jpg (or .png)
   ```
4. Click the file → You'll see:
   - File size
   - Upload date
   - Download URL
   - Metadata

✅ **If you see the file = SUCCESS!**

---

## Method 2: Test Both Roles (5 minutes)

### Test User Profile Picture:
```bash
1. flutter run
2. Register as "Passenger"
3. Go to Profile → Tap picture → Upload
4. ✅ Verify upload works
```

### Test Driver Profile Picture + License Plate:
```bash
1. Logout (from Profile menu)
2. Register new account as "Driver"
3. Complete vehicle setup:
   - Car: "Toyota Camry"
   - Plate: "TEST-123"
   - Type: "Car"
4. Submit → Navigate to Driver Home
5. Go to Profile tab
6. Tap profile picture → Upload
7. ✅ Verify upload works
8. Tap "Edit Vehicle Information"
9. Change plate to "TEST-999"
10. Submit
11. ✅ Verify profile shows: "Plate: TEST-999"
```

---

## Method 3: Manual Firebase Console Check

### Check Storage Bucket Created:
1. Visit: https://console.firebase.google.com/project/btrips-42089/storage
2. Look for bucket: `gs://btrips-42089.appspot.com`
3. ✅ If you see the bucket = Storage is enabled

### Check Rules Deployed:
1. Same console → Click **Rules** tab
2. You should see our custom rules:
   ```javascript
   match /profile_pictures/{userId}/{fileName} {
     allow read: if isAuthenticated();
     allow write: if isAuthenticated() && isOwner(userId)...
   ```
3. ✅ If you see our rules = Rules deployed correctly

### Check Usage:
1. Same console → Click **Usage** tab
2. You'll see:
   - Storage used: 0 GB (until uploads happen)
   - Downloads: 0 (until images viewed)
   - Operations: 0 (until uploads happen)

---

## 🐛 Troubleshooting

### Issue: "Upload failed: Permission denied"
**Check**:
```bash
cd /Users/azayed/aidev/btripsbuckley/btrips_user
firebase deploy --only storage
```
Should show: ✔ Deploy complete!

### Issue: "Network error"
**Check**:
- Internet connection working?
- Firebase project accessible?
- Run: `flutter doctor -v` (check for issues)

### Issue: Image uploads but doesn't show
**Check**:
1. Open app logs in terminal
2. Look for error: "Failed to load network image"
3. Verify URL in Firestore:
   - Console → Firestore → users/{userId}
   - Field: profileImageUrl should have "https://..."

### Issue: "Storage bucket not found"
**Solution**: Storage not enabled yet
- Visit: https://console.firebase.google.com/project/btrips-42089/storage
- Click "Get Started"

---

## ✅ Success Checklist

After testing, verify:

- [ ] User can upload profile picture
- [ ] Picture displays in User profile
- [ ] Driver can upload profile picture  
- [ ] Picture displays in Driver profile
- [ ] Driver can edit license plate
- [ ] New plate shows in profile: "Plate: ABC-1234"
- [ ] File appears in Firebase Storage console
- [ ] File has correct path: `profile_pictures/{userId}/profile.{ext}`
- [ ] Download URL works (click file in console → copy URL → paste in browser)
- [ ] Removing picture works (tap picture → Remove Photo)
- [ ] After removal, default avatar shows (first letter)

---

## 📊 Expected Results

### In App:
```
Before Upload:
┌─────────┐
│         │
│    J    │  ← Initial letter avatar
│         │
└─────────┘

After Upload:
┌─────────┐
│         │
│  [IMG]  │  ← Actual photo
│         │
└─────────┘
    📷       ← Camera badge (tap to change)
```

### In Firebase Console (Storage → Files):
```
profile_pictures/
├── abc123def456/          ← User 1
│   └── profile.jpg        (245 KB, uploaded 1 min ago)
└── xyz789ghi012/          ← User 2
    └── profile.png        (189 KB, uploaded 2 min ago)
```

### In Firestore (users collection):
```javascript
users/abc123def456
{
  name: "John Doe",
  email: "john@example.com",
  profileImageUrl: "https://firebasestorage.googleapis.com/v0/b/btrips-42089.appspot.com/o/profile_pictures%2Fabc123def456%2Fprofile.jpg?alt=media&token=..."
}
```

---

## 🎯 Quick 30-Second Test

**Fastest way to verify everything works:**

```bash
# 1. Run app (10 sec)
flutter run

# 2. Login/Register (10 sec)
tap "Login" or "Join BTrips"

# 3. Upload picture (10 sec)
Profile tab → Tap circle → Gallery → Select image

# 4. Verify (instantly)
✅ Image shows in app
✅ Success message displayed
```

Then check Firebase:
https://console.firebase.google.com/project/btrips-42089/storage/btrips-42089.appspot.com/files

✅ **If you see `profile_pictures/{userId}/profile.jpg` = WORKING!**

---

## 📸 What to Upload

**Test Images**:
- Any photo from your device
- Screenshot works fine
- Size < 5MB (our limit)
- Format: jpg, png, or webp

**For Best Results**:
- Square image (looks best in circle)
- Clear photo (recognizable face/avatar)
- Good lighting
- 500x500px or larger

---

## 🎉 Expected Behavior

### Upload Flow:
```
1. Tap profile circle
   ↓
2. Modal shows options
   ↓
3. Tap "Gallery"
   ↓
4. Image picker opens
   ↓
5. Select image
   ↓
6. Modal closes
   ↓
7. Loading spinner shows (on camera badge)
   ↓
8. Upload completes (2-5 seconds)
   ↓
9. Success SnackBar: "Profile picture updated successfully!"
   ↓
10. Image displays in circle
   ↓
11. ✅ DONE!
```

### What Happens Behind the Scenes:
```
1. Image picked → XFile created
2. Image compressed → 1024x1024px, 85% quality
3. Uploaded to: profile_pictures/{userId}/profile.{ext}
4. Download URL received
5. URL saved to Firestore: users/{userId}.profileImageUrl
6. Provider refreshes
7. UI updates with new image
```

---

## 🔍 Verification Commands

### Check Firebase CLI:
```bash
firebase projects:list
# Should show: btrips-42089

firebase use
# Should show: Active Project: btrips-42089 (btrips)
```

### Check Flutter:
```bash
flutter doctor
# All checkmarks? ✅ Ready!

flutter devices
# Shows available devices/simulators
```

### Check Storage Rules:
```bash
cd /Users/azayed/aidev/btripsbuckley/btrips_user
cat storage.rules
# Should show our custom rules
```

---

## 💡 Pro Tips

1. **Test on Real Device**: Camera works better on physical device
2. **Test Both Roles**: Make sure both User and Driver profiles work
3. **Test Remove**: Verify removing picture works too
4. **Check Console**: Always verify file uploaded in Firebase Console
5. **Test Network**: Try on WiFi and cellular data

---

## 📞 Quick Links

- **Storage Console**: https://console.firebase.google.com/project/btrips-42089/storage
- **Firestore Console**: https://console.firebase.google.com/project/btrips-42089/firestore
- **Authentication Console**: https://console.firebase.google.com/project/btrips-42089/authentication

---

## ✅ Final Verification

Run this checklist after testing:

```
✅ App runs without errors
✅ Can login/register
✅ Profile screen shows picture circle
✅ Can tap circle to upload
✅ Modal shows (Camera/Gallery/Remove)
✅ Image picker opens
✅ Can select image
✅ Loading indicator shows
✅ Success message displays
✅ Image shows in circle
✅ File appears in Firebase Storage console
✅ URL saved in Firestore
✅ Can remove picture
✅ Default avatar shows after removal
```

**All checked?** 🎉 **FULLY WORKING!**

---

**Ready to test? Just run: `flutter run`** 🚀

