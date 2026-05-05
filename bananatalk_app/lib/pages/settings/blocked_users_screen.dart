import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/models/blocked_user.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');

      if (_currentUserId == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _error = l10n.userIdNotFound;
            _isLoading = false;
          });
        }
        return;
      }

      final blockedUsers = await BlockService.getBlockedUsers(
        userId: _currentUserId!,
      );

      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _error = l10n.errorLoadingBlockedUsers(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(BlockedUser blockedUser) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unblockUser),
        content: Text(l10n.unblockConfirm(blockedUser.blockedUserName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: Text(l10n.unblock),
          ),
        ],
      ),
    );

    if (result == true && _currentUserId != null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final unblockResult = await BlockService.unblockUser(
        currentUserId: _currentUserId!,
        blockedUserId: blockedUser.userId,
      );

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(unblockResult['message'] ?? l10n.operationCompleted),
            backgroundColor:
                unblockResult['success'] ? AppColors.success : AppColors.error,
          ),
        );

        if (unblockResult['success']) {
          await _loadBlockedUsers();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.blockedUsers, style: context.titleLarge),
        backgroundColor: context.surfaceColor,
        elevation: 0,
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const UserListSkeleton(count: 6);
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadBlockedUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        _error!,
                        style: context.bodyMedium
                            .copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: _loadBlockedUsers,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_blockedUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBlockedUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block,
                        size: 64, color: context.textSecondary),
                    SizedBox(height: AppSpacing.lg),
                    Text(l10n.noBlockedUsers, style: context.titleLarge),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.usersYouBlockWillAppearHere,
                      style: context.bodyMedium
                          .copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final blockedUser = _blockedUsers[index];

          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.borderMD,
              boxShadow:
                  context.isDarkMode ? AppShadows.none : AppShadows.sm,
            ),
            child: ListTile(
              contentPadding: AppSpacing.paddingMD,
              leading: CachedCircleAvatar(
                imageUrl: blockedUser.blockedUserAvatar,
                radius: 28,
                backgroundColor: context.containerColor,
                errorWidget: Text(
                  blockedUser.blockedUserName.isNotEmpty
                      ? blockedUser.blockedUserName[0].toUpperCase()
                      : '?',
                  style: context.titleMedium.copyWith(
                    color: context.primaryColor,
                  ),
                ),
              ),
              title: Text(
                blockedUser.blockedUserName,
                style: context.titleSmall,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (blockedUser.reason != null)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.reasonLabel(blockedUser.reason!),
                        style: context.caption,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l10n.blockedAgo(_formatRelative(blockedUser.blockedAt, l10n)),
                      style: context.caption,
                    ),
                  ),
                ],
              ),
              trailing: TextButton(
                onPressed: () => _unblockUser(blockedUser),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                ),
                child: Text(l10n.unblock),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatRelative(DateTime dateTime, AppLocalizations l10n) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;

      if (difference <= 0) return l10n.today;
      if (difference == 1) return l10n.yesterday;
      if (difference < 7) return l10n.daysAgo(difference);

      final locale = Localizations.localeOf(context).toString();
      return DateFormat.yMd(locale).format(dateTime);
    } catch (_) {
      return DateFormat.yMd().format(dateTime);
    }
  }
}
