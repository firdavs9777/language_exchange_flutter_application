// EXAMPLE: How to integrate VIP and visitor features into your chat
// This is a reference implementation - adapt to your existing code structure

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/providers/provider_models/users_model.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/visitor_usage_indicator.dart';
import 'package:bananatalk_app/widgets/visitor_limit_dialog.dart';
import 'package:bananatalk_app/services/vip_service.dart';

// EXAMPLE 1: Chat Input with Visitor Limit Check
class ChatInputWithFeatureGate extends ConsumerStatefulWidget {
  final String chatId;
  final String userId;

  const ChatInputWithFeatureGate({
    Key? key,
    required this.chatId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ChatInputWithFeatureGate> createState() =>
      _ChatInputWithFeatureGateState();
}

class _ChatInputWithFeatureGateState
    extends ConsumerState<ChatInputWithFeatureGate> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage(User currentUser) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // FEATURE GATE CHECK: Can user send message?
    if (!FeatureGate.canSendMessage(currentUser)) {
      // Show limit reached dialog
      await VisitorLimitDialog.show(
        context: context,
        userId: widget.userId,
        limitType: 'message',
        limitations: currentUser.visitorLimitations!,
      );
      return;
    }

    // Continue with sending message
    // ... your existing message sending logic
    _messageController.clear();

    // After successful send, refresh visitor limits if visitor
    if (currentUser.isVisitor) {
      await _refreshVisitorLimits();
    }
  }

  Future<void> _refreshVisitorLimits() async {
    final result = await VipService.getVisitorLimits(userId: widget.userId);
    if (result['success']) {
      // Update your user state with new limits
      // ref.read(userProvider.notifier).updateVisitorLimits(
      //   result['visitorLimitations'],
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from your provider
    // final currentUser = ref.watch(userProvider);

    // Example User for demonstration
    final currentUser = User(
      name: 'Test User',
      password: '',
      email: 'test@example.com',
      bio: '',
      image: '',
      birth_day: '1',
      birth_month: '1',
      gender: 'male',
      birth_year: '1990',
      native_language: 'English',
      language_to_learn: 'Spanish',
      userMode: UserMode.visitor,
      visitorLimitations: VisitorLimitations(
        dailyMessageLimit: 5,
        messagesSentToday: 3,
        dailyProfileViewLimit: 10,
        profileViewsToday: 5,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: currentUser.isVisitor
                    ? 'Message (${currentUser.visitorLimitations?.remainingMessages ?? 0} left)'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(currentUser),
          ),
        ],
      ),
    );
  }
}

// EXAMPLE 2: Profile View with Feature Gate
class ProfileViewWithFeatureGate extends ConsumerWidget {
  final String profileId;
  final String currentUserId;

  const ProfileViewWithFeatureGate({
    Key? key,
    required this.profileId,
    required this.currentUserId,
  }) : super(key: key);

