import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/presentation/widgets/star_rating_widget.dart';

/// Provider to fetch passenger details by ID
final passengerDetailsProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return snapshot.data();
  });
});

/// Provider to fetch passenger profile details
final passengerProfileProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('userProfiles')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return snapshot.data();
  });
});

/// Widget showing passenger information for drivers
class PassengerInfoCard extends ConsumerWidget {
  final String userId;
  final String? userEmail;
  
  const PassengerInfoCard({
    super.key,
    required this.userId,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(passengerDetailsProvider(userId));
    final profileData = ref.watch(passengerProfileProvider(userId));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: userData.when(
        data: (user) {
          if (user == null) {
            return _buildLoadingState();
          }

          final profile = profileData.value;
          final passengerName = user['name'] ?? 'Passenger';
          final profileImageUrl = user['profileImageUrl'] as String?;
          final phoneNumber = user['phoneNumber'] as String?;
          final rating = profile?['rating'] ?? 5.0;
          final totalRides = profile?['totalRides'] ?? 0;

          return Row(
            children: [
              // Profile Picture
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.grey[600],
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.grey[600],
                        ),
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Passenger Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'PASSENGER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Name
                    Text(
                      passengerName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Rating and Rides
                    Row(
                      children: [
                        CompactStarRating(rating: rating.toDouble(), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($totalRides rides)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    
                    // Phone number if available
                    if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Call button
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                IconButton(
                  onPressed: () {
                    // TODO: Implement call functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling $phoneNumber...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  color: Colors.green,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (_, __) => _buildErrorState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(
          'Loading passenger info...',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Row(
      children: [
        Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Passenger: ${userEmail ?? "Unknown"}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ),
      ],
    );
  }
}

