# Admin Dashboard Testing Guide

**Date**: November 2, 2025  
**Admin Email**: zayed.albertyn@gmail.com  
**Status**: Ready for Testing

---

## 🔐 Pre-Test Checklist

### 1. Verify Admin User in Firebase

Go to **Firebase Console** → **Firestore Database** → **users** collection

Find your user document (the one with email: zayed.albertyn@gmail.com) and ensure it has:

```javascript
{
  userType: "admin",          // ⚠️ CRITICAL - Must be "admin"
  email: "zayed.albertyn@gmail.com",
  name: "Zayed Albertyn",     // Or your name
  phoneNumber: "",            // Can be empty
  homeAddress: "",            // Can be empty
  isActive: true,             // Must be true
  isVerified: true,           // Should be true
  isSuspended: false,         // Should be false
  createdAt: <Timestamp>,
  lastLogin: <Timestamp>,
  fcmToken: "",
  profileImageUrl: ""
}
```

**If `userType` is NOT "admin"**:
1. Click on your user document
2. Edit the `userType` field
3. Change it to: `admin`
4. Save

---

## 🚀 Running the App

### Option 1: Run on Web (Recommended for Admin)
```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user
flutter run -d chrome
```

### Option 2: Run on Android
```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user
flutter run
```

### Option 3: Run on iOS
```bash
cd /Users/azayed/aidev/trippobuckley/trippo_user
flutter run -d ios
```

---

## 🧪 Testing Checklist

### Test 1: Admin Login & Navigation ✅

**Steps**:
1. ⬜ App opens to splash screen
2. ⬜ Redirects to login (if not logged in)
3. ⬜ Login with: `zayed.albertyn@gmail.com`
4. ⬜ Should see splash screen animation
5. ⬜ **Should redirect to /admin** (not /home)
6. ⬜ See admin dashboard with:
   - AppBar: "BTrips Admin" with your email
   - Bottom navigation with 5 tabs
   - Drivers tab active by default

**Expected Debug Logs**:
```
✅ User data loaded:
   Email: zayed.albertyn@gmail.com
   UserType: UserType.admin
   isAdmin: true
🔐 User is an ADMIN, navigating to admin dashboard
```

**What to Check**:
- ✅ Bottom nav shows 5 tabs
- ✅ AppBar shows your email
- ✅ Logout button present
- ✅ Drivers tab is active

---

### Test 2: Drivers Management ✅

**Navigate to**: Already on Drivers tab

**Steps**:
1. ⬜ See statistics cards at top:
   - Total Drivers
   - Active Drivers
   - Inactive
   - Pending
2. ⬜ See search bar and action buttons
3. ⬜ If you have drivers, see them in table
4. ⬜ Try searching for a driver's name
5. ⬜ Click "View" icon (eye) on a driver
   - ⬜ Driver details dialog opens
   - ⬜ Shows email, phone, status, join date
   - ⬜ Click "Close"
6. ⬜ Click "Deactivate" icon (block) on an active driver
   - ⬜ Confirmation dialog opens
   - ⬜ Requires reason input
   - ⬜ Enter reason: "Testing deactivation"
   - ⬜ Click "Deactivate"
   - ⬜ See success message
   - ⬜ Driver status changes to "Inactive" (red badge)
7. ⬜ Check Firebase Console:
   - ⬜ `drivers/{uid}.isActive` should be `false`
   - ⬜ `users/{uid}.isActive` should be `false`
   - ⬜ `adminActions` collection should have new entry
8. ⬜ Click "Activate" icon (checkmark) on inactive driver
   - ⬜ Simple confirmation
   - ⬜ Click "Activate"
   - ⬜ Driver reactivated
9. ⬜ Click "Refresh" button
   - ⬜ See "Drivers list refreshed" message
   - ⬜ Data reloads

**What to Verify**:
- ✅ Stats update automatically
- ✅ Search filters in real-time
- ✅ Actions trigger confirmations
- ✅ Firebase updates correctly
- ✅ Audit logs created

---

### Test 3: Users Management ✅

**Navigate to**: Tap "Users" tab in bottom navigation

**Steps**:
1. ⬜ See statistics cards:
   - Total Users
   - Active Users
   - Inactive
   - New Users
2. ⬜ See users in data table
3. ⬜ Try searching for a user's name
4. ⬜ Click "View" icon (eye) on a user
   - ⬜ User details dialog opens
   - ⬜ Click "Close"

**Test Contact Info Editing** ⭐:
5. ⬜ Click "Edit" icon (pencil) on a user
   - ⬜ "Edit Contact Info" dialog opens
   - ⬜ Shows current phone number (if any)
   - ⬜ Shows current address (if any)
