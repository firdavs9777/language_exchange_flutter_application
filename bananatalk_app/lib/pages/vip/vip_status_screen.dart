import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/vip_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class VipStatusScreen extends StatefulWidget {
  final String userId;

  const VipStatusScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<VipStatusScreen> createState() => _VipStatusScreenState();
}

class _VipStatusScreenState extends State<VipStatusScreen> {
  VipSubscription? subscription;
  VipFeatures? features;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadVipStatus();
  }

  Future<void> _loadVipStatus() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await VipService.getVipStatus(userId: widget.userId);

    if (result['success']) {
      setState(() {
        subscription = result['vipSubscription'];
        features = result['vipFeatures'];
        isLoading = false;
      });
    } else {
      setState(() {
        error = result['error'];
        isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelVIPSubscription),
        content: const Text(
          'Are you sure you want to cancel your VIP subscription? You will lose access to all VIP features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.keepVIP),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.cancelSubscription),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        isLoading = true;
      });

      final result =
          await VipService.deactivateVip(userId: widget.userId);

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppLocalizations.of(context)!.vipSubscriptionCancelledSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to cancel subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.vipStatus),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.vipStatus),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVipStatus,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (subscription == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.vipStatus),
        ),
        body: const Center(
          child: Text(AppLocalizations.of(context)!.noActiveVIPSubscription),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP Status'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // VIP Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'VIP Member',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subscription!.plan.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subscription Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Status',
                    (subscription!.status ?? 'unknown').toUpperCase(),
                    statusColor: subscription!.status == 'active'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  _buildDetailRow(
                    'Plan',
                    subscription!.plan,
                  ),
                  _buildDetailRow(
                    'Start Date',
                    DateFormat('MMM dd, yyyy').format(subscription!.startDate),
                  ),
                  _buildDetailRow(
                    'End Date',
                    DateFormat('MMM dd, yyyy').format(subscription!.endDate),
                  ),
                  _buildDetailRow(
                    'Amount',
                    '\$${subscription!.amount}',
                  ),
                  _buildDetailRow(
                    'Length',
                    _getSubscriptionLength(subscription!.plan),
                  ),
                ],
              ),
            ),

            // Legal Links (required for App Store)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/terms-of-use'),
                            icon: const Icon(Icons.description_outlined, size: 18),
                            label: const Text(
                              'Terms of Use',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launchURL('https://banatalk.com/privacy-policy'),
                            icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                            label: const Text(
                              'Privacy Policy',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your subscription in your device Account Settings. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Active Features
            if (features != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (features!.unlimitedMessages)
                      _buildFeatureItem(
                        icon: Icons.message,
                        title: AppLocalizations.of(context)!.unlimitedMessages,
                      ),
                    if (features!.unlimitedProfileViews)
                      _buildFeatureItem(
                        icon: Icons.visibility,
                        title: AppLocalizations.of(context)!.unlimitedProfileViews,
                      ),
                    if (features!.prioritySupport)
                      _buildFeatureItem(
                        icon: Icons.support_agent,
                        title: AppLocalizations.of(context)!.prioritySupport,
                      ),
                    if (features!.advancedSearch)
                      _buildFeatureItem(
                        icon: Icons.search,
                        title: AppLocalizations.of(context)!.advancedSearch,
                      ),
                    if (features!.profileBoost)
                      _buildFeatureItem(
                        icon: Icons.trending_up,
                        title: AppLocalizations.of(context)!.profileBoost,
                      ),
                    if (features!.adFree)
                      _buildFeatureItem(
                        icon: Icons.block,
                        title: AppLocalizations.of(context)!.adFreeExperience,
                      ),
                  ],
                ),
              ),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _cancelSubscription,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel Subscription',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionLength(String plan) {
    switch (plan.toLowerCase()) {
      case 'monthly':
        return '1 month';
      case 'quarterly':
        return '3 months';
      case 'yearly':
      case 'annual':
        return '1 year';
      default:
        return plan;
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
