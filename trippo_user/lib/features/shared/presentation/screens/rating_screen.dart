import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../data/models/ride_request_model.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../../data/providers/ride_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../Container/utils/error_notification.dart';
import '../widgets/star_rating_widget.dart';

/// Provider for selected rating
final selectedRatingProvider = StateProvider.autoDispose<double>((ref) => 0.0);

/// Provider for feedback text
final feedbackProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider for loading state
final ratingLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Screen for rating a completed ride
/// Users rate drivers, Drivers rate users
class RatingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final bool isDriver;

  const RatingScreen({
    super.key,
    required this.rideId,
    this.isDriver = false,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  RideRequestModel? _ride;

  @override
  void initState() {
    super.initState();
    _loadRideDetails();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// Load ride details
  Future<void> _loadRideDetails() async {
    try {
      final rideRepo = ref.read(rideRepositoryProvider);
      final ride = await rideRepo.getRideRequest(widget.rideId);
      
      if (mounted) {
        setState(() {
          _ride = ride;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorNotification().showError(context, "Failed to load ride details");
      }
    }
  }

  /// Submit rating
  Future<void> _submitRating() async {
    final rating = ref.read(selectedRatingProvider);
    
    if (rating == 0.0) {
      ErrorNotification().showError(context, "Please select a rating");
      return;
    }

    try {
      ref.read(ratingLoadingProvider.notifier).state = true;

      final rideRepo = ref.read(rideRepositoryProvider);
      final feedback = _feedbackController.text.trim();

      if (widget.isDriver) {
        // Driver rating user
        await rideRepo.addDriverRating(
          rideId: widget.rideId,
          rating: rating,
          feedback: feedback.isNotEmpty ? feedback : null,
        );

        // Update user's average rating
        if (_ride != null && _ride!.userId.isNotEmpty) {
          final userRepo = ref.read(userRepositoryProvider);
          await userRepo.updateRating(
            userId: _ride!.userId,
            newRating: rating,
          );
        }
      } else {
        // User rating driver
        await rideRepo.addUserRating(
          rideId: widget.rideId,
          rating: rating,
          feedback: feedback.isNotEmpty ? feedback : null,
        );

        // Update driver's average rating
        if (_ride != null && _ride!.driverId != null) {
          final driverRepo = ref.read(driverRepositoryProvider);
          await driverRepo.updateRating(
            driverId: _ride!.driverId!,
            newRating: rating,
          );
        }
      }

      // Increment ride counts
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser != null) {
        if (widget.isDriver) {
          final driverRepo = ref.read(driverRepositoryProvider);
          await driverRepo.incrementTotalRides(currentUser.uid);
        } else {
          final userRepo = ref.read(userRepositoryProvider);
          await userRepo.incrementTotalRides(currentUser.uid);
        }
      }

      ref.read(ratingLoadingProvider.notifier).state = false;

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to main screen
        if (widget.isDriver) {
          context.goNamed(RouteNames.driverMain);
        } else {
          context.goNamed(RouteNames.userMain);
        }
      }
    } catch (e) {
      ref.read(ratingLoadingProvider.notifier).state = false;
      if (mounted) {
        ErrorNotification().showError(
          context,
          "Failed to submit rating: ${e.toString()}",
        );
      }
    }
  }

  /// Skip rating
  void _skipRating() {
    if (widget.isDriver) {
      context.goNamed(RouteNames.driverMain);
    } else {
      context.goNamed(RouteNames.userMain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRating = ref.watch(selectedRatingProvider);
    final isLoading = ref.watch(ratingLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isDriver ? 'Rate Passenger' : 'Rate Your Driver'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _skipRating,
        ),
      ),
      body: _ride == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ride Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _ride!.pickupAddress,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Dropoff
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _ride!.dropoffAddress,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Fare and Vehicle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                  Text(
                                    '\$${_ride!.fare.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _ride!.vehicleType,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Rating prompt
                    Text(
                      widget.isDriver
                          ? 'How was the passenger?'
                          : 'How was your ride?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Star Rating
                    Center(
                      child: StarRating(
                        rating: selectedRating,
                        size: 50.0,
                        readOnly: false,
                        onRatingChanged: (newRating) {
                          ref.read(selectedRatingProvider.notifier).state = newRating;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Rating text
                    if (selectedRating > 0)
                      Center(
                        child: Text(
                          _getRatingText(selectedRating),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Feedback field
                    Text(
                      'Share your feedback (optional)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      maxLength: 200,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: widget.isDriver
                            ? 'Tell us about the passenger...'
                            : 'Tell us about your experience...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          isLoading ? 'Submitting...' : 'Submit Rating',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Skip Button
                    TextButton(
                      onPressed: isLoading ? null : _skipRating,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Get descriptive text for rating value
  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent! ⭐';
    if (rating >= 3.5) return 'Great! 👍';
    if (rating >= 2.5) return 'Good 🙂';
    if (rating >= 1.5) return 'Okay 😐';
    return 'Needs Improvement 😕';
  }
}

