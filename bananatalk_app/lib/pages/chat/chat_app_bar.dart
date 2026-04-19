import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/providers/message_count_provider.dart';
import 'package:bananatalk_app/providers/chat_state_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/daily_call_limit_service.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:app_settings/app_settings.dart';
import 'user_avatar.dart';
import 'chat_options_menu.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;
  final String? profilePicture;
  final bool isTyping;
  final String? userId;
  final bool? isConnected;
  final ConnectionStatus? connectionStatus;
  final bool? isOnline;
  final String? lastSeen;
  final VoidCallback? onThemeChanged;
  final bool isVip;

  const ChatAppBar({
    super.key,
    required this.userName,
    this.profilePicture,
    required this.isTyping,
    this.userId,
    this.isConnected,
    this.connectionStatus,
    this.isOnline,
    this.lastSeen,
    this.onThemeChanged,
    this.isVip = false,
  });

  Widget _buildStatusWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Priority: typing > connection issues > online/offline status
    if (isTyping) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDots(),
          Spacing.hGapXS,
          Text(
            l10n.typing,
            style: context.captionSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Only show connection status if explicitly set AND not connected
    // This prevents "Connecting..." flash on every chat open
    if (connectionStatus != null &&
        connectionStatus != ConnectionStatus.connected) {
      return _buildConnectionStatus(context, connectionStatus!);
    }

    // Show online/offline status
    if (isOnline != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOnline! ? AppColors.online : AppColors.offline,
              shape: BoxShape.circle,
              boxShadow: isOnline!
                  ? [
                      BoxShadow(
                        color: AppColors.online.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          Spacing.hGapXS,
          Text(
            isOnline! ? l10n.online : _formatLastSeen(context),
            style: context.captionSmall.copyWith(
              color: isOnline! ? AppColors.online : context.textSecondary,
              fontWeight: isOnline! ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConnectionStatus(BuildContext context, ConnectionStatus status) {
    Color dotColor;
    String statusText;
    bool showPulse = false;

    switch (status) {
      case ConnectionStatus.connecting:
        dotColor = AppColors.warning;
        statusText = 'Connecting...';
        showPulse = true;
        break;
      case ConnectionStatus.reconnecting:
        dotColor = AppColors.warning;
        statusText = 'Reconnecting...';
        showPulse = true;
        break;
      case ConnectionStatus.disconnected:
        dotColor = AppColors.error;
        statusText = 'Offline';
        break;
      case ConnectionStatus.connected:
        dotColor = AppColors.online;
        statusText = 'Connected';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPulse)
          _PulsingDot(color: dotColor)
        else
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        Spacing.hGapXS,
        Text(
          statusText,
          style: context.captionSmall.copyWith(
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
  
  String _formatLastSeen(BuildContext context) {
    // If lastSeen is null or empty, user was recently online or we don't have data
    if (lastSeen == null || lastSeen!.isEmpty || lastSeen == 'null') {
      return 'Last seen recently';
    }

    try {
      final lastSeenDate = parseToKoreaTime(lastSeen!);
      final now = getKoreaNow();
      final difference = now.difference(lastSeenDate);

      // Handle future dates (clock sync issues) - treat as just now
      if (difference.isNegative) {
        return 'Active just now';
      }

      if (difference.inSeconds < 30) {
        return 'Active just now';
      } else if (difference.inMinutes < 1) {
        return 'Active just now';
      } else if (difference.inMinutes == 1) {
        return 'Active 1 min ago';
      } else if (difference.inMinutes < 60) {
        return 'Active ${difference.inMinutes} min ago';
      } else if (difference.inHours == 1) {
        return 'Active 1 hour ago';
      } else if (difference.inHours < 24) {
        return 'Active ${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Active yesterday';
      } else if (difference.inDays < 7) {
        return 'Active ${difference.inDays}d ago';
      } else {
        // Show actual date for 7+ days ago
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months[lastSeenDate.month - 1];
        return 'Last seen $month ${lastSeenDate.day}';
      }
    } catch (e) {
      return 'Last seen recently';
    }
  }

  Future<void> _navigateToProfile(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userIdNotAvailable),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final communityService = ref.read(communityServiceProvider);
      final community = await communityService.getSingleCommunity(id: userId!);

      if (community == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.userNotFound)),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SingleCommunity(community: community),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.4, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeIn,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if calling is enabled (requires 3+ messages) — reactive, updates when messages load
    final canCall = userId != null
        ? ref.watch(canCallProvider(userId!))
        : false;

    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: InkWell(
        onTap: () => _navigateToProfile(context, ref),
        borderRadius: AppRadius.borderMD,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // User avatar hidden - only show name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: context.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVip) ...[
                          Spacing.hGapSM,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AppRadius.borderSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 10,
                                  color: AppColors.white,
                                ),
                                Spacing.hGapXXS,
                                Text(
                                  'VIP',
                                  style: context.captionSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Spacing.hGapXXS,
                    _buildStatusWidget(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Video call button
        _CallButton(
          icon: Icons.videocam_rounded,
          isEnabled: canCall,
          onPressed: canCall && userId != null
              ? () => _initiateCall(context, ref, CallType.video)
              : () => _showCallDisabledTooltip(context),
        ),
        // Audio call button
        _CallButton(
          icon: Icons.call_rounded,
          isEnabled: canCall,
          onPressed: canCall && userId != null
              ? () => _initiateCall(context, ref, CallType.audio)
              : () => _showCallDisabledTooltip(context),
        ),
        ChatOptionsMenu(
          userName: userName,
          userId: userId,
          onThemeChanged: onThemeChanged,
        ),
      ],
    );
  }

  void _showCallDisabledTooltip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.exchange3MessagesBeforeCall),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _initiateCall(
    BuildContext context,
    WidgetRef ref,
    CallType callType,
  ) async {
    if (userId == null) return;

    // Check VIP status for call limits
    final authState = ref.read(authServiceProvider);
    final currentUserId = authState.userId;
    final isCurrentUserVip = ref.read(isVipProvider(currentUserId));

    if (!isCurrentUserVip) {
      // Check daily call limit
      final canMakeCall = await DailyCallLimitService.canCall();
      if (!canMakeCall) {
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => VipUpgradeSheet(
              featureName: 'Unlimited Calls',
              description:
                  'Free users can make up to ${DailyCallLimitService.maxDailyCalls} calls per day. '
                  'Upgrade to VIP for unlimited calls!',
            ),
          );
        }
        return;
      }
    }

    try {
      final callNotifier = ref.read(callProvider.notifier);

      // Set VIP status so CallManager knows about duration limit
      callNotifier.setVipCall(isCurrentUserVip);

      // Setup error callback to handle permission errors
      callNotifier.setCallErrorCallback((error) {
        if (context.mounted) {
          _handleCallError(context, error);
        }
      });

      await callNotifier.initiateCall(
        userId!,
        userName,
        profilePicture,
        callType,
      );

      // Record this call for daily limit tracking (non-VIP)
      if (!isCurrentUserVip) {
        final currentCall = callNotifier.currentCall;
        if (currentCall != null && currentCall.callId.isNotEmpty) {
          await DailyCallLimitService.recordCall(currentCall.callId);
        }
      }

      // Navigate to active call screen via overlay navigator
      if (context.mounted) {
        final currentCall = callNotifier.currentCall;
        if (currentCall != null) {
          callOverlayNavigatorKey.currentState?.push(
            AppPageRoute(
              builder: (_) => ActiveCallScreen(call: currentCall),
              fullscreenDialog: true,
            ),
          );
        }
      }
    } catch (e) {
      // Error is already handled via the callback, no need to handle again
    }
  }
  
  void _handleCallError(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      // Show dialog with option to open settings
      final message = error.substring('PERMANENTLY_DENIED:'.length);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.permissionsRequired),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppSettings.openAppSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    } else if (error.startsWith('DENIED:')) {
      // Show snackbar for temporary denial
      final message = error.substring('DENIED:'.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Animated call button with hover effect
class _CallButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _CallButton({
    required this.icon,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.borderMD,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMD,
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isEnabled
                  ? AppColors.primary
                  : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated typing dots indicator with visibility-aware animation
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pause animation when not visible (TickerMode disabled)
    if (!TickerMode.of(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.15;
              final progress = (_controller.value - delay).clamp(0.0, 1.0);
              final bounce = (progress < 0.5)
                  ? Curves.easeOut.transform(progress * 2)
                  : Curves.easeIn.transform(2 - progress * 2);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Transform.translate(
                  offset: Offset(0, -3 * bounce),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.6 + 0.4 * bounce),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Pulsing dot for connection status
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.of(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