6. ⬜ Update phone: `+1-555-TEST-123`
7. ⬜ Update address: `123 Admin Test Street, Test City`
8. ⬜ Click "Save Changes"
   - ⬜ Dialog shows loading spinner
   - ⬜ Dialog closes
   - ⬜ See success message: "Contact info updated for [User Name]"
9. ⬜ Check Firebase Console:
   - ⬜ `users/{uid}.phoneNumber` = `+1-555-TEST-123`
   - ⬜ `userProfiles/{uid}.homeAddress` = `123 Admin Test Street, Test City`
   - ⬜ `adminActions` collection has 2 new entries:
     - `actionType: "update_user_phone"`
     - `actionType: "update_user_address"`

**Test Payment Methods** ⭐:
10. ⬜ Click "Credit Card" icon on a user
    - ⬜ "Payment Methods" dialog opens
    - ⬜ If user has no cards: Shows empty state
    - ⬜ If user has cards: Shows list with:
      - Card brand icon
      - Masked number (•••• 4242)
      - Expiry date
      - Cardholder name
      - Remove/Set Default buttons
    - ⬜ Click "Add Payment Method"
    - ⬜ See message: "Stripe integration will be added later"
    - ⬜ Click outside to close

**Test User Actions**:
11. ⬜ Click "Deactivate" on an active user
    - ⬜ Requires reason
    - ⬜ Enter: "Test user deactivation"
    - ⬜ Confirm
    - ⬜ User status → Inactive
12. ⬜ Click "Refresh" button
    - ⬜ Data reloads

**What to Verify**:
- ✅ Contact editing saves to Firebase
- ✅ Both users and userProfiles updated
- ✅ Audit logs created (2 entries)
- ✅ Payment methods dialog works
- ✅ Empty state shows correctly

---

### Test 4: Trips Analytics ✅ ⭐ NEW

**Navigate to**: Tap "Trips" tab in bottom navigation

**Steps**:
1. ⬜ See statistics cards:
   - Total Rides: [count]
   - Completed: [count] with revenue
   - Ongoing: [count]
   - Cancelled: [count]
2. ⬜ See trips in data table (if any rides exist)
3. ⬜ Try searching for a user email or location
4. ⬜ Click "View" icon on a trip
   - ⬜ Trip Details Dialog opens
   - ⬜ Shows:
     - Trip Information (ID, status, vehicle, timestamps)
     - Participants (user, driver, ratings)
     - Route (pickup, dropoff, distance, duration)
     - Pricing (fare)
   - ⬜ Click "Close"

**Test Analytics Dashboard** ⭐:
5. ⬜ Click "Analytics" button (changes from table view)
   - ⬜ View switches to analytics dashboard
   - ⬜ See **Pie Chart**: "Ride Status Distribution"
     - Shows completed (green)
     - Shows ongoing (blue)
     - Shows pending (amber)
     - Shows cancelled (red)
   - ⬜ See **Line Chart**: "Revenue Trend (Last 7 Days)"
     - Shows revenue by date
     - Blue line with gradient
     - Grid lines and labels
6. ⬜ Click "Show Table" button
   - ⬜ Returns to data table view
7. ⬜ Toggle back and forth a few times
8. ⬜ Click "Refresh" button

**What to Verify**:
- ✅ Statistics calculated correctly
- ✅ Charts display properly
- ✅ Pie chart shows correct proportions
- ✅ Line chart shows revenue trend
- ✅ Toggle between views works
- ✅ Search filters trips

---

### Test 5: Navigation & Logout ✅

**Steps**:
1. ⬜ Tap each bottom nav tab:
   - Drivers → Users → Trips → Accounts → Costs
2. ⬜ Each tab should load (Accounts & Costs are placeholders)
3. ⬜ Return to Drivers tab
4. ⬜ Click logout button in AppBar
   - ⬜ Confirmation dialog appears
   - ⬜ Click "Logout"
   - ⬜ Redirected to login screen
5. ⬜ Login again
   - ⬜ Should go directly to admin dashboard
   - ⬜ Should remember last tab (or default to Drivers)

**What to Verify**:
- ✅ All tabs accessible
- ✅ Logout requires confirmation
- ✅ Can login again
- ✅ Auto-redirects to admin

---

## 🎯 Expected Behavior

### On Login:
```
Login Screen
   ↓
Enter: zayed.albertyn@gmail.com + password
   ↓
Splash Screen (2 seconds)
   ↓
Debug log: "🔐 User is an ADMIN"
   ↓
Admin Dashboard (/admin)
```

