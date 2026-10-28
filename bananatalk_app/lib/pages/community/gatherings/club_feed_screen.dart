import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Clubs v2: all of a club's posts, as full moment cards.
class ClubFeedScreen extends ConsumerWidget {
  const ClubFeedScreen({super.key, required this.clubId, required this.title});

  final String clubId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final posts = ref.watch(clubMomentsProvider(clubId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(clubMomentsProvider(clubId).future),
        child: posts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(children: [
            Padding(padding: const EdgeInsets.all(24), child: Text(l10n.clubPostsEmpty)),
          ]),
          data: (items) => items.isEmpty
              ? ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.clubPostsEmpty, style: context.bodyMedium),
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => MomentCard(
                    moments: items[i],
                    onRefresh: () => ref.invalidate(clubMomentsProvider(clubId)),
                  ),
                ),
        ),
      ),
    );
  }
}
