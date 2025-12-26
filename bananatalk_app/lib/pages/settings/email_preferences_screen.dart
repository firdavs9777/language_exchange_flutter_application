import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bananatalk_app/service/endpoints.dart';

/// Email notification preferences screen
class EmailPreferencesScreen extends StatefulWidget {
  const EmailPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<EmailPreferencesScreen> createState() => _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends State<EmailPreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Email preference states
  bool _emailNotifications = true;
  bool _weeklyDigest = true;
  bool _newMessageEmails = true;
  bool _newFollowerEmails = true;
  bool _securityAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Fetch current user details to get preferences
      final url = Uri.parse('${Endpoints.baseURL}auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final privacySettings = data['data']?['privacySettings'] ?? {};
        
        if (mounted) {
          setState(() {
            _emailNotifications = privacySettings['emailNotifications'] ?? true;
            _weeklyDigest = privacySettings['weeklyDigest'] ?? true;
            _newMessageEmails = privacySettings['newMessageEmails'] ?? true;
            _newFollowerEmails = privacySettings['newFollowerEmails'] ?? true;
            _securityAlerts = privacySettings['securityAlerts'] ?? true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Failed to load preferences');
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    // Optimistic update
    setState(() {
      switch (key) {
        case 'emailNotifications':
          _emailNotifications = value;
          break;
        case 'weeklyDigest':
          _weeklyDigest = value;
          break;
        case 'newMessageEmails':
          _newMessageEmails = value;
          break;
        case 'newFollowerEmails':
          _newFollowerEmails = value;
          break;
        case 'securityAlerts':
          _securityAlerts = value;
          break;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.updateDetailsURL}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'privacySettings': {key: value}
        }),
      );

      if (response.statusCode != 200) {
        // Revert on failure
        setState(() {
          switch (key) {
            case 'emailNotifications':
              _emailNotifications = !value;
              break;
            case 'weeklyDigest':
              _weeklyDigest = !value;
              break;
            case 'newMessageEmails':
              _newMessageEmails = !value;
              break;
            case 'newFollowerEmails':
              _newFollowerEmails = !value;
              break;
            case 'securityAlerts':
              _securityAlerts = !value;
              break;
          }
        });
        _showError('Failed to update setting');
      }
    } catch (e) {
      // Revert on error
      setState(() {
        switch (key) {
          case 'emailNotifications':
            _emailNotifications = !value;
            break;
          case 'weeklyDigest':
            _weeklyDigest = !value;
            break;
          case 'newMessageEmails':
            _newMessageEmails = !value;
            break;
          case 'newFollowerEmails':
            _newFollowerEmails = !value;
            break;
          case 'securityAlerts':
            _securityAlerts = !value;
            break;
        }
      });
      _showError('Failed to update setting');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Email Preferences',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Master switch
                  _buildSection(
                    children: [
                      _EmailToggleTile(
                        icon: Icons.email_outlined,
                        iconColor: Colors.blue,
                        title: 'Email Notifications',
                        subtitle: 'Receive email notifications from BananaTalk',
                        value: _emailNotifications,
                        onChanged: (value) => _updatePreference('emailNotifications', value),
                        isMasterSwitch: true,
                      ),
                    ],
                  ),
                  
                  // Individual settings (only show when master is ON)
                  if (_emailNotifications) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'NOTIFICATION TYPES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildSection(
                      children: [
                        _EmailToggleTile(
                          icon: Icons.analytics_outlined,
                          iconColor: Colors.purple,
                          title: 'Weekly Summary',
                          subtitle: 'Activity recap every Sunday',
                          value: _weeklyDigest,
                          onChanged: (value) => _updatePreference('weeklyDigest', value),
                        ),
                        const Divider(height: 1, indent: 60),
                        _EmailToggleTile(
                          icon: Icons.chat_bubble_outline,
                          iconColor: Colors.green,
                          title: 'New Messages',
                          subtitle: "When you're away for 24+ hours",
                          value: _newMessageEmails,
                          onChanged: (value) => _updatePreference('newMessageEmails', value),
                        ),
                        const Divider(height: 1, indent: 60),
                        _EmailToggleTile(
                          icon: Icons.person_add_outlined,
                          iconColor: Colors.orange,
                          title: 'New Followers',
                          subtitle: 'When someone follows you',
                          value: _newFollowerEmails,
                          onChanged: (value) => _updatePreference('newFollowerEmails', value),
                        ),
                        const Divider(height: 1, indent: 60),
                        _EmailToggleTile(
                          icon: Icons.security_outlined,
                          iconColor: Colors.red,
                          title: 'Security Alerts',
                          subtitle: 'Password & login alerts',
                          value: _securityAlerts,
                          onChanged: (value) => _updatePreference('securityAlerts', value),
                          showRecommendedBadge: true,
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Info note
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'We recommend keeping Security Alerts enabled to stay informed about important account activity.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// Toggle tile widget for email preferences
class _EmailToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isMasterSwitch;
  final bool showRecommendedBadge;

  const _EmailToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.isMasterSwitch = false,
    this.showRecommendedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMasterSwitch ? 16 : 15,
                        fontWeight: isMasterSwitch ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (showRecommendedBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber[700], size: 12),
                            const SizedBox(width: 2),
                            Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Toggle
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: isMasterSwitch ? Colors.blue : Colors.green,
          ),
        ],
      ),
    );
  }
}

