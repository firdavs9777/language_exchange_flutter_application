import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';

class VisitorUsageIndicator extends StatelessWidget {
  final VisitorLimitations limitations;
  final bool compact;

  const VisitorUsageIndicator({
    Key? key,
    required this.limitations,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildFullView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Visitor Mode - Daily Limits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLimitItem(
              context: context,
              icon: Icons.message,
              label: 'Messages',
              used: limitations.messagesSentToday,
              total: limitations.dailyMessageLimit,
            ),
            const SizedBox(height: 12),
            _buildLimitItem(
              context: context,
              icon: Icons.visibility,
              label: 'Profile Views',
              used: limitations.profileViewsToday,
              total: limitations.dailyProfileViewLimit,
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade your account for unlimited access',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.message,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${limitations.remainingMessages}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.visibility,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${limitations.remainingProfileViews}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int used,
    required int total,
  }) {
    final remaining = total - used;
    final percentage = used / total;
    final isLow = percentage > 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isLow ? Colors.orange : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$remaining left',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isLow ? Colors.orange : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isLow ? Colors.orange : Theme.of(context).primaryColor,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$used / $total used',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class VisitorBadge extends StatelessWidget {
  const VisitorBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 14,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Visitor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class VipBadge extends StatelessWidget {
  const VipBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
