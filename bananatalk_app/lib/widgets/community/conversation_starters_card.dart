import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart' as chat;

enum StarterType { sharedTopic, recentMoment, language, location, mbti, generic }

class StarterSuggestion {
  final String icon;
  final String text;
  final String? actionText;
  final StarterType type;

  const StarterSuggestion({
    required this.icon,
    required this.text,
    this.actionText,
    required this.type,
  });
}

class ConversationStartersCard extends ConsumerWidget {
  final Community profile;

  const ConversationStartersCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(userProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        final starters = _generateStarters(currentUser, profile);

        if (starters.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Conversation Starters',
                    style: context.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Starters list (max 3)
              ...starters.take(3).map(
                (starter) => _buildStarterCard(context, starter),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<StarterSuggestion> _generateStarters(
    Community currentUser,
    Community profile,
  ) {
    final starters = <StarterSuggestion>[];

    // 1. Shared topics
    final myTopics = currentUser.topics.toSet();
    final theirTopics = profile.topics.toSet();
    final sharedTopics = myTopics.intersection(theirTopics);

    for (final topicId in sharedTopics.take(1)) {
      final topic = Topic.defaultTopics.firstWhere(
        (t) => t.id == topicId,
        orElse: () => Topic(
          id: topicId,
          name: topicId,
          icon: '🏷️',
          category: 'other',
        ),
      );
      starters.add(StarterSuggestion(
        icon: topic.icon,
        text: 'You both love ${topic.name} - ask about their favorite!',
        actionText:
            "Hey! I saw you're into ${topic.name} too. What's your favorite?",
        type: StarterType.sharedTopic,
      ));
    }

    // 2. Language match
    if (currentUser.language_to_learn.toLowerCase() ==
        profile.native_language.toLowerCase()) {
      starters.add(StarterSuggestion(
        icon: '🗣️',
        text:
            "You're learning ${profile.native_language} - ask for tips!",
        actionText:
            "Hi! I'm learning ${profile.native_language}. Any tips for a beginner?",
        type: StarterType.language,
      ));
    }

    // 3. Location-based (only if privacy allows)
    final locationText = PrivacyUtils.getLocationText(profile);
    if (locationText.isNotEmpty) {
      starters.add(StarterSuggestion(
        icon: '📍',
        text:
            "They're from $locationText - ask about local culture!",
        actionText:
            "Hey! What's $locationText like? I'd love to hear about it!",
        type: StarterType.location,
      ));
    }

    // 4. MBTI match
    if (currentUser.mbti.isNotEmpty &&
        profile.mbti.isNotEmpty &&
        currentUser.mbti.toUpperCase() == profile.mbti.toUpperCase()) {
      starters.add(StarterSuggestion(
        icon: '🧠',
        text: "You're both ${profile.mbti.toUpperCase()} - compare insights!",
        actionText:
            "Hey fellow ${profile.mbti.toUpperCase()}! How do you think our personality affects language learning?",
        type: StarterType.mbti,
      ));
    }

    // 5. Fallback
    if (starters.isEmpty) {
      starters.add(const StarterSuggestion(
        icon: '👋',
        text: 'Say hi and introduce yourself!',
        actionText:
            "Hi! I'd love to practice languages together. How are you?",
        type: StarterType.generic,
      ));
    }

    return starters;
  }

  Widget _buildStarterCard(BuildContext context, StarterSuggestion starter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(starter.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  starter.text,
                  style: context.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () => _copyToClipboard(context, starter.actionText),
                isPrimary: false,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.send_rounded,
                label: 'Chat',
                onTap: () => _navigateToChat(context, starter.actionText),
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String? text) {
    if (text == null) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String? prefilledMessage) {
    // Copy message to clipboard first so user can paste it
    if (prefilledMessage != null) {
      Clipboard.setData(ClipboardData(text: prefilledMessage));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => chat.ChatScreen(
          userId: profile.id,
          userName: profile.name,
          profilePicture: profile.profileImageUrl,
          isVip: profile.isVip,
        ),
      ),
    );

    // Show snackbar after navigation
    if (prefilledMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.content_paste, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Message copied! Paste to send.')),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? AppColors.primary : context.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? AppColors.primary : context.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppColors.primary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
