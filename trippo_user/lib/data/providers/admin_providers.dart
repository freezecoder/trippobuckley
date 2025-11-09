import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/admin_repository.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../models/admin_action_model.dart';
import '../models/ride_request_model.dart';
import '../../core/enums/ride_status.dart';

/// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

/// Provider for fetching all drivers (basic user info)
final allDriversProvider = FutureProvider<List<UserModel>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return await adminRepo.getAllDrivers(limit: 100);
});

/// Combined driver data with email
class DriverWithEmail {
  final DriverModel driver;
  final String email;
  final String name;

  DriverWithEmail({
    required this.driver,
    required this.email,
    required this.name,
  });
}

/// Provider for fetching all drivers with earnings data and email
final allDriversWithEarningsProvider = FutureProvider<List<DriverWithEmail>>((ref) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Get driver data
    final driversSnapshot = await firestore
        .collection('drivers')
        .orderBy('earnings', descending: true)
        .limit(100)
        .get();
    
    // Get corresponding user data for emails
    final List<DriverWithEmail> driversWithEmail = [];
    
    for (final doc in driversSnapshot.docs) {
      final driverModel = DriverModel.fromFirestore(doc.data(), doc.id);
      
      // Get user document to fetch email
      final userDoc = await firestore.collection('users').doc(doc.id).get();
      final email = userDoc.exists ? (userDoc.data()?['email'] ?? 'N/A') : 'N/A';
      final name = userDoc.exists ? (userDoc.data()?['name'] ?? 'N/A') : 'N/A';
      
      driversWithEmail.add(DriverWithEmail(
        driver: driverModel,
        email: email,
        name: name,
      ));
    }
    
    return driversWithEmail;
  } catch (e) {
    print('Error fetching drivers with earnings: $e');
    return [];
  }
});

/// Provider for fetching all users (passengers)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return await adminRepo.getAllUsers(limit: 100);
});

/// Provider for driver search query
final driverSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for user search query
final userSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered drivers based on search query
final filteredDriversProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final driversAsync = ref.watch(allDriversProvider);
  final searchQuery = ref.watch(driverSearchQueryProvider);

  return driversAsync.when(
    data: (drivers) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(drivers);
      }

      final filtered = drivers.where((driver) {
        final query = searchQuery.toLowerCase();
        return driver.name.toLowerCase().contains(query) ||
            driver.email.toLowerCase().contains(query) ||
            (driver.phoneNumber.isNotEmpty &&
                driver.phoneNumber.toLowerCase().contains(query));
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for filtered users based on search query
final filteredUsersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);

  return usersAsync.when(
    data: (users) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(users);
      }

      final filtered = users.where((user) {
        final query = searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phoneNumber.isNotEmpty &&
                user.phoneNumber.toLowerCase().contains(query));
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for driver statistics
final driverStatsProvider = Provider<Map<String, int>>((ref) {
  final driversAsync = ref.watch(allDriversProvider);

  return driversAsync.when(
    data: (drivers) {
      int total = drivers.length;
      int active = drivers.where((d) => d.isActive).length;
      int inactive = drivers.where((d) => !d.isActive).length;

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'pending': 0, // TODO: Add pending verification count
        'suspended': 0, // TODO: Add suspended count
      };
    },
    loading: () => {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'pending': 0,
      'suspended': 0,
    },
    error: (_, __) => {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'pending': 0,
      'suspended': 0,
    },
  );
});

/// Provider for user statistics
final userStatsProvider = Provider<Map<String, int>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);

  return usersAsync.when(
    data: (users) {
      int total = users.length;
      int active = users.where((u) => u.isActive).length;
      int inactive = users.where((u) => !u.isActive).length;

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'new': 0, // TODO: Calculate new users this month
        'suspended': 0, // TODO: Add suspended count
      };
    },
    loading: () => {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'new': 0,
      'suspended': 0,
    },
    error: (_, __) => {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'new': 0,
      'suspended': 0,
    },
  );
});

/// Provider for admin actions (audit log)
final adminActionsProvider = FutureProvider<List<AdminActionModel>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return await adminRepo.getAdminActions(limit: 50);
});

