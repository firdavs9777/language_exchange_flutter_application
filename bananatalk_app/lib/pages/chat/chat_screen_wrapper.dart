import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final communityService = CommunityService();
      final userData = await communityService.getSingleCommunity(id: widget.userId);

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
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
      profilePicture: _userData!.images.isNotEmpty
          ? _userData!.images.first
          : null,
    );
  }
}

