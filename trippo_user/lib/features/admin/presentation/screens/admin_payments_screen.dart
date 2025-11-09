import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../data/providers/admin_providers.dart';
import '../../../../data/providers/stripe_providers.dart';
import '../../../../data/models/ride_request_model.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_search_bar.dart';

/// Admin screen for managing payments and invoicing
class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with stats
        Container(
          padding: const EdgeInsets.all(16),
          color: AdminTheme.primaryColor.withOpacity(0.1),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: AdminTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref.invalidate(allRidesProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOverallStats(),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: AdminSearchBar(
            hintText: 'Search by user email, amount, or transaction ID...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'User Payments'),
            Tab(text: 'Driver Earnings'),
            Tab(text: 'Invoicing'),
          ],
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _UserPaymentsTab(searchQuery: _searchQuery),
              _DriverEarningsTab(searchQuery: _searchQuery),
              _InvoicingTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallStats() {
    final allRidesAsync = ref.watch(allRidesProvider);

    return allRidesAsync.when(
      data: (rides) {
        final stats = _calculatePaymentStats(rides);
        
        return Row(
          children: [
            Expanded(
              child: AdminStatsCard(
                title: 'Total Revenue',
                value: '\$${stats['totalRevenue'].toStringAsFixed(2)}',
                icon: Icons.monetization_on,
                iconColor: Colors.green,
                subtitle: '${stats['completedCount']} completed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatsCard(
                title: 'Pending',
                value: '\$${stats['totalPending'].toStringAsFixed(2)}',
                icon: Icons.hourglass_empty,
                iconColor: Colors.orange,
                subtitle: '${stats['pendingCount']} pending',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatsCard(
                title: 'Failed',
                value: '\$${stats['totalFailed'].toStringAsFixed(2)}',
                icon: Icons.error_outline,
                iconColor: Colors.red,
                subtitle: '${stats['failedCount']} failed',
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Map<String, dynamic> _calculatePaymentStats(List<RideRequestModel> rides) {
    double totalRevenue = 0;
    double totalPending = 0;
    double totalFailed = 0;
    int completedCount = 0;
    int pendingCount = 0;
    int failedCount = 0;

    for (final ride in rides) {
      final status = ride.paymentStatus ?? 'pending';
      switch (status) {
        case 'completed':
          totalRevenue += ride.fare;
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
      'totalRevenue': totalRevenue,
      'totalPending': totalPending,
      'totalFailed': totalFailed,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'failedCount': failedCount,
    };
  }
}

/// Tab showing all user payments
class _UserPaymentsTab extends ConsumerWidget {
  final String searchQuery;

  const _UserPaymentsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRidesAsync = ref.watch(allRidesProvider);

    return allRidesAsync.when(
      data: (rides) {
        // Filter rides to show user payments
        var filtered = rides.where((r) => r.userId.isNotEmpty).toList();

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          filtered = filtered.where((ride) {
            return ride.userEmail.toLowerCase().contains(searchQuery) ||
                ride.fare.toString().contains(searchQuery) ||
                (ride.stripePaymentIntentId?.toLowerCase().contains(searchQuery) ?? false);
          }).toList();
        }

        // Sort by most recent
        filtered.sort((a, b) => (b.completedAt ?? b.requestedAt)
            .compareTo(a.completedAt ?? a.requestedAt));

        if (filtered.isEmpty) {
          return const Center(
            child: Text('No user payments found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final ride = filtered[index];
            return _PaymentCard(ride: ride, isDriverView: false);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

/// Tab showing driver earnings
class _DriverEarningsTab extends ConsumerWidget {
  final String searchQuery;

  const _DriverEarningsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDriversAsync = ref.watch(allDriversWithEarningsProvider);

    return allDriversAsync.when(
      data: (drivers) {
        // Apply search filter
        var filtered = drivers;
        if (searchQuery.isNotEmpty) {
          filtered = drivers.where((driverWithEmail) {
            return driverWithEmail.email.toLowerCase().contains(searchQuery) ||
                driverWithEmail.driver.carPlateNum.toLowerCase().contains(searchQuery) ||
                driverWithEmail.driver.earnings.toString().contains(searchQuery);
          }).toList();
        }

        // Already sorted by earnings from provider

        if (filtered.isEmpty) {
          return const Center(
            child: Text('No driver earnings found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final driverData = filtered[index];
            return _DriverEarningsCard(driverData: driverData);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

/// Tab for one-off invoicing
class _InvoicingTab extends ConsumerStatefulWidget {
  const _InvoicingTab();

  @override
  ConsumerState<_InvoicingTab> createState() => _InvoicingTabState();
}

class _InvoicingTabState extends ConsumerState<_InvoicingTab> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.receipt_long, size: 32, color: AdminTheme.primaryColor),
              SizedBox(width: 12),
              Text(
                'One-Off Invoicing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Charge a customer\'s card for custom amounts (fees, penalties, adjustments)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Form Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Email
                  const Text(
                    'Customer Email',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Amount
                  const Text(
                    'Amount (USD)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      hintText: '25.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Late fee, Adjustment, Custom charge',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processInvoice,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isProcessing ? 'Processing...' : 'Charge Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This will immediately charge the customer\'s default payment method. Make sure the amount and description are correct.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Invoices Section
          const Text(
            'Recent Manual Invoices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRecentInvoices(),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices() {
    final invoicesAsync = ref.watch(allAdminInvoicesProvider);

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No invoices yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        // Show recent 10 invoices
        final recentInvoices = invoices.take(10).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Customer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Text(
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Invoice rows
              ...recentInvoices.map((invoice) => _buildInvoiceRow(invoice)),
            ],
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error loading invoices: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(AdminInvoice invoice) {
    final dateFormat = DateFormat('MMM dd, yy');
    final statusColor = invoice.status == 'succeeded' 
        ? Colors.green 
        : (invoice.status == 'failed' ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Text(
            dateFormat.format(invoice.createdAt),
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              invoice.userEmail,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invoice.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${invoice.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              invoice.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processInvoice() async {
    final email = _emailController.text.trim();
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    // Validation
    if (email.isEmpty || amountText.isEmpty || description.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: $email'),
            Text('Amount: \$${amount.toStringAsFixed(2)}'),
            Text('Description: $description'),
            const SizedBox(height: 16),
            const Text(
              'This will immediately charge the customer\'s card. Continue?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
            ),
            child: const Text('Charge Card'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final stripeRepo = ref.read(stripeRepositoryProvider);
      
      // Call cloud function to process invoice
      await stripeRepo.processAdminInvoice(
        userEmail: email,
        amount: amount,
        description: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invoice processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _emailController.clear();
        _amountController.clear();
        _descriptionController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to process invoice: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Payment card widget for displaying user payments
class _PaymentCard extends StatelessWidget {
  final RideRequestModel ride;
  final bool isDriverView;

  const _PaymentCard({
    required this.ride,
    required this.isDriverView,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ride.paymentStatus ?? 'pending');
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
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
        onTap: () => _showPaymentDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(ride.paymentStatus ?? 'pending'),
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${ride.fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ride.paymentMethod == 'cash' ? 'Cash' : 'Card',
                            style: TextStyle(
                              color: Colors.grey[600],
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
                      (ride.paymentStatus ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // User/Driver Info
              Row(
                children: [
                  Icon(
                    isDriverView ? Icons.person : Icons.local_taxi,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDriverView ? ride.driverEmail ?? 'N/A' : ride.userEmail,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Route
              Row(
                children: [
                  Icon(Icons.trip_origin, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.dropoffAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Footer
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  if (ride.paymentMethodLast4 != null)
                    Text(
                      '•••• ${ride.paymentMethodLast4}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PaymentDetailsDialog(ride: ride),
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
}

/// Driver earnings card
class _DriverEarningsCard extends StatelessWidget {
  final DriverWithEmail driverData;

  const _DriverEarningsCard({required this.driverData});

  @override
  Widget build(BuildContext context) {
    final driver = driverData.driver;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Driver Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_taxi,
                color: Colors.green,
                size: 32,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Driver Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverData.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${driver.carName} • ${driver.carPlateNum}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${driver.rating.toStringAsFixed(1)} • ${driver.totalRides} rides',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Earnings
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${driver.earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Total Earnings',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment details dialog
class _PaymentDetailsDialog extends StatelessWidget {
  final RideRequestModel ride;

  const _PaymentDetailsDialog({required this.ride});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy • hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '\$${ride.fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
                    
                    const SizedBox(height: 24),
                    
                    _buildDetailRow('User', ride.userEmail),
                    if (ride.driverEmail != null)
                      _buildDetailRow('Driver', ride.driverEmail!),
                    _buildDetailRow('Payment Method', ride.paymentMethod == 'cash' ? 'Cash' : 'Credit Card'),
                    if (ride.paymentMethodBrand != null)
                      _buildDetailRow('Card Type', ride.paymentMethodBrand!.toUpperCase()),
                    if (ride.paymentMethodLast4 != null)
                      _buildDetailRow('Card', '•••• ${ride.paymentMethodLast4}'),
                    if (ride.stripePaymentIntentId != null)
                      _buildDetailRow('Stripe ID', ride.stripePaymentIntentId!),
                    
                    const Divider(height: 32),
                    
                    _buildDetailRow('Distance', '${ride.distance.toStringAsFixed(1)} km'),
                    _buildDetailRow('Duration', '${ride.duration} min'),
                    _buildDetailRow('Vehicle', ride.vehicleType),
                    
                    const Divider(height: 32),
                    
                    if (ride.completedAt != null)
                      _buildDetailRow('Completed', dateFormat.format(ride.completedAt!)),
                    _buildDetailRow('Requested', dateFormat.format(ride.requestedAt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
}

