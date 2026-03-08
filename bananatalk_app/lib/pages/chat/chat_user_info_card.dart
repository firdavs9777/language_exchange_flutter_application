// lib/pages/chat/chat_user_info_card.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Card showing user info at the start of a new chat
class ChatUserInfoCard extends StatelessWidget {
  final String userName;
  final String? userPicture;
  final String? bio;
  final int? age;
  final String? gender;
  final String? location;
  final String? nativeLanguage;
  final String? learningLanguage;
  final List<String>? interests;
  final VoidCallback? onViewProfile;

  const ChatUserInfoCard({
    super.key,
    required this.userName,
    this.userPicture,
    this.bio,
    this.age,
    this.gender,
    this.location,
    this.nativeLanguage,
    this.learningLanguage,
    this.interests,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.secondary.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile picture - larger size
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: userPicture != null && userPicture!.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: userPicture!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Name and age
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userName,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              if (age != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$age',
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Location
          if (location != null && location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: context.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  location!,
                  style: context.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Languages
          if (nativeLanguage != null || learningLanguage != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (nativeLanguage != null) ...[
                  _buildLanguageChip(
                    context,
                    label: nativeLanguage!,
                    icon: Icons.chat_bubble_outline,
                    isNative: true,
                  ),
                ],
                if (nativeLanguage != null && learningLanguage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: context.textSecondary,
                    ),
                  ),
                ],
                if (learningLanguage != null) ...[
                  _buildLanguageChip(
                    context,
                    label: learningLanguage!,
                    icon: Icons.school_outlined,
                    isNative: false,
                  ),
                ],
              ],
            ),
          ],

          // Bio
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bio!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Interests / Topics
          if (interests != null && interests!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: interests!.take(5).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: context.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // View profile button
          if (onViewProfile != null)
            TextButton.icon(
              onPressed: onViewProfile,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('View Full Profile'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),

          // Conversation starter hint
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: context.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Say hi and start a conversation!',
                style: context.bodySmall.copyWith(
                  color: context.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isNative,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isNative
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNative
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isNative ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: isNative ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