### Admin Dashboard Should Show:
```
✅ AppBar: "BTrips Admin" + your email + logout button
✅ Stats cards with real numbers
✅ Search bar functional
✅ Action buttons clickable
✅ Data tables with real data
✅ Bottom navigation (5 tabs)
```

---

## 🐛 Troubleshooting

### Issue: Not Redirecting to Admin Dashboard

**Solution**:
1. Check Firebase Console → users collection
2. Find your document (with email: zayed.albertyn@gmail.com)
3. Verify `userType: "admin"` (NOT "user" or "driver")
4. Logout and login again

### Issue: No Drivers/Users Showing

**Cause**: No drivers/users exist in database

**Solution**:
1. This is normal if you haven't registered any drivers/users
2. You'll see empty state message
3. Register test accounts:
   - Open app in another browser/device
   - Register as "Driver" or "Passenger"
   - Return to admin dashboard
   - Refresh to see them

### Issue: No Trips Showing

**Cause**: No completed rides in database

**Solution**:
1. This is normal if no rides have been completed
2. Empty state will show
3. To test with data:
   - Complete a ride as user/driver
   - Return to admin Trips tab
   - Refresh to see the trip

### Issue: Charts Not Showing

**Cause**: No data or fl_chart not loaded

**Solution**:
1. Check that rides exist
2. Ensure flutter pub get ran successfully
3. Restart app after adding fl_chart

---

## 📊 Test Data Verification

### After Each Admin Action:

**Check Firebase Console**:
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Check relevant collections:

**For Driver Deactivation**:
```
drivers/{driver-uid}:
  └── isActive: false ✅

users/{driver-uid}:
  └── isActive: false ✅

adminActions/{action-id}:
  ├── actionType: "deactivate_driver"
  ├── adminEmail: "zayed.albertyn@gmail.com"
  ├── targetEmail: "driver@email.com"
  ├── reason: "Your entered reason"
  ├── previousState: { isActive: true }
  └── newState: { isActive: false }
```

**For Contact Info Update**:
```
users/{user-uid}:
  └── phoneNumber: "+1-555-TEST-123" ✅

userProfiles/{user-uid}:
  └── homeAddress: "123 Admin Test Street" ✅

adminActions (2 entries):
  Entry 1:
    ├── actionType: "update_user_phone"
    ├── previousState: { phoneNumber: "" }
    └── newState: { phoneNumber: "+1-555-TEST-123" }
  
  Entry 2:
    ├── actionType: "update_user_address"
    ├── previousState: { homeAddress: "" }
    └── newState: { homeAddress: "123 Admin Test Street" }
```

---

## 🎯 Feature Testing Matrix

| Feature | Tab | Test Steps | Expected Result |
|---------|-----|------------|-----------------|
| Admin login | - | Login with admin email | Redirects to /admin ✅ |
| Bottom nav | All | Tap each tab | Switches screens ✅ |
| Drivers list | Drivers | View table | Shows all drivers ✅ |
| Driver search | Drivers | Type name in search | Filters in real-time ✅ |
| Driver deactivate | Drivers | Click block icon | Requires reason, updates Firebase ✅ |
| Users list | Users | View table | Shows all users ✅ |
| User search | Users | Type name in search | Filters in real-time ✅ |
| **Edit contact** | Users | Click edit icon | **Opens dialog, saves to Firebase** ✅ |
| **View payments** | Users | Click card icon | **Shows payment methods** ✅ |
| User deactivate | Users | Click block icon | Requires reason, updates Firebase ✅ |
| Trips list | Trips | View table | Shows all rides ✅ |
| **Analytics charts** | Trips | Click "Analytics" | **Shows pie & line charts** ✅ |
| Trip details | Trips | Click view icon | Shows comprehensive info ✅ |
| Trip search | Trips | Type user email | Filters in real-time ✅ |
| Logout | All | Click logout | Confirmation, then logout ✅ |

---

## 🎬 Recommended Test Flow

### Full Test Sequence (15 minutes):

**Part 1: Login & Navigation (2 min)**
```
1. Run app
2. Login as admin
3. Verify redirect to /admin
4. Tap through all 5 tabs
5. Return to Drivers tab
```

**Part 2: Drivers Management (3 min)**
```
1. View driver statistics
2. Search for a driver
3. View driver details
4. Deactivate a driver (with reason)
5. Check Firebase for updates
6. Reactivate the driver
7. Refresh data
```

