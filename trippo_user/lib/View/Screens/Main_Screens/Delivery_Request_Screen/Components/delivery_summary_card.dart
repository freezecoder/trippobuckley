import 'package:flutter/material.dart';
import 'package:btrips_unified/Model/direction_model.dart';
import 'package:btrips_unified/core/utils/delivery_helpers.dart';

/// Widget to display delivery summary before confirmation
class DeliverySummaryCard extends StatelessWidget {
  final Direction? pickupLocation;
  final Direction? dropoffLocation;
  final String? category;
  final String? itemsDescription;
  final double itemCost;
  final double? deliveryFee;
  final double? distance;

  const DeliverySummaryCard({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.category,
    required this.itemsDescription,
    required this.itemCost,
    required this.deliveryFee,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final total = (deliveryFee ?? 0) + itemCost;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Category
          if (category != null)
            _buildInfoRow(
              icon: Icons.category,
              label: 'Category',
              value: '${DeliveryHelpers.getCategoryIcon(category!)} ${DeliveryHelpers.getCategoryDisplayName(category!)}',
            ),
          
          const SizedBox(height: 12),
          
          // Pickup Location
          if (pickupLocation != null)
            _buildInfoRow(
              icon: Icons.store,
              label: 'Pickup From',
              value: pickupLocation!.locationName ?? pickupLocation!.humanReadableAddress ?? 'Unknown',
              valueColor: Colors.orange[300],
            ),
          
          const SizedBox(height: 12),
          
          // Dropoff Location
          if (dropoffLocation != null)
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Deliver To',
              value: dropoffLocation!.locationName ?? dropoffLocation!.humanReadableAddress ?? 'Unknown',
              valueColor: Colors.green[300],
            ),
          
          const SizedBox(height: 12),
          
          // Items Description
          if (itemsDescription != null && itemsDescription!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.shopping_bag,
              label: 'Items',
              value: itemsDescription!,
              maxLines: 3,
            ),
          
          const SizedBox(height: 16),
          
          Divider(color: Colors.grey[800]),
          
          const SizedBox(height: 16),
          
          // Distance
          if (distance != null)
            _buildPriceRow(
              label: 'Distance',
              value: '${distance!.toStringAsFixed(1)} mi',
              isHighlight: false,
            ),
          
          const SizedBox(height: 8),
          
          // Item Cost
          if (itemCost > 0)
            _buildPriceRow(
              label: 'Item Cost',
              value: '\$${itemCost.toStringAsFixed(2)}',
              isHighlight: false,
            ),
          
          const SizedBox(height: 8),
          
          // Delivery Fee
          if (deliveryFee != null)
            _buildPriceRow(
              label: 'Delivery Fee',
              value: '\$${deliveryFee!.toStringAsFixed(2)}',
              isHighlight: false,
            ),
          
          const SizedBox(height: 12),
          
          Divider(color: Colors.grey[700], thickness: 2),
          
          const SizedBox(height: 12),
          
          // Total
          _buildPriceRow(
            label: 'Total',
            value: '\$${total.toStringAsFixed(2)}',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    required bool isHighlight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? Colors.white : Colors.grey[400],
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? Colors.orange : Colors.white,
            fontSize: isHighlight ? 22 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

