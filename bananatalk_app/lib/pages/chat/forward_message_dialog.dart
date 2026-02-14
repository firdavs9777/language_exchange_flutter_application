import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Export the dialog widget
class ForwardMessageDialog extends ConsumerStatefulWidget {
  final List<String> userIds;
  final MessageService messageService;

  const ForwardMessageDialog({
    super.key,
    required this.userIds,
    required this.messageService,
  });

  @override
  ConsumerState<ForwardMessageDialog> createState() => _ForwardMessageDialogState();
}

class _ForwardMessageDialogState extends ConsumerState<ForwardMessageDialog> {
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  List<Community> _users = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final List<Community> users = [];
      for (final userId in widget.userIds) {
        try {
          final user = await ref.read(communityServiceProvider).getSingleCommunity(id: userId);
          if (user != null) {
            users.add(user);
          }
        } catch (e) {
          debugPrint('Error loading user $userId: $e');
        }
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderXL,
      ),
      backgroundColor: context.surfaceColor,
      title: Text(
        'Forward Message',
        style: context.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error.isNotEmpty
                ? Text(_error, style: context.bodyMedium.copyWith(color: AppColors.error))
                : _users.isEmpty
                    ? Text(
                        AppLocalizations.of(context)!.noUsersAvailableToForwardTo,
                        style: context.bodyMedium,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Select users to forward to:',
                            style: context.bodySmall,
                          ),
                          Spacing.gapLG,
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final isSelected = _selectedUserIds.contains(user.id);

                                return CheckboxListTile(
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedUserIds.add(user.id);
                                      } else {
                                        _selectedUserIds.remove(user.id);
                                      }
                                    });
                                  },
                                  title: Text(user.name, style: context.titleSmall),
                                  subtitle: user.email.isNotEmpty
                                      ? Text(user.email, style: context.caption)
                                      : null,
                                  secondary: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: context.containerColor,
                                    backgroundImage: (user.images.isNotEmpty
                                            ? NetworkImage(user.images.first)
                                            : user.imageUrls.isNotEmpty
                                                ? NetworkImage(user.imageUrls.first)
                                                : null) as ImageProvider?,
                                    child: (user.images.isEmpty && user.imageUrls.isEmpty)
                                        ? Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?',
                                            style: context.titleMedium,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Cancel',
            style: context.labelLarge.copyWith(
              color: context.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedUserIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedUserIds.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderMD,
            ),
          ),
          child: Text(
            'Forward (${_selectedUserIds.length})',
            style: context.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

