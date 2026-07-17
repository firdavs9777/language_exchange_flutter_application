import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

/// Outcome of a share-to-friends send, used to pick the summary snackbar.
class _ShareSendResult {
  final int successCount;
  final List<String> failedNames;

  const _ShareSendResult({required this.successCount, required this.failedNames});
}

/// Bottom sheet to share a story into a BananaTalk DM as a tappable story
/// card. Source list is the user's recent chat partners — the same data
/// `chat_list_screen.dart` fetches via `MessageService.getChatPartners`
/// (no separate "all followings" search; recent partners cover the common
/// case and keep this sheet to one request).
///
/// Sending loops `StoriesService.shareStory` per selected partner so one
/// failed recipient doesn't block the rest; failures are collected and
/// summarized in a single snackbar after the sheet closes.
Future<void> showStoryShareSheet(
  BuildContext context,
  WidgetRef ref,
  Story story,
) async {
  final result = await showModalBottomSheet<_ShareSendResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _StoryShareSheet(ref: ref, story: story),
  );

  if (result == null || !context.mounted) return;

  if (result.failedNames.isEmpty) {
    showChatSnackBar(context, message: 'Sent 💛', type: ChatSnackBarType.success);
  } else if (result.successCount == 0) {
    showChatSnackBar(
      context,
      message: "Couldn't send to ${result.failedNames.join(', ')}",
      type: ChatSnackBarType.error,
    );
  } else {
    showChatSnackBar(
      context,
      message: 'Sent 💛 — failed for ${result.failedNames.join(', ')}',
      type: ChatSnackBarType.info,
    );
  }
}

class _StoryShareSheet extends StatefulWidget {
  const _StoryShareSheet({required this.ref, required this.story});
  final WidgetRef ref;
  final Story story;

  @override
  State<_StoryShareSheet> createState() => _StoryShareSheetState();
}

class _StoryShareSheetState extends State<_StoryShareSheet> {
  final _controller = TextEditingController();
  List<ChatPartnerData> _partners = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _failed = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await widget.ref.read(userProvider.future);
      final partners = await widget.ref
          .read(messageServiceProvider)
          .getChatPartners(id: me.id, limit: 50);
      if (mounted) setState(() => _partners = partners);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ChatPartnerData> get _filtered {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return _partners;
    return _partners.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _send() async {
    if (_selectedIds.isEmpty || _sending) return;
    setState(() => _sending = true);

    var successCount = 0;
    final failedNames = <String>[];
    for (final id in _selectedIds) {
      final partner = _partners.firstWhere((p) => p.id == id);
      try {
        final res = await StoriesService.shareStory(
          storyId: widget.story.id,
          sharedTo: 'dm',
          receiverId: id,
        );
        if (res['success'] == true) {
          successCount++;
        } else {
          failedNames.add(partner.name);
        }
      } catch (_) {
        failedNames.add(partner.name);
      }
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      _ShareSendResult(successCount: successCount, failedNames: failedNames),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Send to friends',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_selectedIds.isNotEmpty)
                      Text(
                        '${_selectedIds.length} selected',
                        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search recent chats…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty || _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            _selectedIds.isEmpty
                                ? 'Send'
                                : 'Send (${_selectedIds.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return const Center(child: Text('Could not load your chats'));
    }
    final results = _filtered;
    if (results.isEmpty) {
      return const Center(child: Text('No recent chats to send to'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final partner = results[index];
        final isSelected = _selectedIds.contains(partner.id);
        return ListTile(
          leading: CachedCircleAvatar(
            radius: 20,
            imageUrl: partner.profileImageUrl,
            errorWidget: Text(
              partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
            ),
          ),
          title: Text(partner.name),
          trailing: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isSelected ? AppColors.primary : Theme.of(context).hintColor,
          ),
          onTap: () => _toggle(partner.id),
        );
      },
    );
  }
}
