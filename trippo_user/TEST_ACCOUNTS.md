# Test Accounts for BTrips Unified App

**Date**: November 1, 2025  
**Status**: ✅ **READY FOR TESTING**

---

## 🧑 Passenger Account (Regular User)

```
Email:    zayed.albertyn@gmail.com
Password: (your existing password)
UID:      ULnMdQhgdagACWprIHNIxf5Z8qi2
Role:     user (passenger)
Status:   ✅ Active

Firestore Structure:
✅ users/ULnMdQhgdagACWprIHNIxf5Z8qi2
✅ userProfiles/ULnMdQhgdagACWprIHNIxf5Z8qi2
```

### Expected Flow:
1. Login → Splash → User Main (2 tabs)
2. **Ride Tab**: Map view, search, book rides
3. **Profile Tab**: View profile, edit contact info, settings

---

## 🚕 Driver Account (Test Driver)

```
Email:    driver@bt.com
Password: Test123!
UID:      Ol5Q7Q6btTOmHKTNFRQgYkvEikd2
Role:     driver
Status:   ✅ Active, Verified

Vehicle Details:
- Car Name: Toyota Camry
- Plate: TEST-123
- Type: Car
- Rate: 3.0
- Status: Offline (will be "Idle" when online)

Firestore Structure:
✅ users/Ol5Q7Q6btTOmHKTNFRQgYkvEikd2
✅ drivers/Ol5Q7Q6btTOmHKTNFRQgYkvEikd2
```

### Expected Flow:
1. Login → Splash → Driver Main (4 tabs)
2. **Home Tab**: Map with "Go Online" button
3. **Earnings Tab**: $0.00, 0 rides, 5.0 rating
4. **History Tab**: Empty (no rides yet)
5. **Profile Tab**: Driver info, edit contact, vehicle details

---

## 🧪 Testing Scenarios

### Test 1: Passenger Login ✅
```bash
1. Open app
2. Login with: zayed.albertyn@gmail.com
3. Should show: User Main (2 tabs)
4. Navigate to Profile tab
5. Try "Edit Contact Info"
6. Add phone and address
```

### Test 2: Driver Login ✅
```bash
1. Logout (if logged in)
2. Login with: driver@bt.com / Test123!
3. Should show: Driver Main (4 tabs)
4. Tap "Go Online" on Home tab
5. Should broadcast location to Firestore
6. Check Earnings tab (shows $0, 0 rides)
7. Check Profile tab (shows vehicle info)
```

### Test 3: Role Switching
```bash
1. Login as passenger
2. Logout
3. Login as driver
4. Verify correct UI shows for each role
5. Check that routes are protected (no cross-access)
```

### Test 4: New User Registration
```bash
1. Logout
2. Tap "Sign Up"
3. Choose "Passenger" role
4. Register with new email
5. Should navigate to User Main
```

### Test 5: New Driver Registration
```bash
1. Logout
2. Tap "Sign Up"
3. Choose "Driver" role
4. Register with new email
5. Should navigate to Driver Config
6. Fill in vehicle details
7. Should navigate to Driver Main
```

---

## 🔍 Firebase Console Links

### Authentication
- **Users List**: https://console.firebase.google.com/project/trippo-42089/authentication/users
- Should see both accounts

### Firestore Database
- **users collection**: https://console.firebase.google.com/project/trippo-42089/firestore/data/~2Fusers
- **userProfiles collection**: https://console.firebase.google.com/project/trippo-42089/firestore/data/~2FuserProfiles
- **drivers collection**: https://console.firebase.google.com/project/trippo-42089/firestore/data/~2Fdrivers

---

## 📱 Quick Commands

### Run the App
```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user
flutter run
```

### Clean Build (if needed)
```bash
flutter clean && flutter pub get && flutter run
```

### Create More Test Accounts
```bash
# Create another driver
node scripts/create_test_driver.js

# Fix existing account
node scripts/fix_firestore_structure.js <email>
```

---

## ✅ What to Verify

### For Passenger Account:
- ✅ Login works without hanging
- ✅ Navigates to User Main (2 tabs)
- ✅ Map loads on Ride tab
- ✅ Profile shows correct data
- ✅ Can edit contact info (phone + address)
- ✅ Can edit profile (name, photo)

### For Driver Account:
- ✅ Login works without hanging
- ✅ Navigates to Driver Main (4 tabs)
- ✅ Home tab shows map + "Go Online" button
- ✅ Tapping "Go Online" changes button to green "Online - Available"
- ✅ Location broadcasts to Firestore (check drivers/{uid}.driverLoc)
- ✅ Earnings tab shows stats (0 rides, $0, 5.0 rating)
- ✅ Profile shows vehicle info
- ✅ Can edit contact info (phone only)

---

## 🔧 Troubleshooting

### If Login Hangs:
```bash
# Run diagnostic
node scripts/diagnose_auth.js <email>

# Or fix the account
node scripts/fix_firestore_structure.js <email>
```

### If Wrong Screen Shows:
- Check Firestore: `users/{uid}.userType` field
- Should be "user" for passengers
- Should be "driver" for drivers

### If Driver Can't Go Online:
- Check location permissions
- Check Firestore rules
- Check console for errors

---

## 📊 Account Summary

| Email | Password | Role | UID | Status |
|-------|----------|------|-----|--------|
| zayed.albertyn@gmail.com | (your password) | user | ULnMdQhg... | ✅ Active |
| driver@bt.com | Test123! | driver | Ol5Q7Q6b... | ✅ Active |

---

## 🎯 Next Steps

1. ✅ Test passenger login
2. ✅ Test driver login
3. ✅ Try "Go Online" as driver
4. ✅ Test contact info editing (both roles)
5. ✅ Test navigation between tabs
6. ⏳ Create ride request (passenger)
7. ⏳ Accept ride (driver)
8. ⏳ Complete ride flow

---

## 🔐 Security Notes

**Test Account Passwords:**
- Driver test account uses simple password: `Test123!`
- Change this for production
- These are for testing only

**Firestore Access:**
- Currently using Firebase Admin SDK (full access)
- Deploy security rules before production
- Rules should restrict read/write by UID

---

**Status**: 🟢 **BOTH ACCOUNTS READY**  
**Last Updated**: November 1, 2025  
**Ready to Test**: ✅ YES


