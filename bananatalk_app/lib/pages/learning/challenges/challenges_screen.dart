import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/learning_providers.dart';
import 'package:bananatalk_app/models/learning/challenge_model.dart';
import 'package:bananatalk_app/widgets/learning/challenge_card.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Challenges screen with daily and weekly challenges
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        title: Text(
          'Challenges',
          style: context.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Special'),
          ],
        ),
      ),
      body: challengesAsync.when(
        data: (challenges) {
          final daily =
              challenges.where((c) => c.type.toLowerCase() == 'daily').toList();
          final weekly =
              challenges.where((c) => c.type.toLowerCase() == 'weekly').toList();
          final special =
              challenges.where((c) => c.type.toLowerCase() == 'special').toList();

          return Column(
            children: [
              // Stats header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: _buildStatsRow(challenges),
              ),
              // Challenge lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChallengeList(
                      daily,
                      'Daily',
                      'Complete challenges daily to earn XP and rewards!',
                      const Color(0xFF2196F3),
                    ),
                    _buildChallengeList(
                      weekly,
                      'Weekly',
                      'Weekly challenges refresh every Monday',
                      const Color(0xFF9C27B0),
                    ),
                    _buildChallengeList(
                      special,
                      'Special',
                      'Limited-time challenges with bonus rewards!',
                      const Color(0xFFFF9800),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.textMuted),
              Spacing.gapLG,
              Text('Failed to load challenges',
                  style: context.bodyMedium.copyWith(color: context.textSecondary)),
              Spacing.gapLG,
              ElevatedButton(
                onPressed: () => ref.invalidate(challengesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<Challenge> challenges) {
    final completed = challenges.where((c) => c.isCompleted).length;
    final totalXP = challenges
        .where((c) => c.isCompleted)
        .fold<int>(0, (sum, c) => sum + c.xpReward);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Completed',
          '$completed/${challenges.length}',
          const Color(0xFF00BFA5),
          Icons.check_circle_rounded,
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[200],
        ),
        _buildStatItem(
          'XP Earned',
          '+$totalXP',
          const Color(0xFFFF9800),
          Icons.star_rounded,
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[200],
        ),
        _buildStatItem(
          'Progress',
          challenges.isNotEmpty
              ? '${(completed / challenges.length * 100).round()}%'
              : '0%',
          const Color(0xFF9C27B0),
          Icons.trending_up_rounded,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeList(
    List challenges,
    String type,
    String description,
    Color color,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type Challenges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Separate completed and active challenges
    final active = challenges.where((c) => !c.isCompleted).toList();
    final completed = challenges.where((c) => c.isCompleted).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(challengesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Active challenges
          if (active.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Active (${active.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...active.map((challenge) => ChallengeCard(
                  challenge: challenge,
                  onTap: () => _showChallengeDetail(challenge),
                )),
          ],
          // Completed challenges
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed (${completed.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...completed.map((challenge) => ChallengeCard(
                  challenge: challenge,
                  onTap: () => _showChallengeDetail(challenge),
                )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showChallengeDetail(dynamic challenge) {
    final progress = challenge.progressPercentage;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getTypeColor(challenge.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(challenge.category),
                    color: _getTypeColor(challenge.type),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            challenge.typeLabel,
                            _getTypeColor(challenge.type),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            challenge.difficultyLabel,
                            _getDifficultyColor(challenge.difficulty),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              challenge.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${challenge.currentProgress}/${challenge.requirement.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: challenge.isCompleted
                        ? const Color(0xFF00BFA5)
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  challenge.isCompleted
                      ? const Color(0xFF00BFA5)
                      : _getTypeColor(challenge.type),
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
            // Rewards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF00BFA5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${challenge.xpReward} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00BFA5),
                              ),
                            ),
                            Text(
                              'XP Reward',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (challenge.bonusReward != null) ...[
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getBonusIcon(challenge.bonusReward!.type),
                              color: const Color(0xFF9C27B0),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.bonusReward!.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9C27B0),
                                  ),
                                ),
                                Text(
                                  'Bonus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Time remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: challenge.timeRemaining.inHours < 6
                      ? Colors.orange
                      : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  'Expires in ${challenge.timeRemainingFormatted}',
                  style: TextStyle(
                    fontSize: 13,
                    color: challenge.timeRemaining.inHours < 6
                        ? Colors.orange
                        : Colors.grey[600],
                    fontWeight: challenge.timeRemaining.inHours < 6
                        ? FontWeight.w600
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return const Color(0xFF2196F3);
      case 'weekly':
        return const Color(0xFF9C27B0);
      case 'special':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'hard':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'messaging':
        return Icons.chat_rounded;
      case 'vocabulary':
        return Icons.text_fields_rounded;
      case 'lessons':
        return Icons.school_rounded;
      case 'corrections':
        return Icons.spellcheck_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  IconData _getBonusIcon(String type) {
    switch (type.toLowerCase()) {
      case 'streak_freeze':
        return Icons.ac_unit_rounded;
      case 'xp_boost':
        return Icons.bolt_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }
}
