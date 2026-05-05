import 'package:app_settings/app_settings.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          l10n.notificationSettings,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, ref, settings, l10n),
        loading: () => _buildLoadingState(context),
        error: (error, stack) =>
            _buildErrorState(context, ref, error.toString(), l10n),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero status card
          _buildStatusCard(context, ref, settings, l10n),
          const SizedBox(height: 24),

          // Notification Types
          _buildSectionTitle(
            context,
            l10n.notificationTypes,
            Icons.notifications_active_rounded,
            const Color(0xFF2196F3),
          ),
          const SizedBox(height: 10),
          _buildSectionContainer(context, [
            _buildToggleTile(
              context: context,
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF4CAF50),
              title: l10n.chatMessages,
              subtitle: l10n.getNotifiedWhenYouReceiveMessages,
              value: settings.chatMessages && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('chatMessages', value);
              },
              isFirst: true,
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFE91E63),
              title: l10n.moments,
              subtitle: l10n.likesAndCommentsOnYourMoments,
              value: settings.moments && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('moments', value);
              },
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.dynamic_feed_rounded,
              iconColor: const Color(0xFF7C4DFF),
              title: l10n.followerMoments,
              subtitle: l10n.whenPeopleYouFollowPost,
              value: settings.followerMoments && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('followerMoments', value);
              },
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.person_add_rounded,
              iconColor: const Color(0xFF00BCD4),
              title: l10n.friendRequests,
              subtitle: l10n.whenSomeoneFollowsYou,
              value: settings.friendRequests && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('friendRequests', value);
              },
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.visibility_rounded,
              iconColor: const Color(0xFFFF9800),
              title: l10n.profileVisits,
              subtitle: l10n.whenSomeoneViewsYourProfileVIP,
              value: settings.profileVisits && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('profileVisits', value);
              },
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.campaign_rounded,
              iconColor: const Color(0xFF9C27B0),
              title: l10n.marketing,
              subtitle: l10n.updatesAndPromotionalMessages,
              value: settings.marketing && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('marketing', value);
              },
              isLast: true,
            ),
          ]),

          const SizedBox(height: 24),

          // Quiet Hours
          _buildSectionTitle(
            context,
            l10n.quietHours,
            Icons.bedtime_rounded,
            const Color(0xFF673AB7),
          ),
          const SizedBox(height: 10),
          _buildSectionContainer(context, [
            _buildToggleTile(
              context: context,
              icon: Icons.do_not_disturb_on_rounded,
              iconColor: const Color(0xFF673AB7),
              title: l10n.quietHoursEnable,
              subtitle: l10n.quietHoursSubtitle,
              value: settings.quietHours.enabled,
              enabled: true,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .updateQuietHours(settings.quietHours.copyWith(enabled: v));
              },
              isFirst: true,
              isLast: !settings.quietHours.enabled,
            ),
            if (settings.quietHours.enabled) ...[
              _buildDivider(context),
              _buildTimeTile(
                context: context,
                icon: Icons.bedtime_off_rounded,
                iconColor: const Color(0xFF673AB7),
                title: l10n.quietHoursStart,
                time: settings.quietHours.start,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _parseHHmm(settings.quietHours.start),
                  );
                  if (t != null) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateQuietHours(
                          settings.quietHours.copyWith(start: _formatHHmm(t)),
                        );
                  }
                },
              ),
              _buildDivider(context),
              _buildTimeTile(
                context: context,
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFF9800),
                title: l10n.quietHoursEnd,
                time: settings.quietHours.end,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _parseHHmm(settings.quietHours.end),
                  );
                  if (t != null) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateQuietHours(
                          settings.quietHours.copyWith(end: _formatHHmm(t)),
                        );
                  }
                },
              ),
              _buildDivider(context),
              _buildToggleTile(
                context: context,
                icon: Icons.priority_high_rounded,
                iconColor: const Color(0xFFE53935),
                title: l10n.quietHoursAllowUrgent,
                subtitle: l10n.quietHoursAllowUrgentSubtitle,
                value: settings.quietHours.allowUrgent,
                enabled: true,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .updateQuietHours(
                        settings.quietHours.copyWith(allowUrgent: v),
                      );
                },
                isLast: true,
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // Notification Preferences
          _buildSectionTitle(
            context,
            l10n.notificationPreferences,
            Icons.tune_rounded,
            const Color(0xFFFF9800),
          ),
          const SizedBox(height: 10),
          _buildSectionContainer(context, [
            _buildToggleTile(
              context: context,
              icon: Icons.volume_up_rounded,
              iconColor: const Color(0xFFFF9800),
              title: l10n.sound,
              subtitle: l10n.playNotificationSounds,
              value: settings.sound && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('sound', value);
              },
              isFirst: true,
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.vibration_rounded,
              iconColor: const Color(0xFF7C4DFF),
              title: l10n.vibration,
              subtitle: l10n.vibrateOnNotifications,
              value: settings.vibration && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('vibration', value);
              },
            ),
            _buildDivider(context),
            _buildToggleTile(
              context: context,
              icon: Icons.preview_rounded,
              iconColor: const Color(0xFF2196F3),
              title: l10n.showPreview,
              subtitle: l10n.showMessagePreviewInNotifications,
              value: settings.showPreview && settings.enabled,
              enabled: settings.enabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('showPreview', value);
              },
              isLast: true,
            ),
          ]),

          // Muted Conversations
          if (settings.mutedConversations.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              context,
              l10n.mutedConversations,
              Icons.volume_off_rounded,
              const Color(0xFF607D8B),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${settings.mutedConversations.length}',
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionContainer(
              context,
              List.generate(settings.mutedConversations.length, (i) {
                final conversationId = settings.mutedConversations[i];
                return Column(
                  children: [
                    _buildMutedConversationTile(
                      context: context,
                      conversationId: conversationId,
                      onUnmute: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .unmuteConversation(conversationId);
                      },
                      isFirst: i == 0,
                      isLast: i == settings.mutedConversations.length - 1,
                      l10n: l10n,
                    ),
                    if (i < settings.mutedConversations.length - 1)
                      _buildDivider(context),
                  ],
                );
              }),
            ),
          ],

          const SizedBox(height: 24),

          // System Settings
          _buildSystemSettingsCard(context, l10n),
        ],
      ),
    );
  }

  // ========== STATUS CARD ==========
  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = settings.enabled;
    final color = enabled ? AppColors.primary : context.textMuted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.2 : 0.12),
            color.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.75)],
                    )
                  : null,
              color: enabled ? null : context.containerColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: enabled ? Colors.white : context.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'Notifications on' : 'Notifications off',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: enabled ? color : context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.turnAllNotificationsOnOrOff,
                  style: context.captionSmall.copyWith(
                    color: context.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: settings.enabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting('enabled', value);
            },
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: context.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  // ========== SECTION CONTAINER ==========
  Widget _buildSectionContainer(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.dividerColor.withValues(alpha: 0.4),
      ),
    );
  }

  // ========== TOGGLE TILE ==========
  Widget _buildToggleTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool>? onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 18 : 0),
      topRight: Radius.circular(isFirst ? 18 : 0),
      bottomLeft: Radius.circular(isLast ? 18 : 0),
      bottomRight: Radius.circular(isLast ? 18 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && onChanged != null ? () => onChanged(!value) : null,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Opacity(
                opacity: enabled ? 1.0 : 0.4,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? context.textPrimary
                            : context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.captionSmall.copyWith(
                        color: enabled
                            ? context.textMuted
                            : context.textMuted.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== TIME TILE ==========
  Widget _buildTimeTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 18 : 0),
      topRight: Radius.circular(isFirst ? 18 : 0),
      bottomLeft: Radius.circular(isLast ? 18 : 0),
      bottomRight: Radius.circular(isLast ? 18 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MUTED CONVERSATION TILE ==========
  Widget _buildMutedConversationTile({
    required BuildContext context,
    required String conversationId,
    required VoidCallback onUnmute,
    required bool isFirst,
    required bool isLast,
    required AppLocalizations l10n,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 18 : 0),
      topRight: Radius.circular(isFirst ? 18 : 0),
      bottomLeft: Radius.circular(isLast ? 18 : 0),
      bottomRight: Radius.circular(isLast ? 18 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF607D8B,
                  ).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volume_off_rounded,
                  color: Color(0xFF607D8B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${l10n.conversation} $conversationId',
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onUnmute,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.unmute,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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
      ),
    );
  }

  // ========== SYSTEM SETTINGS CARD ==========
  Widget _buildSystemSettingsCard(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          AppSettings.openAppSettings(type: AppSettingsType.notification);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF607D8B), const Color(0xFF455A64)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF607D8B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.systemNotificationSettings,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.manageNotificationsInSystemSettings,
                      style: context.captionSmall.copyWith(
                        color: context.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading settings...',
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String error,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingSettings,
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: context.bodySmall.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .fetchSettings();
                },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.retry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parse 'HH:mm' string into a TimeOfDay.
TimeOfDay _parseHHmm(String s) {
  final parts = s.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Format a TimeOfDay as zero-padded 'HH:mm'.
String _formatHHmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
