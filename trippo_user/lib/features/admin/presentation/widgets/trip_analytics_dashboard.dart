import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/models/ride_request_model.dart';

/// Analytics dashboard widget for trip statistics
class TripAnalyticsDashboard extends StatelessWidget {
  final List<RideRequestModel> rides;

  const TripAnalyticsDashboard({
    super.key,
    required this.rides,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status distribution pie chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride Status Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: _buildStatusPieChart(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Revenue trend line chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Trend (Last 7 Days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: _buildRevenueTrendChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPieChart() {
    final completed = rides.where((r) => r.status.name == 'completed').length;
    final ongoing = rides.where((r) => r.status.name == 'ongoing').length;
    final pending = rides.where((r) => r.status.name == 'pending').length;
    final cancelled = rides.where((r) => r.status.name == 'cancelled').length;

    final total = completed + ongoing + pending + cancelled;
    if (total == 0) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AdminTheme.textSecondary),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: [
          if (completed > 0)
            PieChartSectionData(
              value: completed.toDouble(),
              title: '$completed',
              color: AdminTheme.successColor,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (ongoing > 0)
            PieChartSectionData(
              value: ongoing.toDouble(),
              title: '$ongoing',
              color: AdminTheme.infoColor,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (pending > 0)
            PieChartSectionData(
              value: pending.toDouble(),
              title: '$pending',
              color: AdminTheme.warningColor,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (cancelled > 0)
            PieChartSectionData(
              value: cancelled.toDouble(),
              title: '$cancelled',
              color: AdminTheme.dangerColor,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendChart() {
    // Group rides by date and calculate revenue
    final revenueByDate = <DateTime, double>{};
    
    for (final ride in rides) {
      if (ride.status.name == 'completed') {
        final date = DateTime(
          ride.requestedAt.year,
          ride.requestedAt.month,
          ride.requestedAt.day,
        );
        revenueByDate[date] = (revenueByDate[date] ?? 0) + ride.fare;
      }
    }

    if (revenueByDate.isEmpty) {
      return const Center(
        child: Text(
          'No completed rides yet',
          style: TextStyle(color: AdminTheme.textSecondary),
        ),
      );
    }

    // Sort dates and create spots
    final sortedDates = revenueByDate.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        revenueByDate[entry.value]!,
      );
    }).toList();

    final maxRevenue = revenueByDate.values.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxRevenue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AdminTheme.dividerColor,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AdminTheme.dividerColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedDates.length) return const Text('');
                final date = sortedDates[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxRevenue / 5,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AdminTheme.dividerColor),
        ),
        minX: 0,
        maxX: (sortedDates.length - 1).toDouble(),
        minY: 0,
        maxY: maxRevenue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AdminTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AdminTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

