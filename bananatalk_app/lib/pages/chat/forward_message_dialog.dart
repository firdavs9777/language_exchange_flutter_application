import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
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
          print('Error loading user $userId: $e');
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
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Forward Message',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Text(_error, style: const TextStyle(color: Colors.red))
                : _users.isEmpty
                    ? Text(AppLocalizations.of(context)!.noUsersAvailableToForwardTo)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Select users to forward to:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final isSelected = _selectedUserIds.contains(user.id);
                                
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedUserIds.add(user.id);
                                      } else {
                                        _selectedUserIds.remove(user.id);
                                      }
                                    });
                                  },
                                  title: Text(user.name),
                                  subtitle: user.email.isNotEmpty 
                                      ? Text(user.email) 
                                      : null,
                                  secondary: CircleAvatar(
                                    radius: 20,
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
                                            style: const TextStyle(fontSize: 18),
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
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedUserIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedUserIds.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: Text(
            'Forward (${_selectedUserIds.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

