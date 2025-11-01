import 'package:flutter/material.dart';

/// Interactive star rating widget
/// Can be used for both input (selecting rating) and display (showing rating)
class StarRating extends StatelessWidget {
  /// Current rating value (0.0 - 5.0)
  final double rating;
  
  /// Callback when rating changes (null for read-only mode)
  final ValueChanged<double>? onRatingChanged;
  
  /// Size of each star
  final double size;
  
  /// Color of filled stars
  final Color color;
  
  /// Color of empty stars
  final Color emptyColor;
  
  /// Whether to allow interaction
  final bool readOnly;
  
  /// Number of stars to display
  final int starCount;

  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 40.0,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.readOnly = false,
    this.starCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return GestureDetector(
          onTap: readOnly || onRatingChanged == null
              ? null
              : () {
                  final newRating = (index + 1).toDouble();
                  onRatingChanged!(newRating);
                },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.05),
            child: Icon(
              index < rating.floor()
                  ? Icons.star
                  : (index < rating && rating % 1 >= 0.5)
                      ? Icons.star_half
                      : Icons.star_border,
              size: size,
              color: index < rating ? color : emptyColor,
            ),
          ),
        );
      }),
    );
  }
}

/// Compact star rating display (for lists)
class CompactStarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const CompactStarRating({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size,
          color: color,
        ),
        SizedBox(width: size * 0.25),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