  Future<void> _viewProfile(BuildContext context, User currentUser) async {
    // FEATURE GATE CHECK: Can user view profile?
    if (!FeatureGate.canViewProfile(currentUser)) {
      await VisitorLimitDialog.show(
        context: context,
        userId: currentUserId,
        limitType: 'profile',
        limitations: currentUser.visitorLimitations!,
      );
      return;
    }

    // Continue with viewing profile
    // ... your existing profile view logic

    // After successful view, refresh visitor limits if visitor
    if (currentUser.isVisitor) {
      final result = await VipService.getVisitorLimits(userId: currentUserId);
      // Update state...
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user from your provider
    // final currentUser = ref.watch(userProvider);

    final currentUser = User(
      name: 'Test User',
      password: '',
      email: 'test@example.com',
      bio: '',
      image: '',
      birth_day: '1',
      birth_month: '1',
      gender: 'male',
      birth_year: '1990',
      native_language: 'English',
      language_to_learn: 'Spanish',
      userMode: UserMode.visitor,
      visitorLimitations: VisitorLimitations(
        dailyProfileViewLimit: 10,
        profileViewsToday: 8,
      ),
    );

    return Card(
      child: InkWell(
        onTap: () => _viewProfile(context, currentUser),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person),
              ),
              const SizedBox(height: 8),
              const Text('Profile Name'),
              if (currentUser.isVisitor &&
                  currentUser.visitorLimitations != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${currentUser.visitorLimitations!.remainingProfileViews} views left',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// EXAMPLE 3: Chat App Bar with Usage Indicator
class ChatAppBarWithUsageIndicator extends ConsumerWidget
    implements PreferredSizeWidget {
  final String chatTitle;

  const ChatAppBarWithUsageIndicator({
    Key? key,
    required this.chatTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user from your provider
    // final currentUser = ref.watch(userProvider);

    final currentUser = User(
      name: 'Test User',
      password: '',
      email: 'test@example.com',
      bio: '',
      image: '',
      birth_day: '1',
      birth_month: '1',
      gender: 'male',
      birth_year: '1990',
      native_language: 'English',
      language_to_learn: 'Spanish',
      userMode: UserMode.visitor,
      visitorLimitations: VisitorLimitations(
        dailyMessageLimit: 5,
        messagesSentToday: 2,
        dailyProfileViewLimit: 10,
        profileViewsToday: 5,
      ),
    );

    return AppBar(
      title: Text(chatTitle),
      actions: [
        // Show compact usage indicator for visitors
        if (currentUser.isVisitor && currentUser.visitorLimitations != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: VisitorUsageIndicator(
                limitations: currentUser.visitorLimitations!,
                compact: true,
              ),
            ),
          ),

        // Show VIP badge for VIP users
        if (currentUser.isVip)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: VipBadge()),
          ),

        // Menu button
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// EXAMPLE 4: Feature-Gated Advanced Search
class AdvancedSearchExample extends ConsumerWidget {
  const AdvancedSearchExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user from your provider
    // final currentUser = ref.watch(userProvider);

    final currentUser = User(
      name: 'Test User',
      password: '',
      email: 'test@example.com',
      bio: '',
      image: '',
      birth_day: '1',
      birth_month: '1',
      gender: 'male',
      birth_year: '1990',
      native_language: 'English',
      language_to_learn: 'Spanish',
      userMode: UserMode.regular, // Not VIP
    );

    // Use feature gate to show/hide advanced search
    if (!currentUser.isVip ||
        !FeatureGate.hasVipFeature(currentUser, 'advancedSearch')) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Advanced Search',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock advanced search filters with VIP',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to VIP plans
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => VipPlansScreen(userId: currentUser.id),
                //   ),
                // );
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to VIP'),
            ),
          ],
        ),
      );
    }

    // Show advanced search for VIP users
    return Column(
      children: [
        // Advanced search filters
        TextField(
          decoration: const InputDecoration(
            labelText: 'Filter by location',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Filter by age range',
            prefixIcon: Icon(Icons.calendar_today),
          ),
        ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Filter by interests',
            prefixIcon: Icon(Icons.interests),
          ),
        ),
      ],
    );
  }
}

// EXAMPLE 5: Main Screen with Visitor Usage Card
class MainScreenWithUsageCard extends ConsumerWidget {
  const MainScreenWithUsageCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user from your provider
    // final currentUser = ref.watch(userProvider);

    final currentUser = User(
      name: 'Test User',
      password: '',
      email: 'test@example.com',
      bio: '',
      image: '',
      birth_day: '1',
      birth_month: '1',
      gender: 'male',
      birth_year: '1990',
      native_language: 'English',
      language_to_learn: 'Spanish',
      userMode: UserMode.visitor,
      visitorLimitations: VisitorLimitations(
        dailyMessageLimit: 5,
        messagesSentToday: 4,
        dailyProfileViewLimit: 10,
        profileViewsToday: 8,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('BananaTalk'),
        actions: [
          // User mode badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: currentUser.modeBadge),
          ),
        ],
      ),
      body: Column(
        children: [
          // Show usage card for visitors
          if (currentUser.isVisitor && currentUser.visitorLimitations != null)
            VisitorUsageIndicator(
              limitations: currentUser.visitorLimitations!,
              compact: false,
            ),

          // Rest of your content
          Expanded(
            child: Center(
              child: Text('Your main content here'),
            ),
          ),
        ],
      ),
    );
  }
}
