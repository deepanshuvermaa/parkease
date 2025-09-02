import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/enhanced_business_settings.dart';
import '../models/parking_charges.dart';
import '../providers/vehicle_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'vehicle_exit_screen.dart';

class ParkingQueueScreen extends StatefulWidget {
  const ParkingQueueScreen({super.key});

  @override
  State<ParkingQueueScreen> createState() => _ParkingQueueScreenState();
}

class _ParkingQueueScreenState extends State<ParkingQueueScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.parkingQueue),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<VehicleProvider>(
              builder: (context, vehicleProvider, _) {
                final vehicles = vehicleProvider.searchVehicles(_searchQuery);
                
                if (vehicles.isEmpty) {
                  return _buildEmptyState();
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await vehicleProvider.loadVehicles();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      return _buildVehicleCard(vehicles[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by vehicle number or ticket ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final duration = vehicle.parkingDuration;
    
    // Calculate amount using parking charges settings
    final estimatedAmount = _parkingCharges?.calculateCharge(
      vehicle.vehicleType.displayName, 
      duration
    ) ?? vehicle.calculateAmount();
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _navigateToExit(vehicle),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        vehicle.vehicleType.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
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
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                vehicle.ticketId,
                                style: TextStyle(
                                  fontSize: AppFontSize.xs,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Entry: ${Helpers.formatDateTime(vehicle.entryTime)}',
                          style: const TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        'Duration',
                        Helpers.formatDuration(duration),
                        Icons.access_time,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Est. Amount',
                        Helpers.formatCurrency(estimatedAmount),
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Rate',
                        _getRateDisplay(vehicle),
                        Icons.local_offer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToExit(vehicle),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Process Exit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRateDisplay(Vehicle vehicle) {
    if (_parkingCharges == null) {
      return '${vehicle.rate.toStringAsFixed(0)}/hr';
    }
    
    final rate = _parkingCharges!.getVehicleRate(vehicle.vehicleType.displayName);
    
    switch (_parkingCharges!.chargeType) {
      case ChargeType.oneTime:
        return Helpers.formatCurrency(rate);
      case ChargeType.hourly:
        final duration = _parkingCharges!.timeUnitDuration;
        final unitName = _parkingCharges!.timeUnit.shortName;
        return '${rate.toStringAsFixed(0)}/$duration$unitName';
      case ChargeType.perDay:
        return '${rate.toStringAsFixed(0)}/day';
      case ChargeType.custom:
        return '${rate.toStringAsFixed(0)}';
    }
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isEmpty
                ? 'No vehicles in parking'
                : 'No vehicles found for "$_searchQuery"',
            style: const TextStyle(
              fontSize: AppFontSize.lg,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToExit(Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleExitScreen(vehicle: vehicle),
      ),
    );
  }
}