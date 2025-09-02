import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_button.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isTrialExpired;
  
  const SubscriptionScreen({
    super.key,
    this.isTrialExpired = false,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to most popular
  bool _isProcessing = false;
  
  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Monthly',
      'price': 499,
      'duration': 1,
      'savings': null,
      'popular': false,
    },
    {
      'title': 'Quarterly',
      'price': 1299,
      'duration': 3,
      'savings': '13% OFF',
      'popular': true,
    },
    {
      'title': 'Yearly',
      'price': 4799,
      'duration': 12,
      'savings': '20% OFF',
      'popular': false,
    },
  ];

  Future<void> _processPurchase() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment process
    await Future.delayed(const Duration(seconds: 2));

    // In real app, you would integrate with payment gateway here
    // For now, we'll simulate a successful payment
    final authProvider = context.read<AuthProvider>();
    final plan = _plans[_selectedPlanIndex];
    final success = await authProvider.upgradeToSubscription(
      'PAY_${DateTime.now().millisecondsSinceEpoch}',
      plan['duration'],
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Text('Payment Successful!'),
              ],
            ),
            content: const Text(
              'Your subscription has been activated. Enjoy unlimited access to all features!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.isTrialExpired) {
                    Navigator.of(context).pop(); // Go back to dashboard
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trial status banner
            if (authProvider.isGuest)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isTrialExpired 
                      ? Colors.red.shade50 
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isTrialExpired 
                        ? Colors.red.shade300 
                        : Colors.blue.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isTrialExpired 
                          ? Icons.warning_amber_rounded 
                          : Icons.info_outline,
                      color: widget.isTrialExpired 
                          ? Colors.red.shade700 
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isTrialExpired
                                ? 'Your trial has expired'
                                : 'Trial Period Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isTrialExpired 
                                  ? Colors.red.shade700 
                                  : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isTrialExpired
                                ? 'Subscribe now to continue using the app'
                                : '${authProvider.remainingTrialDays} days remaining in your trial',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isTrialExpired 
                                  ? Colors.red.shade600 
                                  : Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Unlock Full Access',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the plan that works best for you',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Pricing cards
            ...List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final isSelected = _selectedPlanIndex == index;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlanIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.05) 
                              : Colors.white,
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.primary 
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Radio button
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected 
                                      ? AppColors.primary 
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            
                            // Plan details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        plan['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (plan['savings'] != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            plan['savings'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${plan['price']} for ${plan['duration']} ${plan['duration'] == 1 ? 'month' : 'months'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Price
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${plan['price']}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? AppColors.primary 
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  '₹${(plan['price'] / plan['duration']).toStringAsFixed(0)}/mo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Popular badge
                      if (plan['popular'])
                        Positioned(
                          top: -8,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'MOST POPULAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Features list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All plans include:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeature('Unlimited vehicle entries'),
                  _buildFeature('Bluetooth printer support'),
                  _buildFeature('Custom pricing & vehicle types'),
                  _buildFeature('Detailed reports & analytics'),
                  _buildFeature('Multi-user support'),
                  _buildFeature('Data backup & restore'),
                  _buildFeature('24/7 customer support'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Purchase button
            LoadingButton(
              isLoading: _isProcessing,
              onPressed: _processPurchase,
              child: Text(
                'Subscribe for ₹${_plans[_selectedPlanIndex]['price']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.cancel, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Cancel Anytime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}