**Part 3: Users Management (5 min)** ⭐
```
1. Tap Users tab
2. View user statistics
3. Click "Edit" on a user
4. Update phone: +1-555-ADMIN-TEST
5. Update address: 123 Admin Test St
6. Save and verify success
7. Check Firebase Console:
   - users/{uid}.phoneNumber
   - userProfiles/{uid}.homeAddress
   - adminActions (2 new entries)
8. Click "Credit Card" icon on same user
9. View payment methods dialog
10. Close dialog
11. Deactivate user (with reason)
12. Reactivate user
```

**Part 4: Trips Analytics (5 min)** ⭐
```
1. Tap Trips tab
2. View trip statistics (revenue shown)
3. View trips in table
4. Click "View" on a trip
5. Review all trip details
6. Close dialog
7. Click "Analytics" button
8. View pie chart (status distribution)
9. View line chart (revenue trend)
10. Click "Show Table" to return
11. Try searching for a user email
12. Refresh data
```

**Part 5: Logout (1 min)**
```
1. Click logout button
2. Confirm logout
3. Verify redirect to login
```

---

## 📸 Screenshots to Capture

If testing visually, capture these:

1. ✅ Admin dashboard main screen (bottom nav visible)
2. ✅ Drivers tab with data table
3. ✅ Driver deactivate confirmation dialog
4. ✅ Users tab with data table
5. ✅ **Edit Contact Info dialog** ⭐
6. ✅ **Payment Methods dialog** ⭐
7. ✅ Trips tab with data table
8. ✅ **Analytics dashboard with charts** ⭐
9. ✅ Trip details dialog
10. ✅ Firebase Console showing audit logs

---

## 🔍 What to Look For

### Visual Quality ✅
- Professional dark blue theme
- Clean data tables
- Responsive design
- Smooth animations
- Color-coded status badges

### Functionality ✅
- All buttons clickable
- Dialogs open/close properly
- Forms submit successfully
- Search filters instantly
- Charts render correctly

### Data Integrity ✅
- Firebase updates correctly
- Audit logs created
- Statistics accurate
- Real-time sync working

### Error Handling ✅
- Loading states show
- Error messages clear
- Empty states helpful
- Confirmations work

---

## ⚠️ Known Limitations (Intentional)

### Placeholder Features:
- ❌ Delete operations (placeholder message)
- ❌ Export to CSV (placeholder message)
- ❌ Advanced filters (placeholder message)
- ❌ Bulk actions (not implemented yet)
- ❌ Stripe integration (deferred)
- ❌ Accounts tab (Phase 6)
- ❌ Costs tab (Phase 7)

### These Will Show Messages:
```
"Export feature coming soon"
"Filters coming in next update"
"Stripe integration will be added later"
"Delete functionality will be implemented later"
```

---

## ✅ Success Criteria

### Admin Dashboard Works If:

**Navigation**:
- ✅ Admin login redirects to /admin
- ✅ Bottom nav shows 5 tabs
- ✅ Can switch between tabs
- ✅ Logout works

**Drivers Tab**:
- ✅ Shows drivers in table
- ✅ Search filters data
- ✅ Can activate/deactivate
- ✅ Stats update

**Users Tab**:
- ✅ Shows users in table
- ✅ Search filters data
- ✅ **Edit contact info saves** ⭐
- ✅ **Payment methods dialog opens** ⭐
- ✅ Can activate/deactivate
- ✅ Stats update

**Trips Tab** ⭐:
- ✅ Shows trips in table
- ✅ Search filters data
- ✅ **Analytics button toggles to charts**
- ✅ **Pie chart displays**
- ✅ **Line chart displays**
- ✅ Stats show revenue

**Firebase**:
- ✅ User/driver status updates
- ✅ Contact info saves to both collections
- ✅ Audit logs created in adminActions
- ✅ All timestamps accurate

---

## 🎉 Testing Complete When:

- [ ] Admin login works
- [ ] All 5 tabs accessible
- [ ] Drivers management working
- [ ] Users management working
- [ ] Contact editing saves correctly
- [ ] Payment methods dialog displays
- [ ] Trips table shows data
- [ ] **Analytics charts render** ⭐
- [ ] Trip details comprehensive
- [ ] Search works on all tabs
- [ ] Firebase updates verified
- [ ] Audit logs created
- [ ] Logout works

---

## 📝 Notes

### For Best Testing Experience:
1. Test on **web** (Chrome) for best data table experience
2. Have **Firebase Console** open in another tab
3. Check **adminActions** collection after each action
4. Keep **Flutter logs** visible for debug messages

### If You Find Bugs:
1. Note the exact steps to reproduce
2. Check Flutter console for errors
3. Check Firebase Console for data state
4. Take screenshots if visual issue

---

**Ready to test!** 🚀

Run the app and follow the checklist above!

