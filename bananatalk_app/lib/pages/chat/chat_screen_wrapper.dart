import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/call/call_launcher.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';

class ChatScreenWrapper extends ConsumerStatefulWidget {
  final String userId;
  final String? prefillMessage;

  /// 'audio' | 'video': start that call once the user is loaded (missed-call
  /// "Call back", `/chat/:userId?call=`). Busy, unavailable and permission
  /// outcomes are shown by [CallLauncher].
  final String? autoCall;

  const ChatScreenWrapper({
    super.key,
    required this.userId,
    this.prefillMessage,
    this.autoCall,
  });

  @override
  ConsumerState<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends ConsumerState<ChatScreenWrapper> {
  Community? _userData;
  bool _isLoading = true;
  String? _error;
  bool _autoCallDone = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final communityService = CommunityService();
      final userData = await communityService.getSingleCommunity(
        id: widget.userId,
      );

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
        if (userData != null) _startAutoCall(userData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.chatFailedToLoadUser;
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoCall(Community user) {
    final type = widget.autoCall;
    if (type == null || _autoCallDone) return;
    _autoCallDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CallLauncher.start(
        context,
        ref,
        userId: widget.userId,
        userName: user.name,
        avatar: user.profileImageUrl,
        type: type == 'video' ? CallType.video : CallType.audio,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const AppBackButton(),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
      );
    }

    if (_error != null || _userData == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(AppLocalizations.of(context)!.error),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? AppLocalizations.of(context)!.userNotFound,
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
      isVip: PrivacyUtils.showsVipBadge(_userData!),
      prefillMessage: widget.prefillMessage,
    );
  }
}
