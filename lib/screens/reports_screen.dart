import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/enhanced_business_settings.dart';
import '../models/parking_charges.dart';
import '../models/business_settings.dart' as bs;
import '../providers/vehicle_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/pdf_export_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/loading_button.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedFilter = 'week';
  bool _showBillWiseView = false;
  ParkingCharges? _parkingCharges;
  
  @override
  void initState() {
    super.initState();
    _loadParkingCharges();
  }
  
  void _loadParkingCharges() {
    final settings = context.read<SettingsProvider>().settings;
    if (settings is EnhancedBusinessSettings) {
      _parkingCharges = settings.parkingCharges;
    } else {
      _parkingCharges = ParkingCharges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final vehicleProvider = context.read<VehicleProvider>();
              final vehicles = vehicleProvider.getVehiclesByDateRange(_startDate, _endDate);
              
              if (value == 'export') {
                _exportReport(vehicles);
              } else if (value == 'print') {
                _printReport(vehicles);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, _) {
          final vehicles = vehicleProvider.getVehiclesByDateRange(_startDate, _endDate);
          final totalCollection = vehicleProvider.getCollectionByDateRange(_startDate, _endDate);
          final revenueByType = vehicleProvider.getRevenueByVehicleType(_startDate, _endDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildViewToggle(),
                const SizedBox(height: AppSpacing.lg),
                if (_showBillWiseView)
                  _buildBillWiseView(vehicles)
                else ...[
                  _buildSummaryCards(totalCollection, vehicles.length),
                  const SizedBox(height: AppSpacing.lg),
                  _buildVehicleTypeBreakdown(revenueByType),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentTransactions(vehicles),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildDateButton(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Today', 'today'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip('Week', 'week'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip('Month', 'month'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip('Year', 'year'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
            _updateDateRange(value);
          });
        }
      },
    );
  }

  void _updateDateRange(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  Widget _buildSummaryCards(double totalCollection, int totalVehicles) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          title: 'Total Collection',
          value: Helpers.formatCurrency(totalCollection),
          icon: Icons.attach_money,
          color: AppColors.success,
        ),
        _buildSummaryCard(
          title: 'Total Vehicles',
          value: totalVehicles.toString(),
          icon: Icons.directions_car,
          color: AppColors.primary,
        ),
        _buildSummaryCard(
          title: 'Average',
          value: totalVehicles > 0
              ? Helpers.formatCurrency(totalCollection / totalVehicles)
              : 'Rs.0.00',
          icon: Icons.trending_up,
          color: AppColors.warning,
        ),
        _buildSummaryCard(
          title: 'Days',
          value: _endDate.difference(_startDate).inDays.toString(),
          icon: Icons.calendar_today,
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.xs,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeBreakdown(Map<VehicleType, double> revenueByType) {
    final total = revenueByType.values.fold(0.0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue by Vehicle Type',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (revenueByType.isEmpty)
              const Center(
                child: Text(
                  'No data available for selected period',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...revenueByType.entries.map((entry) {
                final type = entry.key;
                final revenue = entry.value;
                final percentage = total > 0 ? (revenue / total * 100) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(type.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: AppSpacing.sm),
                              Text(type.displayName),
                            ],
                          ),
                          Text(
                            Helpers.formatCurrency(revenue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForType(type),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(VehicleType type) {
    switch (type) {
      case VehicleType.cycle:
        return Colors.green;
      case VehicleType.twoWheeler:
        return Colors.blue;
      case VehicleType.fourWheeler:
        return Colors.orange;
      case VehicleType.auto:
        return Colors.purple;
    }
  }

  Widget _buildRecentTransactions(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedVehicles = vehicles.toList()
      ..sort((a, b) => b.exitTime!.compareTo(a.exitTime!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...sortedVehicles.take(10).map((vehicle) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(vehicle.vehicleType.icon),
                ),
                title: Text(vehicle.vehicleNumber),
                subtitle: Text(
                  Helpers.formatDateTime(vehicle.exitTime!),
                ),
                trailing: Text(
                  Helpers.formatCurrency(vehicle.totalAmount ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showBillWiseView = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_showBillWiseView ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: !_showBillWiseView ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Summary View',
                        style: TextStyle(
                          color: !_showBillWiseView ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showBillWiseView = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _showBillWiseView ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: _showBillWiseView ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bill-wise View',
                        style: TextStyle(
                          color: _showBillWiseView ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillWiseView(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No bills found for selected date range',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort vehicles by exit time (most recent first)
    final sortedVehicles = vehicles.toList()
      ..sort((a, b) => (b.exitTime ?? b.entryTime).compareTo(a.exitTime ?? a.entryTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Bills: ${vehicles.length}',
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ${Helpers.formatCurrency(vehicles.fold(0.0, (sum, v) => sum + (v.totalAmount ?? 0)))}',
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...sortedVehicles.map((vehicle) => _buildBillCard(vehicle)).toList(),
      ],
    );
  }

  Widget _buildBillCard(Vehicle vehicle) {
    final isCompleted = vehicle.exitTime != null;
    final duration = isCompleted 
        ? vehicle.exitTime!.difference(vehicle.entryTime)
        : DateTime.now().difference(vehicle.entryTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showBillDetails(vehicle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isCompleted 
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.warning.withOpacity(0.2),
                    child: Text(
                      vehicle.vehicleType.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vehicle.vehicleNumber,
                              style: const TextStyle(
                                fontSize: AppFontSize.lg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCompleted 
                                    ? AppColors.success.withOpacity(0.2)
                                    : AppColors.warning.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCompleted ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ticket: ${vehicle.ticketId}',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Icon(Icons.login, size: 14, color: Colors.grey.shade600),
                            Text(
                              DateFormat('dd/MM HH:mm').format(vehicle.entryTime),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            if (isCompleted) ...[
                              Icon(Icons.logout, size: 14, color: Colors.grey.shade600),
                              Text(
                                DateFormat('dd/MM HH:mm').format(vehicle.exitTime!),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Helpers.formatCurrency(vehicle.totalAmount ?? 0),
                        style: const TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatDuration(duration),
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: Colors.grey.shade600,
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

  void _showBillDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Bill Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Ticket ID:', vehicle.ticketId),
              _buildDetailRow('Vehicle Number:', vehicle.vehicleNumber),
              _buildDetailRow('Vehicle Type:', vehicle.vehicleType.displayName),
              _buildDetailRow('Entry Time:', DateFormat('dd MMM yyyy, HH:mm').format(vehicle.entryTime)),
              if (vehicle.exitTime != null)
                _buildDetailRow('Exit Time:', DateFormat('dd MMM yyyy, HH:mm').format(vehicle.exitTime!)),
              _buildDetailRow(
                'Duration:', 
                vehicle.exitTime != null 
                    ? Helpers.formatDuration(vehicle.exitTime!.difference(vehicle.entryTime))
                    : 'Ongoing'
              ),
              _buildDetailRow('Rate:', _getRateDisplayForVehicle(vehicle)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(vehicle.totalAmount ?? 0),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      onPressed: () {
                        Navigator.pop(context);
                        _printBill(vehicle);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () {
                        Navigator.pop(context);
                        _shareBill(vehicle);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRateDisplayForVehicle(Vehicle vehicle) {
    if (_parkingCharges == null) {
      return '${Helpers.formatCurrency(vehicle.rate)}/hour';
    }
    
    final rate = _parkingCharges!.getVehicleRate(vehicle.vehicleType.displayName);
    final rateDisplay = _parkingCharges!.getRateDisplayText(rate);
    
    if (_parkingCharges!.chargeType == ChargeType.oneTime) {
      return '${Helpers.formatCurrency(rate)} (One Time)';
    } else {
      return '${Helpers.formatCurrency(rate)} $rateDisplay';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printBill(Vehicle vehicle) async {
    try {
      final bluetoothProvider = context.read<BluetoothProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      
      if (bluetoothProvider.isConnected) {
        await bluetoothProvider.printReceipt(vehicle, settingsProvider.settings);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bill sent to printer'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No printer connected'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareBill(Vehicle vehicle) async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final settings = settingsProvider.settings;
      
      String billText = '''
PARKING RECEIPT
================
${settings.businessName}
${settings.address}, ${settings.city}

Ticket ID: ${vehicle.ticketId}
Vehicle: ${vehicle.vehicleNumber}
Type: ${vehicle.vehicleType.displayName}

Entry: ${DateFormat('dd/MM/yyyy HH:mm').format(vehicle.entryTime)}
${vehicle.exitTime != null ? 'Exit: ${DateFormat('dd/MM/yyyy HH:mm').format(vehicle.exitTime!)}' : 'Status: Active'}

Duration: ${vehicle.exitTime != null ? Helpers.formatDuration(vehicle.exitTime!.difference(vehicle.entryTime)) : 'Ongoing'}
Rate: ${_getRateDisplayForVehicle(vehicle)}

Total: ${Helpers.formatCurrency(vehicle.totalAmount ?? 0)}
================
Thank you!
      ''';
      
      // You can implement share functionality here
      // For now, just copy to clipboard
      await Clipboard.setData(ClipboardData(text: billText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
        _selectedFilter = 'custom';
      });
    }
  }

  Future<void> _exportReport(List<Vehicle> vehicles) async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final settings = settingsProvider.settings;
      
      EnhancedBusinessSettings enhancedSettings;
      if (settings is EnhancedBusinessSettings) {
        enhancedSettings = settings;
      } else {
        // Convert PaperSize from business_settings to enhanced_business_settings  
        bs.PaperSize convertedPaperSize;
        if (settings.paperSize.toString() == 'PaperSize.mm58') {
          convertedPaperSize = bs.PaperSize.mm58;
        } else {
          convertedPaperSize = bs.PaperSize.mm80;
        }
        
        enhancedSettings = EnhancedBusinessSettings(
          businessName: settings.businessName,
          address: settings.address,
          city: settings.city,
          contactNumber: settings.contactNumber,
          showContactOnReceipt: settings.showContactOnReceipt,
          paperSize: convertedPaperSize,
          autoPrint: settings.autoPrint,
          primaryPrinterId: settings.primaryPrinterId,
        );
      }

      final pdfFile = await PdfExportService.generateParkingReport(
        vehicles: vehicles,
        settings: enhancedSettings,
        fromDate: _startDate,
        toDate: _endDate,
      );

      await PdfExportService.shareReport(
        pdfFile,
        'Parking Report (${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)})',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _printReport(List<Vehicle> vehicles) async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final settings = settingsProvider.settings;
      
      EnhancedBusinessSettings enhancedSettings;
      if (settings is EnhancedBusinessSettings) {
        enhancedSettings = settings;
      } else {
        // Convert PaperSize from business_settings to enhanced_business_settings  
        bs.PaperSize convertedPaperSize;
        if (settings.paperSize.toString() == 'PaperSize.mm58') {
          convertedPaperSize = bs.PaperSize.mm58;
        } else {
          convertedPaperSize = bs.PaperSize.mm80;
        }
        
        enhancedSettings = EnhancedBusinessSettings(
          businessName: settings.businessName,
          address: settings.address,
          city: settings.city,
          contactNumber: settings.contactNumber,
          showContactOnReceipt: settings.showContactOnReceipt,
          paperSize: convertedPaperSize,
          autoPrint: settings.autoPrint,
          primaryPrinterId: settings.primaryPrinterId,
        );
      }

      final pdfFile = await PdfExportService.generateParkingReport(
        vehicles: vehicles,
        settings: enhancedSettings,
        fromDate: _startDate,
        toDate: _endDate,
      );

      await PdfExportService.printReport(pdfFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent to printer!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print report: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}