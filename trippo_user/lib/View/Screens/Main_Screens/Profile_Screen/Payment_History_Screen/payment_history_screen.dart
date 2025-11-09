import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../data/providers/auth_providers.dart';
import '../../../../../data/providers/ride_providers.dart';
import '../../../../../data/providers/admin_providers.dart';
import '../../../../../data/models/ride_request_model.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
            Tab(text: 'Failed'),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: TabBarView(
        controller: _tabController,
        children: [
          _PaymentsList(filter: PaymentFilter.all),
          _PaymentsList(filter: PaymentFilter.completed),
          _PaymentsList(filter: PaymentFilter.pending),
          _PaymentsList(filter: PaymentFilter.failed),
        ],
      ),
    );
  }
}

enum PaymentFilter { all, completed, pending, failed }

class _PaymentsList extends ConsumerWidget {
  final PaymentFilter filter;

  const _PaymentsList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideHistoryAsync = ref.watch(userRideHistoryProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final invoicesAsync = currentUser != null 
        ? ref.watch(userAdminInvoicesProvider(currentUser.uid))
        : null;

    return rideHistoryAsync.when(
      data: (rides) {
        // Get admin invoices if available
        final invoices = invoicesAsync?.value ?? [];
        
        // Combine rides and invoices
        final allTransactions = _combineTransactions(rides, invoices);
        
        // Filter based on payment status
        final filtered = _filterTransactions(allTransactions);

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        // Calculate totals
        final stats = _calculateStatsFromTransactions(filtered);

        return Column(
          children: [
            // Stats Card
            if (filter == PaymentFilter.all)
              _buildStatsCard(stats),
            
            // Payments List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userRideHistoryProvider);
                  if (currentUser != null) {
                    ref.invalidate(userAdminInvoicesProvider(currentUser.uid));
                  }
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                backgroundColor: Colors.white,
                color: Colors.blue,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final transaction = filtered[index];
                    if (transaction is RideRequestModel) {
                      return _buildPaymentCard(context, transaction);
                    } else if (transaction is AdminInvoice) {
                      return _buildInvoiceCard(context, transaction);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading payment history',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _combineTransactions(List<RideRequestModel> rides, List<AdminInvoice> invoices) {
    final List<dynamic> combined = [...rides, ...invoices];
    // Sort by date (most recent first)
    combined.sort((a, b) {
      final aDate = a is RideRequestModel 
          ? (a.completedAt ?? a.requestedAt)
          : (a as AdminInvoice).createdAt;
      final bDate = b is RideRequestModel 
          ? (b.completedAt ?? b.requestedAt)
          : (b as AdminInvoice).createdAt;
      return bDate.compareTo(aDate);
    });
    return combined;
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    return transactions.where((transaction) {
      String status;
      if (transaction is RideRequestModel) {
        status = transaction.paymentStatus ?? 'pending';
      } else if (transaction is AdminInvoice) {
        status = transaction.status == 'succeeded' ? 'completed' : transaction.status;
      } else {
        return false;
      }

      switch (filter) {
        case PaymentFilter.all:
          return true;
        case PaymentFilter.completed:
          return status == 'completed';
        case PaymentFilter.pending:
          return status == 'pending';
        case PaymentFilter.failed:
          return status == 'failed';
      }
    }).toList();
  }

  Map<String, dynamic> _calculateStatsFromTransactions(List<dynamic> transactions) {
    double totalPaid = 0;
    double totalPending = 0;
    double totalFailed = 0;
    int completedCount = 0;
    int pendingCount = 0;
    int failedCount = 0;

    for (final transaction in transactions) {
      String status;
      double amount;
      
      if (transaction is RideRequestModel) {
        status = transaction.paymentStatus ?? 'pending';
        amount = transaction.fare;
      } else if (transaction is AdminInvoice) {
        status = transaction.status == 'succeeded' ? 'completed' : transaction.status;
        amount = transaction.amount;
      } else {
        continue;
      }

      switch (status) {
        case 'completed':
          totalPaid += amount;
          completedCount++;
          break;
        case 'pending':
          totalPending += amount;
          pendingCount++;
          break;
        case 'failed':
          totalFailed += amount;
          failedCount++;
          break;
      }
    }

    return {
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'totalFailed': totalFailed,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'failedCount': failedCount,
    };
  }

  List<RideRequestModel> _filterRides(List<RideRequestModel> rides) {
    switch (filter) {
      case PaymentFilter.all:
        return rides;
      case PaymentFilter.completed:
        return rides.where((r) => r.paymentStatus == 'completed').toList();
      case PaymentFilter.pending:
        return rides.where((r) => r.paymentStatus == 'pending').toList();
      case PaymentFilter.failed:
        return rides.where((r) => r.paymentStatus == 'failed').toList();
    }
  }

  Map<String, dynamic> _calculateStats(List<RideRequestModel> rides) {
    double totalPaid = 0;
    double totalPending = 0;
    double totalFailed = 0;
    int completedCount = 0;
    int pendingCount = 0;
    int failedCount = 0;

    for (final ride in rides) {
      switch (ride.paymentStatus) {
        case 'completed':
          totalPaid += ride.fare;
          completedCount++;
          break;
        case 'pending':
          totalPending += ride.fare;
          pendingCount++;
          break;
        case 'failed':
          totalFailed += ride.fare;
          failedCount++;
          break;
      }
    }

    return {
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'totalFailed': totalFailed,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'failedCount': failedCount,
    };
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Paid',
                '\$${stats['totalPaid'].toStringAsFixed(2)}',
                '${stats['completedCount']} rides',
                Colors.green,
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                'Pending',
                '\$${stats['totalPending'].toStringAsFixed(2)}',
                '${stats['pendingCount']} rides',
                Colors.orange,
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                'Failed',
                '\$${stats['totalFailed'].toStringAsFixed(2)}',
                '${stats['failedCount']} rides',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.receipt_long;

    switch (filter) {
      case PaymentFilter.all:
        message = 'No payment history yet';
        break;
      case PaymentFilter.completed:
        message = 'No completed payments';
        icon = Icons.check_circle_outline;
        break;
      case PaymentFilter.pending:
        message = 'No pending payments';
        icon = Icons.hourglass_empty;
        break;
      case PaymentFilter.failed:
        message = 'No failed payments';
        icon = Icons.error_outline;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment transactions will appear here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, AdminInvoice invoice) {
    final paymentStatus = invoice.status == 'succeeded' ? 'completed' : invoice.status;
    final statusColor = _getStatusColor(paymentStatus);
    final statusIcon = _getStatusIcon(paymentStatus);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showInvoiceDetails(context, invoice),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Amount and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${invoice.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Admin Invoice',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Row(
                children: [
                  Icon(Icons.description, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invoice.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24, color: Colors.grey),
              
              // Footer: Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    dateFormat.format(invoice.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const Spacer(),
                  Icon(Icons.admin_panel_settings, size: 12, color: Colors.purple[300]),
                  const SizedBox(width: 4),
                  Text(
                    'Admin Charge',
                    style: TextStyle(color: Colors.purple[300], fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, AdminInvoice invoice) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy • hh:mm a');
    final statusColor = invoice.status == 'succeeded' 
        ? Colors.green 
        : (invoice.status == 'failed' ? Colors.red : Colors.orange);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invoice Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Amount
              Center(
                child: Column(
                  children: [
                    Text(
                      '\$${invoice.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (invoice.status == 'succeeded' ? 'COMPLETED' : invoice.status.toUpperCase()),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Details
              _buildInvoiceDetailRow('Type', 'Admin Invoice'),
              _buildInvoiceDetailRow('Description', invoice.description),
              if (invoice.stripePaymentIntentId != null)
                _buildInvoiceDetailRow('Transaction ID', invoice.stripePaymentIntentId!),
              _buildInvoiceDetailRow('Date', dateFormat.format(invoice.createdAt)),
              if (invoice.error != null)
                _buildInvoiceDetailRow('Error', invoice.error!, isError: true),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, RideRequestModel ride) {
    final paymentStatus = ride.paymentStatus ?? 'pending';
    final statusColor = _getStatusColor(paymentStatus);
    final statusIcon = _getStatusIcon(paymentStatus);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPaymentDetails(context, ride),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Amount and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${ride.fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ride.paymentMethod == 'cash' ? 'Cash Payment' : 'Card Payment',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Ride Details
              Row(
                children: [
                  Icon(Icons.trip_origin, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.dropoffAddress,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24, color: Colors.grey),
              
              // Footer: Date and Payment Method Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        ride.completedAt != null
                            ? dateFormat.format(ride.completedAt!)
                            : dateFormat.format(ride.requestedAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  if (ride.paymentMethod == 'card' && ride.paymentMethodLast4 != null)
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '•••• ${ride.paymentMethodLast4}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  void _showPaymentDetails(BuildContext context, RideRequestModel ride) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentDetailsSheet(ride: ride),
    );
  }
}

class _PaymentDetailsSheet extends StatelessWidget {
  final RideRequestModel ride;

  const _PaymentDetailsSheet({required this.ride});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy • hh:mm a');

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Amount
            Center(
              child: Column(
                children: [
                  Text(
                    '\$${ride.fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride.paymentStatus ?? 'pending')
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (ride.paymentStatus ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(ride.paymentStatus ?? 'pending'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Details
            _buildDetailRow('Payment Method', ride.paymentMethod == 'cash' ? 'Cash' : 'Credit Card'),
            if (ride.paymentMethod == 'card' && ride.paymentMethodBrand != null)
              _buildDetailRow('Card Type', ride.paymentMethodBrand!.toUpperCase()),
            if (ride.paymentMethod == 'card' && ride.paymentMethodLast4 != null)
              _buildDetailRow('Card Number', '•••• •••• •••• ${ride.paymentMethodLast4}'),
            if (ride.stripePaymentIntentId != null)
              _buildDetailRow('Transaction ID', ride.stripePaymentIntentId!.substring(0, 20) + '...'),
            
            const Divider(height: 32, color: Colors.grey),
            
            _buildDetailRow('Distance', '${ride.distance.toStringAsFixed(1)} km'),
            _buildDetailRow('Duration', '${ride.duration} min'),
            _buildDetailRow('Vehicle Type', ride.vehicleType),
            
            const Divider(height: 32, color: Colors.grey),
            
            if (ride.completedAt != null)
              _buildDetailRow('Completed', dateFormat.format(ride.completedAt!)),
            _buildDetailRow('Requested', dateFormat.format(ride.requestedAt)),
            
            const SizedBox(height: 24),
            
            // Route
            _buildSectionTitle('Route'),
            const SizedBox(height: 12),
            _buildLocationRow(
              Icons.trip_origin,
              'Pickup',
              ride.pickupAddress,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildLocationRow(
              Icons.location_on,
              'Dropoff',
              ride.dropoffAddress,
              Colors.red,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