/// Provider to refresh drivers list
final refreshDriversProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(allDriversProvider);
  };
});

/// Provider to refresh users list
final refreshUsersProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(allUsersProvider);
  };
});

/// Provider for fetching all rides
final allRidesProvider = FutureProvider<List<RideRequestModel>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return await adminRepo.getAllRides(limit: 200);
});

/// Provider for ride search query
final rideSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered rides based on search query
final filteredRidesProvider = Provider<AsyncValue<List<RideRequestModel>>>((ref) {
  final ridesAsync = ref.watch(allRidesProvider);
  final searchQuery = ref.watch(rideSearchQueryProvider);

  return ridesAsync.when(
    data: (rides) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(rides);
      }

      final filtered = rides.where((ride) {
        final query = searchQuery.toLowerCase();
        return ride.id.toLowerCase().contains(query) ||
            ride.userEmail.toLowerCase().contains(query) ||
            (ride.driverEmail?.toLowerCase().contains(query) ?? false) ||
            ride.pickupAddress.toLowerCase().contains(query) ||
            ride.dropoffAddress.toLowerCase().contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for ride statistics
final rideStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final ridesAsync = ref.watch(allRidesProvider);

  return ridesAsync.when(
    data: (rides) {
      final total = rides.length;
      final completed = rides.where((r) => r.status == RideStatus.completed).length;
      final ongoing = rides.where((r) => r.status == RideStatus.ongoing).length;
      final pending = rides.where((r) => r.status == RideStatus.pending).length;
      final cancelled = rides.where((r) => r.status == RideStatus.cancelled).length;
      
      final totalRevenue = rides
          .where((r) => r.status == RideStatus.completed)
          .fold<double>(0, (sum, ride) => sum + ride.fare);
      
      final avgFare = completed > 0 ? totalRevenue / completed : 0.0;
      final avgDistance = rides.isNotEmpty
          ? rides.fold<double>(0, (sum, ride) => sum + ride.distance) / rides.length
          : 0.0;

      return {
        'total': total,
        'completed': completed,
        'ongoing': ongoing,
        'pending': pending,
        'cancelled': cancelled,
        'totalRevenue': totalRevenue,
        'avgFare': avgFare,
        'avgDistance': avgDistance,
      };
    },
    loading: () => {
      'total': 0,
      'completed': 0,
      'ongoing': 0,
      'pending': 0,
      'cancelled': 0,
      'totalRevenue': 0.0,
      'avgFare': 0.0,
      'avgDistance': 0.0,
    },
    error: (_, __) => {
      'total': 0,
      'completed': 0,
      'ongoing': 0,
      'pending': 0,
      'cancelled': 0,
      'totalRevenue': 0.0,
      'avgFare': 0.0,
      'avgDistance': 0.0,
    },
  );
});

/// Provider to refresh rides list
final refreshRidesProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(allRidesProvider);
  };
});

/// Model for admin invoice
class AdminInvoice {
  final String id;
  final String userId;
  final String userEmail;
  final double amount;
  final String description;
  final String adminEmail;
  final String? stripePaymentIntentId;
  final String status;
  final DateTime createdAt;
  final String? error;

  AdminInvoice({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.amount,
    required this.description,
    required this.adminEmail,
    this.stripePaymentIntentId,
    required this.status,
    required this.createdAt,
    this.error,
  });

  factory AdminInvoice.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminInvoice(
      id: id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      stripePaymentIntentId: data['stripePaymentIntentId'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      error: data['error'],
    );
  }
}

/// Provider for fetching all admin invoices
final allAdminInvoicesProvider = StreamProvider<List<AdminInvoice>>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('adminInvoices')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => AdminInvoice.fromFirestore(doc.data(), doc.id))
        .toList();
  });
});

/// Provider for fetching admin invoices for a specific user
final userAdminInvoicesProvider = StreamProvider.family<List<AdminInvoice>, String>((ref, userId) {
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('adminInvoices')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => AdminInvoice.fromFirestore(doc.data(), doc.id))
        .toList();
  });
});

