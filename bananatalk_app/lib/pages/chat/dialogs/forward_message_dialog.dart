import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_dialog_scaffold.dart';
import 'package:bananatalk_app/utils/image_utils.dart';

/// Lists shorter than this skip the search field.
const int _forwardSearchThreshold = 8;

/// Who a message can be forwarded to: every conversation partner except the
/// one this chat is with, the viewer, and anyone the viewer blocked.
List<ChatPartnerData> forwardCandidates(
  List<ChatPartnerData> partners, {
  required String currentPartnerId,
  String? currentUserId,
  required Set<String> blockedIds,
}) {
  final seen = <String>{};
  return [
    for (final p in partners)
      if (p.id.isNotEmpty &&
          p.id != currentPartnerId &&
          p.id != currentUserId &&
          !blockedIds.contains(p.id) &&
          seen.add(p.id))
        p,
  ];
}

/// Name/username search over [forwardCandidates]; a blank query keeps all.
List<ChatPartnerData> filterForwardCandidates(
  List<ChatPartnerData> candidates,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return candidates;
  return candidates
      .where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            (p.username?.toLowerCase().contains(q) ?? false),
      )
      .toList();
}

// Export the dialog widget
class ForwardMessageDialog extends ConsumerStatefulWidget {
  final String currentUserId;
  final String currentPartnerId;
  final MessageService messageService;

  const ForwardMessageDialog({
    super.key,
    required this.currentUserId,
    required this.currentPartnerId,
    required this.messageService,
  });

  @override
  ConsumerState<ForwardMessageDialog> createState() =>
      _ForwardMessageDialogState();
}

class _ForwardMessageDialogState extends ConsumerState<ForwardMessageDialog> {
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  List<ChatPartnerData> _users = [];
  String _query = '';
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
      final partners = await widget.messageService.getChatPartners(
        id: widget.currentUserId,
        limit: 100,
      );
      Set<String> blockedIds = const {};
      try {
        blockedIds = await ref.read(blockedUserIdsProvider.future);
      } catch (_) {
        // The server already hides blocked chats; this is belt and braces.
      }

      if (!mounted) return;
      setState(() {
        _users = forwardCandidates(
          partners,
          currentPartnerId: widget.currentPartnerId,
          currentUserId: widget.currentUserId,
          blockedIds: blockedIds,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChatDialogScaffold(
      heroIcon: Icons.send_rounded,
      heroColor: AppColors.primary,
      title: l10n.forwardMessage,
      titleAlignment: CrossAxisAlignment.start,
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error.isNotEmpty
            ? Text(
                l10n.failedToLoadUsers,
                style: context.bodyMedium.copyWith(color: AppColors.error),
              )
            : _users.isEmpty
            ? Text(l10n.noUsersAvailableToForwardTo, style: context.bodyMedium)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.selectUsersToForward, style: context.bodySmall),
                  Spacing.gapLG,
                  if (_users.length > _forwardSearchThreshold) ...[
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: l10n.searchUsers,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                        ),
                      ),
                    ),
                    Spacing.gapMD,
                  ],
                  Flexible(
                    child: Builder(
                      builder: (context) {
                        final visible = filterForwardCandidates(_users, _query);
                        if (visible.isEmpty) {
                          return Text(
                            l10n.noResultsFound,
                            style: context.bodyMedium,
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final user = visible[index];
                            final isSelected = _selectedUserIds.contains(
                              user.id,
                            );

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
                              subtitle: (user.username?.isNotEmpty ?? false)
                                  ? Text(
                                      '@${user.username}',
                                      style: context.caption,
                                    )
                                  : null,
                              secondary: CircleAvatar(
                                radius: 20,
                                backgroundColor: context.containerColor,
                                backgroundImage: user.profileImageUrl != null
                                    ? ImageUtils.avatarProvider(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null
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
            l10n.cancel,
            style: context.labelLarge.copyWith(color: context.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedUserIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedUserIds.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
          ),
          child: Text(
            l10n.forwardCount(_selectedUserIds.length),
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
