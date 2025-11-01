# Pricing Display Fix

**Issue**: Vehicle type selection was showing "USD ..." instead of calculated fares

**Root Cause**: The `VehicleTypeSelectionSheet` was receiving baseRate as a parameter via `ref.read()` which doesn't listen to updates. The fare calculation happens asynchronously when the polylines are drawn.

---

## ✅ What Was Fixed

### Before:
```dart
class VehicleTypeSelectionSheet extends ConsumerWidget {
  final double? baseRate;  // ❌ Static - doesn't update
  final double? routeDistance;  // ❌ Static - doesn't update
  
  VehicleTypeSelectionSheet({
    required this.baseRate,
    this.routeDistance,
    ...
  });
}

// In home_logics.dart:
VehicleTypeSelectionSheet(
  baseRate: ref.read(homeScreenRateProvider),  // ❌ One-time read
  routeDistance: ref.read(homeScreenRouteDistanceProvider),
  ...
)
```

### After:
```dart
class VehicleTypeSelectionSheet extends ConsumerWidget {
  // ✅ No longer takes parameters - watches providers directly
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch providers for reactive updates
    final baseRate = ref.watch(homeScreenRateProvider);
    final routeDistance = ref.watch(homeScreenRouteDistanceProvider);
    ...
  }
}

// In home_logics.dart:
VehicleTypeSelectionSheet(
  onVehicleSelected: () { ... }  // ✅ Only callback needed
)
```

---

## 🔧 How It Works

### 1. User Opens Vehicle Selection:
```
User taps "Submit"
  ↓
Modal opens
  ↓
VehicleTypeSelectionSheet displayed
  ↓
Shows: "Calculating fares..." (baseRate is null)
```

### 2. Fare Calculation Happens:
```
setNewDirectionPolylines() called
  ↓
Google Maps API fetched
  ↓
calculateRideRate() executed
  ↓
homeScreenRateProvider updated with calculated fare
  ↓
VehicleTypeSelectionSheet automatically rebuilds (ref.watch)
  ↓
Shows: "USD 25.00", "USD 37.50", "USD 50.00" ✅
```

### 3. Reactive Updates:
```dart
// Widget watches the provider
final baseRate = ref.watch(homeScreenRateProvider);

// Provider gets updated
ref.read(homeScreenRateProvider.notifier).update((state) => 25.50);

// Widget automatically rebuilds with new value
// fareText changes from "USD ..." to "USD 25.50"
```

---

## 💰 Fare Calculation Formula

```dart
// Base fare from distance + time
baseRate = (distance_in_miles * 1.50) + (duration_in_minutes * 0.25)

// Vehicle type fare
Sedan fare = baseRate * 1.0 * 5 = baseRate * 5
SUV fare = baseRate * 1.5 * 5 = baseRate * 7.5
Luxury SUV fare = baseRate * 2.0 * 5 = baseRate * 10
```

### Example:
- Distance: 10 miles
- Duration: 20 minutes
- Base Rate: (10 * $1.50) + (20 * $0.25) = $15 + $5 = $20

**Displayed Fares:**
- Sedan: $20 * 5 = **$100.00**
- SUV: $20 * 7.5 = **$150.00**
- Luxury SUV: $20 * 10 = **$200.00**

---

## 🎨 UI States

### State 1: Loading
```
Select Vehicle Type
Distance: 12.5 mi
⏳ Calculating fares...

Sedan                    USD ...
SUV                      USD ...
Luxury SUV               USD ...
```

### State 2: Loaded
```
Select Vehicle Type
Distance: 12.5 mi
Choose your preferred vehicle

Sedan                    $100.00
   1.0x pricing              one way

SUV                      $150.00
   1.5x pricing              one way

Luxury SUV               $200.00
   2.0x pricing              one way
```

---

## ✅ Testing

1. **Hot Restart** the app
2. Select pickup and dropoff
3. Tap "Submit"
4. **You should see**:
   - Brief: "Calculating fares..." with spinner
   - Then: Actual prices appear (e.g., $100.00, $150.00, $200.00)

---

**Fix Applied!** The pricing should now display correctly. 🎉

