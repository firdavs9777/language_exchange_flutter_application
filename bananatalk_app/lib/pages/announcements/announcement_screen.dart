import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/providers/announcement_provider.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';

/// Opened from the notifications list or the push (spec §5.2).
class AnnouncementScreen extends ConsumerWidget {
  const AnnouncementScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final Widget body;
    if (id.trim().isEmpty) {
      body = const _Unavailable();
    } else {
      body = ref.watch(announcementDetailProvider(id)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _Unavailable(
              onRetry: () => ref.invalidate(announcementDetailProvider(id)),
            ),
            data: (a) {
              if (a == null) return const _Unavailable();
              // Read here: the launch pop-up must not repeat it.
              AnnouncementSeenStore.add(a.id).ignore();
              return _Body(announcement: a);
            },
          );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.announcementTitle)),
      body: body,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (a.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              a.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (a.emoji != null) ...[
          Text(a.emoji!, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
        ],
        Text(
          a.title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SelectableText(
          a.body,
          style: TextStyle(fontSize: 15, height: 1.6, color: context.textSecondary),
        ),
        if (a.hasButton) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => openAnnouncementLink(a.buttonUrl!),
            child: Text(a.buttonLabel!),
          ),
        ],
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(l10n.announcementUnavailable, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
