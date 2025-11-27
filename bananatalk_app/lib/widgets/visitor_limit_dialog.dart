import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/visitor_upgrade_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';

class VisitorLimitDialog extends StatelessWidget {
  final String userId;
  final String limitType;
  final VisitorLimitations limitations;

  const VisitorLimitDialog({
    Key? key,
    required this.userId,
    required this.limitType,
    required this.limitations,
  }) : super(key: key);

  static Future<bool?> show({
    required BuildContext context,
    required String userId,
    required String limitType,
    required VisitorLimitations limitations,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VisitorLimitDialog(
        userId: userId,
        limitType: limitType,
        limitations: limitations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String message;
    IconData icon;

    if (limitType == 'message') {
      title = 'Daily Message Limit Reached';
      message =
          'You have sent ${limitations.messagesSentToday} messages today. Upgrade to send more!';
      icon = Icons.message;
    } else {
      title = 'Daily Profile View Limit Reached';
      message =
          'You have viewed ${limitations.profileViewsToday} profiles today. Upgrade to view more!';
      icon = Icons.visibility;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose an option:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Free Account Option
                  _buildOptionCard(
                    context: context,
                    icon: Icons.person,
                    title: 'Create Free Account',
                    description: 'Higher daily limits',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).pop(false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitorUpgradeScreen(
                            userId: userId,
                            limitMessage: message,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // VIP Option
                  _buildOptionCard(
                    context: context,
                    icon: Icons.workspace_premium,
                    title: 'Go VIP',
                    description: 'Unlimited access',
                    color: Colors.amber[700]!,
                    onTap: () {
                      Navigator.of(context).pop(false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VipPlansScreen(
                            userId: userId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Maybe Later'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
