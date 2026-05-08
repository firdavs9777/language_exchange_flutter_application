import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/settings/widgets/settings_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, bool>? _prefs;
  bool _isLoading = true;
  String? _error;

  static const List<String> _keys = [
    'chat',
    'wave',
    'voiceRoomStart',
    'scheduledRoomReminder',
    'followerMoment',
    'visitorAlert',
    'matchAlert',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await ref
          .read(communityServiceProvider)
          .getNotificationPreferences();
      final filled = <String, bool>{};
      for (final key in _keys) {
        filled[key] = prefs[key] ?? true;
      }
      if (!mounted) return;
      setState(() {
        _prefs = filled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    if (_prefs == null) return;
    final old = Map<String, bool>.from(_prefs!);
    setState(() => _prefs![key] = value);
    try {
      await ref
          .read(communityServiceProvider)
          .updateNotificationPreferences({key: value});
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = old);
      showSettingsSnackBar(
        context,
        message: 'Failed to update preference',
        type: SettingsSnackBarType.error,
      );
    }
  }

  Future<void> _resetDefaults() async {
    final defaults = {for (final k in _keys) k: true};
    final old = _prefs == null ? null : Map<String, bool>.from(_prefs!);
    setState(() => _prefs = defaults);
    try {
      await ref
          .read(communityServiceProvider)
          .updateNotificationPreferences(defaults);
    } catch (e) {
      if (!mounted) return;
      if (old != null) setState(() => _prefs = old);
      showSettingsSnackBar(
        context,
        message: 'Failed to reset preferences',
        type: SettingsSnackBarType.error,
      );
    }
  }

  String _labelFor(String key, AppLocalizations l10n) {
    return switch (key) {
      'chat' => l10n.notifPrefChat,
      'wave' => l10n.notifPrefWave,
      'voiceRoomStart' => l10n.notifPrefVoiceRoomStart,
      'scheduledRoomReminder' => l10n.notifPrefScheduledRoomReminder,
      'followerMoment' => l10n.notifPrefFollowerMoment,
      'visitorAlert' => l10n.notifPrefVisitorAlert,
      'matchAlert' => l10n.notifPrefMatchAlert,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.notificationPreferencesTitle),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: context.bodyMedium
                              .copyWith(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.notificationPreferencesSubtitle,
                        style: context.bodyMedium
                            .copyWith(color: context.textSecondary),
                      ),
                    ),
                    for (final key in _keys)
                      SwitchListTile(
                        title: Text(_labelFor(key, l10n),
                            style: context.bodyMedium),
                        value: _prefs![key]!,
                        onChanged: (v) => _toggle(key, v),
                        activeThumbColor: AppColors.primary,
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: _resetDefaults,
                        child: Text(l10n.notifResetToDefaults),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}
