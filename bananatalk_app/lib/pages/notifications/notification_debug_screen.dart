import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationDebugScreen extends ConsumerStatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  ConsumerState<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState
    extends ConsumerState<NotificationDebugScreen> {
  final NotificationService _notificationService = NotificationService();
  final NotificationApiClient _apiClient = NotificationApiClient();
  
  String? _fcmToken;
  bool? _hasPermission;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final token = _notificationService.fcmToken;
    final hasPermission = await _notificationService.hasPermission();
    final deviceId = await _notificationService.getDeviceId();

    setState(() {
      _fcmToken = token;
      _hasPermission = hasPermission;
      _deviceId = deviceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final badgeCount = ref.watch(badgeCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationDebug),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildBadgeCard(badgeCount),
          const SizedBox(height: 16),
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Permission Status', _hasPermission == true
                ? '✅ Granted'
                : _hasPermission == false
                    ? '❌ Denied'
                    : '⏳ Loading...'),
            const Divider(),
            _buildInfoRow('Device ID', _deviceId ?? 'Loading...'),
            const Divider(),
            _buildExpandableInfoRow('FCM Token', _fcmToken ?? 'Not available'),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(badgeCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badge Counts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Messages', badgeCount.messages.toString()),
            const Divider(),
            _buildInfoRow('Notifications', badgeCount.notifications.toString()),
            const Divider(),
            _buildInfoRow('Total', badgeCount.total.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              'Request Permission',
              Icons.notifications_active,
              () async {
                await _notificationService.initialize();
                await _loadDebugInfo();
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Open Settings',
              Icons.settings,
              () async {
                await _notificationService.openSettings();
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Refresh Info',
              Icons.refresh,
              () async {
                await _loadDebugInfo();
                ref.read(badgeCountProvider.notifier).fetchBadgeCount();
              },
            ),
            const Divider(height: 32),
            const Text(
              'Send Test Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Test Chat Message',
              Icons.chat,
              () => _sendTestNotification('chat_message'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Test Moment Like',
              Icons.favorite,
              () => _sendTestNotification('moment_like'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Test Moment Comment',
              Icons.comment,
              () => _sendTestNotification('moment_comment'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Test Friend Request',
              Icons.person_add,
              () => _sendTestNotification('friend_request'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Test Profile Visit',
              Icons.visibility,
              () => _sendTestNotification('profile_visit'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              'Test System',
              Icons.info,
              () => _sendTestNotification('system'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableInfoRow(String label, String value) {
    return ExpansionTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SelectableText(
                value,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(AppLocalizations.of(context)!.copy),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _sendTestNotification(String type) async {
    try {
      final result = await _apiClient.sendTestNotification(type: type);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification sent: $type'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

