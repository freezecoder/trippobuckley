# Admin Role Specification - BTrips Management Portal

**Date**: November 2, 2025  
**Version**: 1.0.0  
**Status**: 📋 **SPECIFICATION PHASE**  
**Target Implementation**: Version 2.1.0+1

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Admin Architecture](#admin-architecture)
3. [Firebase Schema Changes](#firebase-schema-changes)
4. [Security & Access Control](#security--access-control)
5. [Admin Dashboard Features](#admin-dashboard-features)
6. [UI/UX Design](#uiux-design)
7. [Implementation Plan](#implementation-plan)
8. [Technical Requirements](#technical-requirements)
9. [Testing Strategy](#testing-strategy)
10. [Deployment Checklist](#deployment-checklist)

---

## 🎯 Overview

### Purpose
Create a comprehensive admin management portal within the BTrips unified app that allows super administrators to manage drivers, users, trips, accounts, and costs.

### Super Admin
- **Email**: `zayed.albertyn@gmail.com`
- **Role**: `admin` (UserType enum extension)
- **Access Level**: Full system access
- **Assignment**: Manual database assignment (not available through UI registration)

### Key Objectives
1. ✅ Centralized management dashboard
2. ✅ Driver lifecycle management (activate/deactivate/delete)
3. ✅ User lifecycle management (activate/deactivate/delete)
4. ✅ **Admin can edit user contact information** (phone, address) ⭐ NEW
5. ✅ **Admin can manage payment methods** (view, add, remove cards) ⭐ NEW
6. ✅ Comprehensive trip analytics and monitoring
7. ✅ Account management and verification
8. ✅ Cost analysis and revenue tracking
9. ✅ **Stripe integration for secure payment processing** ⭐ NEW
10. ✅ Secure, admin-only access with proper authorization

### 🆕 Version 1.1.0 Updates (November 2, 2025)

This version adds **admin capabilities to manage user contact information and payment methods**:

#### New Admin Powers
1. **Edit User Contact Info**
   - Update phone numbers
   - Update home addresses
   - Changes logged in audit trail

2. **Manage Payment Methods**
   - View all saved cards (masked: •••• 4242)
   - Add new cards via Stripe tokenization
   - Remove or deactivate payment methods
   - Set default payment method
   - **Security**: Only stores Stripe tokens + last 4 digits
   - **Never stores**: Full card numbers, CVV, or PINs

3. **Stripe Integration**
   - Secure card tokenization (PCI compliant)
   - Test mode for development
   - Future: Automated ride payments
   - Comprehensive setup guide included

#### Schema Updates
- Enhanced `users` collection with editable fields
- Enhanced `userProfiles` collection with `paymentMethods` array
- New payment-related audit action types
- Updated security rules for admin access

#### Implementation Changes
- Phase 4 extended with contact/payment features
- New widgets: `edit_contact_info_dialog`, `payment_methods_dialog`
- New model: `payment_method_model`
- New dependencies: `flutter_stripe`, `stripe_platform_interface`
- Timeline extended: 8-9 weeks (was 7-8 weeks)

---

## 🏗️ Admin Architecture

### Role Hierarchy
```
System Roles:
├── user (passenger)      → Can book rides
├── driver                → Can accept rides and earn
└── admin (super user)    → Can manage everything ⭐ NEW
```

### Access Model
```
Admin Can:
✅ View all users, drivers, and rides
✅ Modify user/driver status (active/inactive)
✅ Edit user contact information (phone, address) ⭐ UPDATED
✅ Manage user payment methods (view, add, remove) ⭐ NEW
✅ Delete users/drivers (soft delete with confirmation)
✅ View detailed trip analytics
✅ Access financial reports
✅ Verify driver documents
✅ Manage platform costs and pricing
✅ Export data for analysis

Admin Cannot:
❌ Book rides as a passenger
❌ Accept rides as a driver
❌ Modify ride history (read-only for audit)
❌ Change other admins (only super admin can)
❌ View full credit card numbers (only last 4 digits, expiry) ⭐ NEW
```

### Navigation Structure
```
Admin Main Screen (5 tabs):
├── 1. Drivers Tab      → Driver management
├── 2. Users Tab        → User management  
├── 3. Trips Tab        → Trip monitoring
├── 4. Accounts Tab     → Account verification
└── 5. Costs Tab        → Financial analytics
```

---

## 🔥 Firebase Schema Changes

### 1. Update UserType Enum
```dart
// lib/core/enums/user_type.dart
enum UserType {
  user,     // Regular passenger
  driver,   // Driver
  admin;    // Administrator ⭐ NEW
  
  String toFirestore() {
    switch (this) {
      case UserType.user:
        return 'user';
      case UserType.driver:
        return 'driver';
      case UserType.admin:
        return 'admin';
    }
  }
  
  static UserType fromFirestore(String value) {
    switch (value) {
      case 'user':
        return UserType.user;
      case 'driver':
        return UserType.driver;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.user;
    }
  }
}
```

### 2. Users Collection (Enhanced)
```javascript
users/                                    
  {userId}/
    ├── userType: "user" | "driver" | "admin"  ⭐ UPDATED
    ├── email: string
    ├── name: string
    ├── phoneNumber: string                    ⭐ Admin editable
    ├── homeAddress: string                    ⭐ Admin editable
    ├── isActive: boolean                      ⭐ KEY for management
    ├── isVerified: boolean                    ⭐ NEW
    ├── isSuspended: boolean                   ⭐ NEW
    ├── suspendedReason: string                ⭐ NEW
    ├── suspendedAt: Timestamp                 ⭐ NEW
    ├── suspendedBy: string (adminId)          ⭐ NEW
    ├── createdAt: Timestamp
    ├── lastLogin: Timestamp
    ├── fcmToken: string
    ├── profileImageUrl: string
    └── metadata: {                            ⭐ NEW
        totalLogins: number
        lastActivity: Timestamp
        deviceInfo: string
        ipAddress: string (last known)
      }
```

### 3. UserProfiles Collection (Enhanced for Payments) ⭐ UPDATED
```javascript
userProfiles/                   ⭐ User-specific data
  {userId}/
    ├── homeAddress: string                    ⭐ Admin editable
    ├── workAddress: string                    // Future feature
    ├── favoriteLocations: []                  // Saved places
    ├── preferences: {}                        // App settings
    ├── totalRides: number                     // Rides taken
    ├── rating: number                         // User rating
    └── paymentMethods: [                      ⭐ Admin manageable
        {
          id: string                           // Unique payment method ID
          type: "card" | "cash" | "wallet"     // Payment type
          isDefault: boolean                   // Default payment method
          
          // For credit/debit cards (Stripe tokenized):
          last4: string                        // Last 4 digits (e.g., "4242")
          brand: string                        // "Visa", "Mastercard", etc.
          expiryMonth: string                  // "12"
          expiryYear: string                   // "2025"
          cardholderName: string               // Name on card
          stripePaymentMethodId: string        ⭐ Stripe token (NOT full card)
          
          // Metadata:
          addedAt: Timestamp                   // When card was added
          addedBy: string                      // "user" | "admin"
          lastUsedAt: Timestamp                // Last transaction
          isActive: boolean                    // Can be deactivated by admin
        }
      ]
```

**Security Note**: 
- ❌ NEVER store full card numbers, CVV, or PIN
- ✅ Store only Stripe payment method tokens
- ✅ Store last 4 digits, brand, expiry for display
- ✅ Admins can view/add/remove payment methods
- ✅ All card additions will use Stripe tokenization

### 4. Drivers Collection (Enhanced)
```javascript
drivers/                        
  {userId}/
    ├── carName: string
    ├── carPlateNum: string
    ├── carType: string
    ├── rate: number
    ├── driverStatus: "Offline"|"Idle"|"Busy"
    ├── driverLoc: GeoPoint
    ├── geohash: string
    ├── rating: number
    ├── totalRides: number
    ├── earnings: number
    ├── isVerified: boolean                    ⭐ Admin approval
    ├── isActive: boolean                      ⭐ Admin control
    ├── isSuspended: boolean                   ⭐ NEW
    ├── suspendedReason: string                ⭐ NEW
    ├── verificationStatus: string             ⭐ NEW
    │   // "pending" | "approved" | "rejected"
    ├── verifiedBy: string (adminId)           ⭐ NEW
    ├── verifiedAt: Timestamp                  ⭐ NEW
    ├── documents: {                           ⭐ NEW
    │   license: {
    │     url: string
    │     uploadedAt: Timestamp
    │     verifiedAt: Timestamp
    │     status: "pending"|"approved"|"rejected"
    │   }
    │   insurance: { ... }
    │   registration: { ... }
    │ }
    └── stats: {                               ⭐ NEW
        totalOnlineHours: number
        acceptanceRate: number
        cancellationRate: number
        avgRating: number
        last30DaysRides: number
      }
```

### 4. RideRequests Collection (Enhanced for Analytics)
```javascript
rideRequests/                   
  {rideId}/
    ├── userId: string
    ├── driverId: string
    ├── status: string
    ├── pickup: { lat, lng, address }
    ├── dropoff: { lat, lng, address }
    ├── fare: number
    ├── distance: number (km)
    ├── estimatedDuration: number (minutes)
    ├── actualDuration: number (minutes)       ⭐ NEW
    ├── vehicleType: string
    ├── requestedAt: Timestamp
    ├── acceptedAt: Timestamp
    ├── startedAt: Timestamp
    ├── completedAt: Timestamp
    ├── cancelledAt: Timestamp
    ├── cancelledBy: "user"|"driver"|"admin"   ⭐ NEW
    ├── cancellationReason: string             ⭐ NEW
    ├── paymentMethod: string                  ⭐ NEW
    ├── paymentStatus: "pending"|"paid"|"refunded" ⭐ NEW
    └── flagged: boolean                       ⭐ NEW (for admin review)
```

### 6. New Collection: Admin Actions (Audit Log)
```javascript
adminActions/                   ⭐ NEW COLLECTION
  {actionId}/
    ├── adminId: string
    ├── adminEmail: string
    ├── actionType: string
    │   // User/Driver Management:
    │   // "activate_user" | "deactivate_user" | "delete_user"
    │   // "activate_driver" | "deactivate_driver" | "delete_driver"
    │   // "verify_driver" | "suspend_account"
    │   // 
    │   // Contact Information: ⭐ NEW
    │   // "update_user_phone" | "update_user_address"
    │   //
    │   // Payment Methods: ⭐ NEW
    │   // "add_payment_method" | "remove_payment_method"
    │   // "deactivate_payment_method" | "set_default_payment_method"
    ├── targetType: "user" | "driver" | "ride" | "payment"  ⭐ UPDATED
    ├── targetId: string
    ├── targetEmail: string
    ├── targetName: string
    ├── reason: string
    ├── previousState: object (JSON)
    ├── newState: object (JSON)
    ├── timestamp: Timestamp
    └── metadata: {
        ipAddress: string
        deviceInfo: string
      }
```

### 7. New Collection: Platform Analytics (Cached Data)
```javascript
platformAnalytics/              ⭐ NEW COLLECTION
  daily/
    {date: YYYY-MM-DD}/
      ├── totalRides: number
      ├── totalRevenue: number
      ├── totalDriverEarnings: number
      ├── platformCommission: number
      ├── activeUsers: number
      ├── activeDrivers: number
      ├── newUsers: number
      ├── newDrivers: number
      ├── avgRideDistance: number
      ├── avgRideDuration: number
      ├── avgFare: number
      ├── cancelledRides: number
      ├── completedRides: number
      └── updatedAt: Timestamp
  
  monthly/
    {date: YYYY-MM}/
      ├── ... (aggregated monthly data)
```

---

## 🛡️ Security & Access Control

### Firestore Security Rules (Admin)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function: Check if user is admin
    function isAdmin() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin' &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isActive == true;
    }
    
    // Helper function: Check if user is super admin
    function isSuperAdmin() {
      return request.auth != null &&
             request.auth.token.email == 'zayed.albertyn@gmail.com' &&
             isAdmin();
    }
    
    // Users collection
    match /users/{userId} {
      // Admins can read all users
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || isAdmin());
      
      // Only super admin can modify admin users
      allow write: if request.auth.uid == userId ||
                      (isAdmin() && 
                       (!('userType' in resource.data) || 
                        resource.data.userType != 'admin' ||
                        isSuperAdmin()));
    }
    
    // Drivers collection
    match /drivers/{driverId} {
      // Admins can read all drivers
      allow read: if request.auth != null && 
                     (request.auth.uid == driverId || isAdmin());
      
      // Admins can update driver status/verification
      allow write: if request.auth.uid == driverId || isAdmin();
    }
    
    // User profiles (including payment methods) ⭐ NEW
    match /userProfiles/{userId} {
      // Admins can read all user profiles
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || isAdmin());
      
      // Users can update their own profiles
      // Admins can update any profile (address, payment methods)
      allow write: if request.auth != null &&
                      (request.auth.uid == userId || isAdmin());
    }
    
    // Ride requests
    match /rideRequests/{rideId} {
      // Admins can read all rides
      allow read: if request.auth != null &&
                     (resource.data.userId == request.auth.uid ||
                      resource.data.driverId == request.auth.uid ||
                      isAdmin());
      
      // Admins can flag/update rides
      allow write: if request.auth != null &&
                      (resource.data.userId == request.auth.uid ||
                       resource.data.driverId == request.auth.uid ||
                       isAdmin());
    }
    
    // Admin actions (audit log)
    match /adminActions/{actionId} {
      // Only admins can read audit logs
      allow read: if isAdmin();
      
      // Only admins can create audit logs (auto-created by functions)
      allow create: if isAdmin();
      
      // Never allow updates or deletes (immutable audit log)
      allow update, delete: if false;
    }
    
    // Platform analytics
    match /platformAnalytics/{category}/{date} {
      // Only admins can read analytics
      allow read: if isAdmin();
      
      // Only super admin or cloud functions can write
      allow write: if isSuperAdmin();
    }
  }
}
```

### Route Protection (Go Router)

```dart
// lib/routes/app_router.dart

GoRoute(
  path: '/admin',
  redirect: (context, state) {
    final user = ref.read(currentUserProvider);
    if (user == null) return '/login';
    if (!user.isAdmin) return '/'; // Redirect non-admins
    return null;
  },
  builder: (context, state) => const AdminMainScreen(),
  routes: [
    GoRoute(
      path: 'drivers',
      builder: (context, state) => const AdminDriversScreen(),
    ),
    GoRoute(
      path: 'users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: 'trips',
      builder: (context, state) => const AdminTripsScreen(),
    ),
    GoRoute(
      path: 'accounts',
      builder: (context, state) => const AdminAccountsScreen(),
    ),
    GoRoute(
      path: 'costs',
      builder: (context, state) => const AdminCostsScreen(),
    ),
  ],
),
```

---

## 📊 Admin Dashboard Features

### Tab 1: Drivers Management

#### Features
1. **Driver List View**
   - Paginated list of all drivers
   - Search by name, email, plate number
   - Filter by:
     - Status (Active, Inactive, Suspended)
     - Verification Status (Pending, Approved, Rejected)
     - Vehicle Type (Car, SUV, Motorcycle)
     - Online Status (Online, Offline)
     - Rating (1-5 stars)
   - Sort by:
     - Name, Email, Join Date
     - Total Rides, Earnings, Rating
   
2. **Driver Actions**
   - ✅ Activate Driver
   - ❌ Deactivate Driver
   - 🚫 Suspend Driver (with reason)
   - 🗑️ Delete Driver (soft delete with confirmation)
   - ✅ Verify Driver (approve documents)
   - 👁️ View Driver Details
   - 📄 View Document Verification

3. **Driver Details View**
   - Personal Information
     - Name, Email, Phone
     - Join Date, Last Active
   - Vehicle Information
     - Car Name, Plate Number, Type
   - Statistics
     - Total Rides, Total Earnings
     - Average Rating, Acceptance Rate
     - Cancellation Rate, Total Online Hours
   - Documents
     - License (image, status)
     - Insurance (image, status)
     - Registration (image, status)
   - Recent Activity
     - Last 10 rides
     - Status changes
     - Earnings history

4. **Bulk Actions**
   - Select multiple drivers
   - Bulk activate/deactivate
   - Export driver data (CSV)

#### UI Components
```
Drivers Screen:
├── Search Bar (with filters)
├── Stats Cards
│   ├── Total Drivers
│   ├── Active Drivers
│   ├── Pending Verification
│   └── Suspended Drivers
├── Data Table
│   ├── Columns: Photo, Name, Email, Vehicle, Status, Rating, Actions
│   └── Pagination (20 per page)
└── Action Buttons
    ├── Add Driver (manual)
    ├── Export Data
    └── Refresh
```

---

### Tab 2: Users Management

#### Features
1. **User List View**
   - Paginated list of all users (passengers)
   - Search by name, email, phone
   - Filter by:
     - Status (Active, Inactive, Suspended)
     - Verification Status
     - Join Date Range
   - Sort by:
     - Name, Email, Join Date
     - Total Rides, Last Active

2. **User Actions**
   - ✅ Activate User
   - ❌ Deactivate User
   - 🚫 Suspend User (with reason)
   - 🗑️ Delete User (soft delete with confirmation)
   - 👁️ View User Details
   - ✏️ Edit Contact Information (phone, address) ⭐ NEW
   - 💳 Manage Payment Methods (view, add, remove) ⭐ NEW
   - 📧 Send Notification

3. **User Details View**
   - Personal Information
     - Name, Email, Phone ⭐ Admin editable
     - Home Address ⭐ Admin editable
     - Join Date, Last Active
     - Edit Button → Opens contact info dialog
   - Statistics
     - Total Rides
     - Total Spent
     - Average Rating Given
   - Payment Methods ⭐ Admin manageable
     - Saved cards (masked)
     - Display: •••• 4242 | Visa | Exp: 12/25
     - Actions: Remove, Set Default, Deactivate
     - Add New Card Button (via Stripe)
   - Recent Activity
     - Last 10 rides
     - Recent searches
   - Favorites
     - Saved locations

4. **Edit Contact Information Dialog** ⭐ NEW
   - Form Fields:
     - Phone Number (with validation)
     - Home Address (multi-line text)
   - Actions:
     - Save (updates users/{uid} and userProfiles/{uid})
     - Cancel
   - Audit logged: "update_user_phone" or "update_user_address"

5. **Manage Payment Methods Dialog** ⭐ NEW
   - List existing payment methods:
     - Card brand icon (Visa, Mastercard, etc.)
     - Last 4 digits
     - Expiry date
     - Cardholder name
     - Default indicator
     - Active/Inactive status
     - Actions: Remove, Set Default, Deactivate
   - Add New Payment Method:
     - Stripe Elements integration
     - Cardholder name input
     - Card details (tokenized by Stripe)
     - Save button → Creates Stripe payment method → Saves token
   - Security:
     - Never shows full card number
     - Only stores Stripe token + display info
     - All changes audit logged

6. **Bulk Actions**
   - Select multiple users
   - Bulk activate/deactivate
   - Export user data (CSV)
   - Send bulk notifications

#### UI Components
```
Users Screen:
├── Search Bar (with filters)
├── Stats Cards
│   ├── Total Users
│   ├── Active Users
│   ├── New Users (This Month)
│   └── Suspended Users
├── Data Table
│   ├── Columns: Photo, Name, Email, Phone, Status, Total Rides, Actions
│   └── Pagination (20 per page)
└── Action Buttons
    ├── Export Data
    ├── Send Notification
    └── Refresh
```

---

### Tab 3: Trips Management

#### Features
1. **Trips Overview**
   - All rides (pending, ongoing, completed, cancelled)
   - Real-time updates
   - Search by:
     - Ride ID
     - User/Driver name or email
     - Date range
     - Pickup/Dropoff location
   - Filter by:
     - Status (All, Pending, Ongoing, Completed, Cancelled)
     - Vehicle Type
     - Date Range (Today, This Week, This Month, Custom)
     - Flagged Rides
   - Sort by:
     - Date, Fare, Distance, Duration, Status

2. **Trip Details View**
   - Ride Information
     - Ride ID, Status, Vehicle Type
     - Pickup & Dropoff (with map view)
     - Distance, Duration (estimated vs actual)
   - Participants
     - User (name, photo, rating)
     - Driver (name, photo, rating)
   - Pricing Breakdown
     - Base Fare
     - Distance Charge
     - Time Charge
     - Surge Multiplier (if any)
     - Total Fare
     - Driver Earnings
     - Platform Commission
   - Timeline
     - Requested At
     - Accepted At
     - Started At
     - Completed At
   - Additional Info
     - Payment Method
     - Payment Status
     - Cancellation Info (if applicable)

3. **Analytics Dashboard**
   - Key Metrics
     - Total Rides (All Time, Today, This Week, This Month)
     - Total Revenue
     - Average Fare
     - Average Distance
     - Average Duration
     - Cancellation Rate
   - Charts
     - Rides Over Time (line chart)
     - Revenue Over Time (line chart)
     - Status Distribution (pie chart)
     - Peak Hours (bar chart)
     - Popular Routes (heatmap)
   - Filters
     - Date Range Selector
     - Vehicle Type Filter
     - Export Chart Data

4. **Flagged Rides**
   - Rides flagged for review
   - Reasons:
     - Unusually high fare
     - Very long duration
     - User/Driver complaint
     - Fraud detection
   - Actions:
     - Review & Clear Flag
     - Refund User
     - Suspend Driver/User
     - Add to Audit Log

#### UI Components
```
Trips Screen:
├── Analytics Dashboard (top section)
│   ├── Metric Cards (6 cards)
│   ├── Charts (3 charts)
│   └── Date Range Selector
├── Search & Filter Bar
├── Data Table
│   ├── Columns: ID, Date/Time, User, Driver, Route, Fare, Status, Actions
│   └── Pagination (20 per page)
└── Action Buttons
    ├── Export Data
    ├── View Flagged
    └── Refresh
```

---

### Tab 4: Accounts Management

#### Features
1. **Account Verification**
   - Pending Verifications
     - New driver applications
     - Document uploads
     - Identity verification
   - Quick Actions
     - Approve All Documents
     - Reject with Reason
     - Request More Info

2. **User Accounts**
   - Total Accounts Overview
   - Account Status Distribution
   - Recent Registrations
   - Suspended Accounts

3. **Driver Accounts**
   - Driver Verification Queue
   - Document Verification Status
   - Background Check Status (future)
   - Active/Inactive Breakdown

4. **Bulk Operations**
   - Bulk Verify Drivers
   - Bulk Account Status Changes
   - Batch Notifications

5. **Account Settings**
   - Global Account Rules
     - Auto-suspend after X complaints
     - Auto-deactivate after X days inactive
     - Verification requirements
   - Admin Management
     - View All Admins (super admin only)
     - Add New Admin (super admin only)
     - Remove Admin (super admin only)

#### UI Components
```
Accounts Screen:
├── Verification Queue (top section)
│   ├── Pending Count Badge
│   ├── Quick Approve/Reject Actions
│   └── Document Gallery
├── Stats Cards
│   ├── Total Accounts
│   ├── Active Accounts
│   ├── Pending Verification
│   └── Suspended Accounts
├── Tabs
│   ├── User Accounts
│   ├── Driver Accounts
│   └── Admin Management (super admin only)
└── Settings Panel
    └── Account Rules Configuration
```

---

### Tab 5: Costs & Revenue Management

#### Features
1. **Revenue Overview**
   - Total Revenue (All Time, This Month, This Week, Today)
   - Revenue Breakdown
     - User Payments
     - Driver Earnings
     - Platform Commission
   - Revenue Charts
     - Daily Revenue (line chart)
     - Monthly Comparison (bar chart)
     - Revenue by Vehicle Type (pie chart)

2. **Cost Analysis**
   - Driver Earnings
     - Total Paid to Drivers
     - Average Earnings per Driver
     - Top Earning Drivers
   - Platform Costs
     - Server/Hosting Costs
     - Third-Party API Costs (Google Maps, etc.)
     - Payment Processing Fees
     - Other Operational Costs
   - Profit Margin
     - Gross Revenue
     - Total Costs
     - Net Profit

3. **Pricing Configuration**
   - Base Fare Settings
     - Set per vehicle type
   - Distance Rate
     - Price per km
   - Time Rate
     - Price per minute
   - Surge Pricing
     - Enable/Disable
     - Multiplier Rules
   - Commission Rate
     - Platform percentage (e.g., 20%)

4. **Financial Reports**
   - Generate Reports
     - Daily Summary
     - Weekly Summary
     - Monthly Summary
     - Custom Date Range
   - Export Options
     - PDF Report
     - Excel Spreadsheet
     - CSV Data
   - Email Reports
     - Schedule automatic reports

5. **Payment Status**
   - Pending Payments
   - Failed Payments
   - Refund Requests
   - Payment Method Analytics

#### UI Components
```
Costs Screen:
├── Revenue Dashboard (top section)
│   ├── Key Metrics (4 cards)
│   ├── Revenue Chart (large)
│   └── Date Range Selector
├── Tabs
│   ├── Revenue Overview
│   ├── Cost Analysis
│   ├── Pricing Configuration
│   ├── Financial Reports
│   └── Payment Status
└── Action Buttons
    ├── Generate Report
    ├── Export Data
    ├── Update Pricing
    └── View Payments
```

---

## 🎨 UI/UX Design

### Design Principles
1. **Clarity**: Clear labels, intuitive navigation
2. **Efficiency**: Quick access to common actions
3. **Safety**: Confirmation dialogs for destructive actions
4. **Responsiveness**: Works on tablets and desktops (web focus)
5. **Accessibility**: WCAG 2.1 AA compliant

### Color Scheme (Admin Theme)
```dart
// Dark professional theme
Primary Color: #1E3A8A (Dark Blue)
Secondary Color: #10B981 (Green for success)
Warning Color: #F59E0B (Amber for warnings)
Danger Color: #EF4444 (Red for destructive actions)
Background: #F9FAFB (Light gray)
Card Background: #FFFFFF
Text Primary: #111827
Text Secondary: #6B7280
```

### Typography
```dart
Headings: Poppins (Bold, 600)
Body: Inter (Regular, 400)
Buttons: Inter (Medium, 500)
Tables: Roboto Mono (for data)
```

### Layout Structure
```
Admin Main Screen:
┌─────────────────────────────────────────────┐
│ Header: BTrips Admin | Admin Name | Logout  │
├─────────────────────────────────────────────┤
│ [Drivers] [Users] [Trips] [Accounts] [Costs]│ ← Tab Bar
├─────────────────────────────────────────────┤
│                                             │
│  Tab Content Area                           │
│  (Switches based on selected tab)           │
│                                             │
│                                             │
└─────────────────────────────────────────────┘
```

### Common UI Components

#### 1. Stats Card
```dart
Container:
  - Icon (colored)
  - Title (gray)
  - Value (large, bold)
  - Change indicator (+5% this week)
```

#### 2. Data Table
```dart
Features:
  - Sortable columns
  - Row selection (checkbox)
  - Action menu (3-dot)
  - Pagination controls
  - Search/filter bar above
```

#### 3. Action Confirmation Dialog
```dart
AlertDialog:
  Title: "Confirm Action"
  Content: Description + reason input (for deactivate/suspend)
  Actions:
    - Cancel (gray)
    - Confirm (colored based on action type)
```

#### 4. Detail Panel (Drawer or Modal)
```dart
Right-side slide-in panel:
  - Close button (X)
  - Tabs (Info, Activity, Documents)
  - Action buttons at bottom
```

---

## 🛠️ Implementation Plan

### Phase 1: Foundation (Week 1)
**Goal**: Set up admin role and basic infrastructure

#### Tasks
1. **Update Core Enums** ✅
   - Extend `UserType` enum to include `admin`
   - Update `toFirestore()` and `fromFirestore()` methods
   - Update all existing code using `UserType`

2. **Update Firebase Schema** ✅
   - Add admin-related fields to `users` collection
   - Add enhanced fields to `drivers` collection
   - Add audit fields to `rideRequests` collection
   - Create `adminActions` collection schema
   - Create `platformAnalytics` collection schema

3. **Update Security Rules** ✅
   - Add admin helper functions
   - Update collection rules for admin access
   - Deploy to Firebase

4. **Create Admin Super User** ✅
   - Manually create user document for `zayed.albertyn@gmail.com`
   - Set `userType: "admin"`
   - Set `isActive: true`, `isVerified: true`

5. **Update Authentication Flow** ✅
   - Add admin role detection in `AuthRepository`
   - Add `isAdmin()` helper method
   - Update splash screen routing logic

#### Files to Create/Update
```
lib/core/enums/
  ├── user_type.dart (UPDATE)

lib/data/models/
  ├── admin_action_model.dart (NEW)
  └── platform_analytics_model.dart (NEW)

lib/data/repositories/
  ├── auth_repository.dart (UPDATE)
  └── admin_repository.dart (NEW)

lib/data/providers/
  └── admin_providers.dart (NEW)

firestore.rules (UPDATE)
```

**Deliverables**:
- ✅ Admin role enum working
- ✅ Admin user created in Firebase
- ✅ Admin can login and see different UI
- ✅ Security rules deployed

---

### Phase 2: Admin Navigation & Layout (Week 1-2)
**Goal**: Create admin UI structure and navigation

#### Tasks
1. **Create Admin Screens** ✅
   - `AdminMainScreen` (5 tabs)
   - `AdminDriversScreen` (stub)
   - `AdminUsersScreen` (stub)
   - `AdminTripsScreen` (stub)
   - `AdminAccountsScreen` (stub)
   - `AdminCostsScreen` (stub)

2. **Update Routing** ✅
   - Add `/admin` route with protection
   - Add child routes for each tab
   - Add redirect logic for admin users

3. **Create Shared Admin Components** ✅
   - `AdminStatsCard` widget
   - `AdminDataTable` widget
   - `AdminSearchBar` widget
   - `AdminActionButton` widget
   - `AdminConfirmationDialog` widget

4. **Create Admin Theme** ✅
   - Define admin color scheme
   - Create `admin_theme.dart`
   - Apply to admin screens only

#### Files to Create
```
lib/features/admin/
  ├── presentation/
  │   ├── screens/
  │   │   ├── admin_main_screen.dart (NEW)
  │   │   ├── admin_drivers_screen.dart (NEW)
  │   │   ├── admin_users_screen.dart (NEW)
  │   │   ├── admin_trips_screen.dart (NEW)
  │   │   ├── admin_accounts_screen.dart (NEW)
  │   │   └── admin_costs_screen.dart (NEW)
  │   └── widgets/
  │       ├── admin_stats_card.dart (NEW)
  │       ├── admin_data_table.dart (NEW)
  │       ├── admin_search_bar.dart (NEW)
  │       ├── admin_action_button.dart (NEW)
  │       └── admin_confirmation_dialog.dart (NEW)

lib/core/theme/
  └── admin_theme.dart (NEW)

lib/routes/
  └── app_router.dart (UPDATE)
```

**Deliverables**:
- ✅ Admin can login and see admin dashboard
- ✅ 5 tabs visible and navigable
- ✅ Basic layout in place (with placeholders)

---

### Phase 3: Drivers Management Tab (Week 2-3)
**Goal**: Complete driver management functionality

#### Tasks
1. **Drivers List View** ✅
   - Fetch all drivers from Firestore
   - Display in paginated table
   - Add search functionality
   - Add filter by status, vehicle type
   - Add sorting

2. **Driver Actions** ✅
   - Activate/Deactivate driver
   - Suspend driver (with reason input)
   - Delete driver (soft delete with confirmation)
   - View driver details

3. **Driver Details View** ✅
   - Create detail drawer/modal
   - Display personal info
   - Display vehicle info
   - Display statistics
   - Display recent activity

4. **Document Verification** ✅
   - View uploaded documents (images)
   - Approve/Reject documents
   - Request re-upload

5. **Bulk Actions** ✅
   - Multi-select drivers
   - Bulk activate/deactivate
   - Export to CSV

#### Files to Create
```
lib/features/admin/presentation/
  ├── screens/
  │   └── admin_drivers_screen.dart (UPDATE)
  └── widgets/
      ├── driver_list_table.dart (NEW)
      ├── driver_detail_panel.dart (NEW)
      ├── driver_action_menu.dart (NEW)
      └── driver_document_viewer.dart (NEW)

lib/data/repositories/
  └── admin_repository.dart (UPDATE - add driver methods)
```

**Deliverables**:
- ✅ Drivers tab fully functional
- ✅ All CRUD operations working
- ✅ Audit log entries created

---

### Phase 4: Users Management Tab (Week 3)
**Goal**: Complete user management functionality

#### Tasks
1. **Users List View** ✅
   - Fetch all users from Firestore
   - Display in paginated table
   - Add search functionality
   - Add filter by status
   - Add sorting

2. **User Actions** ✅
   - Activate/Deactivate user
   - Suspend user (with reason input)
   - Delete user (soft delete with confirmation)
   - View user details
   - Edit contact information (phone, address) ⭐ NEW
   - Manage payment methods (view, add, remove) ⭐ NEW
   - Send notification

3. **User Details View** ✅
   - Create detail drawer/modal
   - Display personal info (with edit button)
   - Display ride history
   - Display payment methods (masked)
   - Display recent activity

4. **Edit Contact Information** ⭐ NEW
   - Create edit dialog
   - Phone number field with validation
   - Home address field (multi-line)
   - Update users/{uid} and userProfiles/{uid}
   - Log to audit trail

5. **Payment Methods Management** ⭐ NEW
   - Create payment methods dialog
   - Display existing cards (masked)
   - Stripe Elements integration
   - Add new card (tokenization)
   - Remove/deactivate cards
   - Set default payment method
   - Log all changes to audit trail

6. **Bulk Actions** ✅
   - Multi-select users
   - Bulk activate/deactivate
   - Bulk send notifications
   - Export to CSV

#### Files to Create
```
lib/features/admin/presentation/
  ├── screens/
  │   └── admin_users_screen.dart (UPDATE)
  └── widgets/
      ├── user_list_table.dart (NEW)
      ├── user_detail_panel.dart (NEW)
      ├── user_action_menu.dart (NEW)
      ├── edit_contact_info_dialog.dart (NEW) ⭐
      ├── payment_methods_dialog.dart (NEW) ⭐
      ├── add_payment_method_dialog.dart (NEW) ⭐
      └── send_notification_dialog.dart (NEW)

lib/data/repositories/
  └── admin_repository.dart (UPDATE - add payment methods)

lib/data/models/
  └── payment_method_model.dart (NEW) ⭐
```

**Deliverables**:
- ✅ Users tab fully functional
- ✅ All CRUD operations working
- ✅ Contact info editing working ⭐
- ✅ Payment methods management working ⭐
- ✅ Stripe integration complete ⭐
- ✅ Notification system working

---

### Phase 5: Trips Management Tab (Week 4)
**Goal**: Complete trip monitoring and analytics

#### Tasks
1. **Trips List View** ✅
   - Fetch all rides from Firestore
   - Display in paginated table
   - Add search by ID, user, driver
   - Add filter by status, date range
   - Add sorting

2. **Trip Details View** ✅
   - Display ride information
   - Display participants (user + driver)
   - Display route on map
   - Display pricing breakdown
   - Display timeline

3. **Analytics Dashboard** ✅
   - Create metric cards
   - Create charts:
     - Rides over time (line chart)
     - Revenue over time (line chart)
     - Status distribution (pie chart)
     - Peak hours (bar chart)
   - Add date range selector
   - Add export functionality

4. **Flagged Rides** ✅
   - View flagged rides
   - Review and clear flags
   - Take actions (refund, suspend)

#### Files to Create
```
lib/features/admin/presentation/
  ├── screens/
  │   └── admin_trips_screen.dart (UPDATE)
  └── widgets/
      ├── trip_list_table.dart (NEW)
      ├── trip_detail_panel.dart (NEW)
      ├── trip_analytics_dashboard.dart (NEW)
      ├── trips_chart_widget.dart (NEW)
      └── flagged_rides_list.dart (NEW)

Dependencies to add:
  - fl_chart: ^0.66.0 (for charts)
  - csv: ^5.1.1 (for exports)
```

**Deliverables**:
- ✅ Trips tab fully functional
- ✅ Analytics dashboard working
- ✅ Charts displaying data
- ✅ Export functionality working

---

### Phase 6: Accounts Management Tab (Week 4-5)
**Goal**: Account verification and management

#### Tasks
1. **Verification Queue** ✅
   - Fetch pending verifications
   - Display document gallery
   - Quick approve/reject actions
   - Request more info

2. **Account Overview** ✅
   - Display account stats
   - Show user accounts
   - Show driver accounts
   - Show suspended accounts

3. **Admin Management** (Super Admin Only) ✅
   - View all admins
   - Add new admin
   - Remove admin access

4. **Account Rules** ✅
   - Configure auto-suspend rules
   - Configure verification requirements

#### Files to Create
```
lib/features/admin/presentation/
  ├── screens/
  │   └── admin_accounts_screen.dart (UPDATE)
  └── widgets/
      ├── verification_queue_widget.dart (NEW)
      ├── account_stats_overview.dart (NEW)
      ├── admin_management_panel.dart (NEW)
      └── account_rules_settings.dart (NEW)
```

**Deliverables**:
- ✅ Accounts tab fully functional
- ✅ Verification workflow working
- ✅ Admin management working (for super admin)

---

### Phase 7: Costs & Revenue Tab (Week 5-6)
**Goal**: Financial management and reporting

#### Tasks
1. **Revenue Dashboard** ✅
   - Display revenue metrics
   - Create revenue charts
   - Add date range filtering

2. **Cost Analysis** ✅
   - Driver earnings breakdown
   - Platform costs
   - Profit margin calculation

3. **Pricing Configuration** ✅
   - Base fare settings
   - Distance/time rates
   - Surge pricing rules
   - Commission rate

4. **Financial Reports** ✅
   - Generate reports (daily, weekly, monthly)
   - Export to PDF/Excel/CSV
   - Email scheduling

5. **Payment Status** ✅
   - View pending payments
   - View failed payments
   - Handle refund requests

#### Files to Create
```
lib/features/admin/presentation/
  ├── screens/
  │   └── admin_costs_screen.dart (UPDATE)
  └── widgets/
      ├── revenue_dashboard_widget.dart (NEW)
      ├── cost_analysis_widget.dart (NEW)
      ├── pricing_configuration_widget.dart (NEW)
      ├── financial_reports_widget.dart (NEW)
      └── payment_status_widget.dart (NEW)

Dependencies to add:
  - pdf: ^3.10.7 (for PDF reports)
  - excel: ^2.1.0 (for Excel exports)
```

**Deliverables**:
- ✅ Costs tab fully functional
- ✅ Revenue tracking working
- ✅ Pricing configuration working
- ✅ Report generation working

---

### Phase 8: Audit Logging & Cloud Functions (Week 6)
**Goal**: Complete audit trail and automation

#### Tasks
1. **Audit Logging** ✅
   - Log all admin actions to `adminActions` collection
   - Include before/after states
   - Include reason for action

2. **Cloud Functions** (Optional) ✅
   - Auto-generate daily analytics
   - Send alerts for flagged rides
   - Auto-suspend accounts based on rules
   - Generate scheduled reports

3. **Real-time Notifications** ✅
   - FCM for admin alerts
   - Email notifications for critical actions

#### Files to Create
```
functions/ (Firebase Cloud Functions)
  ├── src/
  │   ├── analytics.ts (NEW - daily analytics)
  │   ├── alerts.ts (NEW - flagged ride alerts)
  │   ├── automation.ts (NEW - auto-suspend rules)
  │   └── reports.ts (NEW - scheduled reports)
  └── package.json

lib/data/repositories/
  └── admin_repository.dart (UPDATE - add audit logging)
```

**Deliverables**:
- ✅ All actions logged to audit trail
- ✅ Cloud functions deployed (if using)
- ✅ Alerts working

---

### Phase 9: Testing & QA (Week 7)
**Goal**: Comprehensive testing of admin features

#### Test Cases
1. **Authentication**
   - ✅ Admin can login
   - ✅ Non-admin cannot access admin routes
   - ✅ Super admin has additional privileges

2. **Driver Management**
   - ✅ Activate/deactivate driver
   - ✅ Suspend driver with reason
   - ✅ Delete driver (soft delete)
   - ✅ Verify documents
   - ✅ View driver details
   - ✅ Bulk actions work

3. **User Management**
   - ✅ Activate/deactivate user
   - ✅ Suspend user with reason
   - ✅ Delete user (soft delete)
   - ✅ View user details
   - ✅ Send notifications
   - ✅ Bulk actions work

4. **Trip Management**
   - ✅ View all rides
   - ✅ Filter and search rides
   - ✅ View ride details
   - ✅ Analytics display correctly
   - ✅ Charts render properly
   - ✅ Export data works

5. **Account Management**
   - ✅ Verification queue works
   - ✅ Document approval works
   - ✅ Admin management works (super admin)
   - ✅ Account rules save correctly

6. **Costs Management**
   - ✅ Revenue displays correctly
   - ✅ Cost analysis accurate
   - ✅ Pricing updates save
   - ✅ Reports generate properly
   - ✅ Exports work (PDF, Excel, CSV)

7. **Security**
   - ✅ Firestore rules prevent unauthorized access
   - ✅ Audit log is immutable
   - ✅ Super admin email check works

8. **Performance**
   - ✅ Tables paginate efficiently
   - ✅ Large datasets load quickly
   - ✅ Charts render smoothly

**Deliverables**:
- ✅ All test cases passed
- ✅ Bugs fixed
- ✅ Performance optimized

---

### Phase 10: Documentation & Deployment (Week 7)
**Goal**: Document and deploy admin features

#### Tasks
1. **Documentation** ✅
   - Admin user guide
   - Technical documentation
   - API documentation
   - Security guidelines

2. **Deployment** ✅
   - Deploy Firestore rules
   - Deploy Cloud Functions (if using)
   - Build production app
   - Deploy web admin (if web-focused)

3. **Training** ✅
   - Create admin tutorial
   - Create video walkthrough

#### Files to Create
```
docs/
  ├── ADMIN_USER_GUIDE.md (NEW)
  ├── ADMIN_TECHNICAL_DOCS.md (NEW)
  └── ADMIN_SECURITY_GUIDELINES.md (NEW)
```

**Deliverables**:
- ✅ Documentation complete
- ✅ Admin portal deployed
- ✅ Training materials ready

---

## 🧪 Technical Requirements

### Dependencies to Add
```yaml
# pubspec.yaml

dependencies:
  # Existing dependencies...
  
  # Charts for analytics
  fl_chart: ^0.66.0
  
  # CSV export
  csv: ^5.1.1
  
  # PDF generation
  pdf: ^3.10.7
  
  # Excel export
  excel: ^2.1.0
  
  # Data tables with pagination
  data_table_2: ^2.5.12
  
  # File picker (for document uploads)
  file_picker: ^6.1.1
  
  # Image viewer (for document verification)
  photo_view: ^0.14.0
  
  # Stripe payment processing ⭐ NEW
  flutter_stripe: ^10.1.1
  stripe_platform_interface: ^10.1.1
  
  # Stripe backend (for Cloud Functions)
  # stripe: (Node.js package for backend)
```

### Minimum Platform Versions
```yaml
- Flutter SDK: >=3.3.0
- Dart SDK: >=3.0.0
- Android: minSdkVersion 21
- iOS: 12.0+
- Web: Chrome/Firefox/Safari (latest)
```

### Firebase Products Used
```
- Firebase Authentication
- Cloud Firestore (with composite indexes)
- Firebase Storage (for document uploads)
- Firebase Cloud Functions (optional)
- Firebase Cloud Messaging (for notifications)
```

---

## 🧪 Testing Strategy

### Unit Tests
```dart
// Test repositories
test_driver_activation()
test_user_suspension()
test_audit_log_creation()
test_analytics_calculation()

// Test providers
test_driver_list_provider()
test_user_list_provider()
test_trip_analytics_provider()
```

### Integration Tests
```dart
// Test workflows
test_driver_verification_workflow()
test_user_suspension_workflow()
test_bulk_action_workflow()
test_report_generation_workflow()
```

### Manual Test Cases
```
1. Login as admin
2. View drivers list
3. Activate a driver
4. Verify driver documents
5. Suspend a user
6. View trip analytics
7. Generate financial report
8. Export data to CSV
9. Update pricing configuration
10. Logout
```

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] All phases completed
- [ ] All tests passed
- [ ] Documentation complete
- [ ] Security rules tested
- [ ] Performance optimized

### Firebase Setup
- [ ] Create super admin user (`zayed.albertyn@gmail.com`)
- [ ] Deploy Firestore security rules
- [ ] Create composite indexes
- [ ] Deploy Cloud Functions (if using)
- [ ] Configure FCM for notifications

### App Deployment
- [ ] Build production APK/IPA
- [ ] Test on real devices
- [ ] Deploy web version (if applicable)
- [ ] Monitor error logs

### Post-Deployment
- [ ] Verify admin login works
- [ ] Test critical workflows
- [ ] Monitor performance
- [ ] Gather feedback
- [ ] Create backup of data

---

## 🎯 Success Criteria

### Functionality
- ✅ Admin can manage all drivers (CRUD)
- ✅ Admin can manage all users (CRUD)
- ✅ Admin can view all trips with analytics
- ✅ Admin can verify accounts
- ✅ Admin can manage costs and pricing
- ✅ All actions are logged in audit trail

### Security
- ✅ Only admin users can access admin routes
- ✅ Super admin has exclusive privileges
- ✅ Firestore rules prevent unauthorized access
- ✅ Audit log is immutable

### Performance
- ✅ Tables load in < 2 seconds
- ✅ Charts render in < 1 second
- ✅ Searches return results in < 1 second
- ✅ Exports generate in < 5 seconds

### User Experience
- ✅ Intuitive navigation
- ✅ Clear action feedback
- ✅ Confirmation for destructive actions
- ✅ Responsive on tablets/desktops

---

## 📚 Next Steps

1. **Review this specification document**
2. **Get approval for design and features**
3. **Begin Phase 1 implementation**
4. **Create admin super user in Firebase**
5. **Start building admin UI**

---

## 📞 Notes

### Super Admin Setup
```javascript
// Manually add this to Firestore (Firebase Console):
// Collection: users
// Document ID: <zayed.albertyn@gmail.com's UID>

{
  userType: "admin",
  email: "zayed.albertyn@gmail.com",
  name: "Zayed Albertyn",
  phoneNumber: "",
  isActive: true,
  isVerified: true,
  isSuspended: false,
  createdAt: Timestamp.now(),
  lastLogin: Timestamp.now(),
  fcmToken: "",
  profileImageUrl: "",
  metadata: {
    totalLogins: 0,
    lastActivity: Timestamp.now(),
    deviceInfo: "",
    ipAddress: ""
  }
}
```

### Stripe Integration Setup ⭐ NEW

#### Step 1: Create Stripe Account
1. Go to https://stripe.com
2. Create a business account
3. Complete verification
4. Get API keys (Publishable and Secret)

#### Step 2: Configure Stripe in Firebase
```javascript
// Firebase Cloud Functions config (future implementation)
firebase functions:config:set \
  stripe.secret_key="sk_test_..." \
  stripe.publishable_key="pk_test_..."
```

#### Step 3: Flutter App Configuration
```dart
// lib/core/constants/stripe_constants.dart
class StripeConstants {
  // Use test keys for development
  static const String publishableKey = 'pk_test_...';
  
  // For production, use environment variables
  static const String publishableKeyProd = 'pk_live_...';
}

// Initialize in main.dart
await Stripe.instance.applySettings(
  publishableKey: StripeConstants.publishableKey,
  merchantDisplayName: 'BTrips',
);
```

#### Step 4: Payment Method Token Flow
```
User/Admin adds card:
1. Admin opens "Add Payment Method" dialog
2. Stripe Elements collects card details (secure iframe)
3. Stripe tokenizes card → Returns payment method ID
4. Save to Firestore:
   {
     stripePaymentMethodId: "pm_1234...",
     last4: "4242",
     brand: "visa",
     expiryMonth: "12",
     expiryYear: "2025",
     cardholderName: "John Doe"
   }
5. Card details NEVER touch your servers
```

#### Step 5: Security Best Practices
- ✅ Use Stripe Elements (PCI compliant)
- ✅ Never log card numbers or CVV
- ✅ Use test mode in development
- ✅ Store only payment method tokens
- ✅ Implement webhook verification
- ✅ Use 3D Secure for European cards
- ✅ Monitor Stripe dashboard for fraud

#### Step 6: Future Payment Processing
When rides are completed:
```dart
// Cloud Function or backend service
1. Get user's default payment method
2. Create PaymentIntent with Stripe
3. Charge card using stored token
4. Update ride with payment status
5. Send receipt to user
```

#### Test Cards (Stripe Test Mode)
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
Insufficient funds: 4000 0000 0000 9995
Expired card: 4000 0000 0000 0069
Any future date for expiry
Any 3 digits for CVV
```

### Data Storage Clarification ⭐ IMPORTANT

**Where Data is Stored:**

| Data Type | Storage Location | Why |
|-----------|------------------|-----|
| Phone numbers | Cloud Firestore (`users/` collection) | Text data, fast queries |
| Home addresses | Cloud Firestore (`userProfiles/` collection) | Text data, fast queries |
| Payment tokens | Cloud Firestore (`userProfiles/paymentMethods` array) | Structured data, secure |
| Profile pictures | Firebase Storage (`profilePictures/{userId}.jpg`) | Binary files, CDN delivery |
| Driver documents | Firebase Storage (`driverDocuments/{userId}/`) | Images/PDFs |
| Document thumbnails | Firebase Storage (`documentThumbnails/`) | Optimized images |

**Note**: Firebase Storage is for files (images, PDFs), while Firestore is for structured data (text, numbers, objects). Contact information and payment tokens are stored in Firestore for fast querying and real-time updates.

### Platform Focus
- **Primary**: Web (desktop browsers) for admin portal
- **Secondary**: Android/iOS (tablets)
- **Not Optimized**: Mobile phones (too small for data tables)

---

**Document Version**: 1.1.0 ⭐ UPDATED  
**Created**: November 2, 2025  
**Last Updated**: November 2, 2025  
**Status**: ✅ **READY FOR IMPLEMENTATION**  
**Estimated Timeline**: 8-9 weeks for full implementation (including payment integration)

---

**Next Document**: `ADMIN_IMPLEMENTATION_PROGRESS.md` (to be created during implementation)

