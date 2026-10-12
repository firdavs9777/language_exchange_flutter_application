import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/providers/announcement_provider.dart';
import 'package:bananatalk_app/services/announcement_seen_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';

/// Opened from the notifications list or the push (spec §5.2).
class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key, required this.id, this.markSeen});

  final String id;

  /// Seam for tests; defaults to [AnnouncementSeenStore.add].
  final Future<void> Function(String id)? markSeen;

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  bool _marked = false;

  /// Once per screen instance, after the first frame that has data, so the
  /// launch pop-up does not repeat it. Never from build().
  void _markSeenOnce(String announcementId) {
    if (_marked) return;
    _marked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      (widget.markSeen ?? AnnouncementSeenStore.add)(announcementId).ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final id = widget.id;
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
              _markSeenOnce(a.id);
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
