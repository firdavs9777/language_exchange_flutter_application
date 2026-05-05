import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/services/daily_chat_limit_service.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreenWrapper extends ConsumerStatefulWidget {
  final String userId;

  const ChatScreenWrapper({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends ConsumerState<ChatScreenWrapper> {
  Community? _userData;
  bool _isLoading = true;
  String? _error;
  bool _chatLimitReached = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final communityService = CommunityService();
      final userData = await communityService.getSingleCommunity(id: widget.userId);

      // Check daily chat limit for non-VIP users
      final authState = ref.read(authServiceProvider);
      final currentUserId = authState.userId;
      final isVip = ref.read(isVipProvider(currentUserId));
      if (!isVip) {
        final canChat = await DailyChatLimitService.canChat(widget.userId);
        if (!canChat) {
          if (mounted) {
            setState(() {
              _chatLimitReached = true;
              _userData = userData;
              _isLoading = false;
            });
          }
          return;
        }
        // Record this chat partner
        await DailyChatLimitService.recordChat(widget.userId);
      }

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load user data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
      );
    }

    if (_chatLimitReached) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 40,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daily Chat Limit Reached',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Free users can chat with up to ${DailyChatLimitService.maxDailyChats} people per day.\nUpgrade to VIP for unlimited conversations!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const VipUpgradeSheet(
                          featureName: 'Unlimited Chats',
                          description:
                              'Chat with as many people as you want! VIP members enjoy unlimited daily conversations.',
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Upgrade to VIP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null || _userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.error),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'User not found',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.goBack),
              ),
            ],
          ),
        ),
      );
    }

    return ChatScreen(
      userId: widget.userId,
      userName: _userData!.name,
      profilePicture: _userData!.profileImageUrl,
      isVip: _userData!.isVip,
    );
  }
}

