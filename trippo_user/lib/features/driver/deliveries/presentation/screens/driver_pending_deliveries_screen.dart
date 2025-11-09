import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:btrips_unified/data/models/ride_request_model.dart';
import 'package:btrips_unified/Container/Repositories/firestore_repo.dart';
import 'package:btrips_unified/features/shared/presentation/screens/ride_delivery_details_screen.dart';

/// Screen showing all pending delivery requests for driver
class DriverPendingDeliveriesScreen extends StatelessWidget {
  const DriverPendingDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rideRequests')
            .where('isDelivery', isEqualTo: true)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading deliveries',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Trigger refresh
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DriverPendingDeliveriesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Loading deliveries...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final deliveries = snapshot.data?.docs ?? [];

          debugPrint('📦 Found ${deliveries.length} pending deliveries');

          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 100,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Delivery Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Waiting for customers to request deliveries...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final doc = deliveries[index];
                final data = doc.data() as Map<String, dynamic>;
                final deliveryId = doc.id;
                final delivery = RideRequestModel.fromFirestore(data, deliveryId);

                return _DeliveryCard(
                  delivery: delivery,
                  deliveryId: deliveryId,
                );
              },
            ),
          );
        },
      );
  }
}

/// Individual delivery card widget
class _DeliveryCard extends StatelessWidget {
  final RideRequestModel delivery;
  final String deliveryId;

  const _DeliveryCard({
    required this.delivery,
    required this.deliveryId,
  });

  String _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'medicines':
        return '💊';
      case 'groceries':
        return '🛒';
      case 'other':
        return '📦';
      default:
        return '📦';
    }
  }

  String _getCategoryName(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return 'Food';
      case 'medicines':
        return 'Medicines';
      case 'groceries':
        return 'Groceries';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: Colors.grey[900],
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange[700]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.deepOrange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '📦 DELIVERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _getCategoryIcon(delivery.deliveryCategory),
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category
            Row(
              children: [
                Icon(Icons.category, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Category: ${_getCategoryName(delivery.deliveryCategory)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),

            // Items
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shopping_bag, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items to Pick Up:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        delivery.deliveryItemsDescription ?? 'No description',
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pickup Location
            _buildLocationRow(
              icon: Icons.store,
              label: 'Pickup From',
              address: delivery.pickupAddress,
              color: Colors.orange,
            ),

            const SizedBox(height: 12),

            // Dropoff Location
            _buildLocationRow(
              icon: Icons.location_on,
              label: 'Deliver To',
              address: delivery.dropoffAddress,
              color: Colors.green,
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),

            // Financial Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${delivery.distance.toStringAsFixed(1)} mi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (delivery.deliveryItemCost != null && delivery.deliveryItemCost! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Item Cost',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${delivery.deliveryItemCost!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '(you pay store)',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'You Earn',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${delivery.fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Warning if driver pays
            if (delivery.deliveryItemCost != null && delivery.deliveryItemCost! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[700]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'ll pay \$${delivery.deliveryItemCost!.toStringAsFixed(2)} at the store. Customer will reimburse.',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery declined'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to accept deliveries'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      debugPrint('📦 Accepting delivery: $deliveryId');
                      debugPrint('   Driver UID: ${currentUser.uid}');
                      debugPrint('   Driver Email: ${currentUser.email}');

                      try {
                        // Accept delivery - update with driver info and status
                        await FirebaseFirestore.instance
                            .collection('rideRequests')
                            .doc(deliveryId)
                            .update({
                          'driverId': currentUser.uid,
                          'driverEmail': currentUser.email,
                          'status': 'accepted',
                          'acceptedAt': FieldValue.serverTimestamp(),
                        });

                        debugPrint('✅ Delivery acceptance updated in Firestore');

                        // Verify the update
                        final updatedDoc = await FirebaseFirestore.instance
                            .collection('rideRequests')
                            .doc(deliveryId)
                            .get();
                        
                        debugPrint('📋 Updated document status: ${updatedDoc.data()?['status']}');
                        debugPrint('📋 Updated document driverId: ${updatedDoc.data()?['driverId']}');

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Delivery accepted! Navigate to pickup.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to delivery details screen
                          await Future.delayed(const Duration(milliseconds: 500));
                          
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RideDeliveryDetailsScreen(
                                  rideId: deliveryId,
                                  isDriver: true,
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('❌ Error accepting delivery: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error accepting delivery: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Accept Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

