import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Email Preferences',
          style: context.titleLarge,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.lg),

                  // Master switch
                  _buildSection(
                    children: [
                      _EmailToggleTile(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.info,
                        title: 'Email Notifications',
                        subtitle: 'Receive email notifications from Bananatalk',
                        value: _emailNotifications,
                        onChanged: (value) => _updatePreference('emailNotifications', value),
                        isMasterSwitch: true,
                      ),
                    ],
                  ),

                  // Individual settings (only show when master is ON)
                  if (_emailNotifications) ...[
                    SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: Text(
                        'NOTIFICATION TYPES',
                        style: context.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildSection(
                      children: [
                        _EmailToggleTile(
                          icon: Icons.analytics_outlined,
                          iconColor: AppColors.accent,
                          title: 'Weekly Summary',
                          subtitle: 'Activity recap every Sunday',
                          value: _weeklyDigest,
                          onChanged: (value) => _updatePreference('weeklyDigest', value),
                        ),
                        Divider(height: 1, indent: 60, color: context.dividerColor),
                        _EmailToggleTile(
                          icon: Icons.chat_bubble_outline,
                          iconColor: AppColors.success,
                          title: 'New Messages',
                          subtitle: "When you're away for 24+ hours",
                          value: _newMessageEmails,
                          onChanged: (value) => _updatePreference('newMessageEmails', value),
                        ),
                        Divider(height: 1, indent: 60, color: context.dividerColor),
                        _EmailToggleTile(
                          icon: Icons.person_add_outlined,
                          iconColor: AppColors.warning,
                          title: 'New Followers',
                          subtitle: 'When someone follows you',
                          value: _newFollowerEmails,
                          onChanged: (value) => _updatePreference('newFollowerEmails', value),
                        ),
                        Divider(height: 1, indent: 60, color: context.dividerColor),
                        _EmailToggleTile(
                          icon: Icons.security_outlined,
                          iconColor: AppColors.error,
                          title: 'Security Alerts',
                          subtitle: 'Password & login alerts',
                          value: _securityAlerts,
                          onChanged: (value) => _updatePreference('securityAlerts', value),
                          showRecommendedBadge: true,
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: AppSpacing.xxl),

                  // Info note
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Container(
                      padding: AppSpacing.paddingLG,
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? AppColors.info.withValues(alpha: 0.15) : AppColors.infoLight,
                        borderRadius: AppRadius.borderMD,
                        border: Border.all(
                          color: context.isDarkMode ? AppColors.info.withValues(alpha: 0.3) : AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info, size: 20),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'We recommend keeping Security Alerts enabled to stay informed about important account activity.',
                              style: context.bodySmall.copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderMD,
        boxShadow: context.isDarkMode ? AppShadows.none : AppShadows.sm,
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          SizedBox(width: AppSpacing.md),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: isMasterSwitch ? context.titleMedium : context.titleSmall,
                    ),
                    if (showRecommendedBadge) ...[
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.secondary.withValues(alpha: 0.2)
                              : AppColors.secondaryLight,
                          borderRadius: AppRadius.borderXS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: AppColors.secondaryDark, size: 12),
                            SizedBox(width: AppSpacing.xxs),
                            Text(
                              'Recommended',
                              style: context.captionSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: context.caption,
                  ),
                ],
              ],
            ),
          ),

          // Toggle
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: isMasterSwitch ? AppColors.info : AppColors.success,
          ),
        ],
      ),
    );
  }
}
