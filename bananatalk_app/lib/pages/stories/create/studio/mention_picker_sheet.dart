import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Bottom sheet for tagging a story with a mention: a searchable list of the
/// current user's followings (reuses [AuthService.getFollowingsUser] — the
/// same call the profile "Following" screen makes; no new endpoint). Tapping
/// a row pops a [StoryMention] positioned at the default sticker spot
/// (x:50, y:80) — the create screen doesn't offer drag-to-place, matching
/// the location sticker's fixed-chip UX.
Future<StoryMention?> showMentionPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<StoryMention>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _MentionSheet(ref: ref),
  );
}

class _MentionSheet extends StatefulWidget {
  const _MentionSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_MentionSheet> createState() => _MentionSheetState();
}

class _MentionSheetState extends State<_MentionSheet> {
  final _controller = TextEditingController();
  List<Community> _followings = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await widget.ref.read(userProvider.future);
      final followings = await widget.ref.read(authServiceProvider).getFollowingsUser(
            id: me.id,
            followingIds: me.followings,
          );
      if (mounted) setState(() => _followings = followings);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Community> get _filtered {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return _followings;
    return _followings.where((u) => u.name.toLowerCase().contains(q)).toList();
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
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search people you follow…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
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
      return const Center(child: Text('Could not load followings'));
    }
    final results = _filtered;
    if (results.isEmpty) {
      return const Center(child: Text('No one to mention yet'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final u = results[index];
        return ListTile(
          leading: CachedCircleAvatar(
            radius: 20,
            imageUrl: u.imageUrls.isNotEmpty ? u.imageUrls.first : null,
            errorWidget: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?'),
          ),
          title: Text(u.name),
          onTap: () => Navigator.pop(
            context,
            StoryMention(userId: u.id, username: u.name, x: 50, y: 80),
          ),
        );
      },
    );
  }
}
