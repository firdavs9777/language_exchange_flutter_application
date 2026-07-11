import 'dart:async';

import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Banana-yellow accent used for the pending-intros count chip.
const _kBananaAccent = Color(0xFFFFD54F);

/// Teal ring color drawn around intro-request avatars.
const _kTealRing = Color(0xFF00BFA5);

/// Horizontal strip of pending "intro" (wave) requests shown at the top of
/// the chat list, between the filter tabs and the conversation list.
///
/// Renders nothing (zero height) when there are no pending intros, still
/// loading, or the fetch failed — this is a lightweight nudge, not a
/// required element, so it should never show a spinner or error state.
class IntroRequestsStrip extends ConsumerWidget {
  const IntroRequestsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final introsAsync = ref.watch(pendingIntrosProvider);

    return introsAsync.when(
      data: (waves) {
        if (waves.isEmpty) return const SizedBox.shrink();
        return _IntroRequestsStripContent(waves: waves);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _IntroRequestsStripContent extends ConsumerWidget {
  final List<Wave> waves;

  const _IntroRequestsStripContent({required this.waves});

  Future<void> _markRead(WidgetRef ref, String waveId) async {
    try {
      await ref
          .read(communityServiceProvider)
          .markWavesAsRead(waveIds: [waveId]);
    } catch (_) {
      // Best-effort: even if the network call fails, refresh the local
      // state so the UI doesn't get stuck showing a stale intro.
    } finally {
      ref.invalidate(pendingIntrosProvider);
      ref.invalidate(wavesUnreadProvider);
    }
  }

  void _onCardTap(
    BuildContext context,
    WidgetRef ref,
    Wave wave,
  ) {
    // Guard against deleted/unknown senders: nothing sensible to navigate
    // to, but the card should still be dismissible via the close button.
    if (wave.fromUserId.isEmpty) return;

    // Navigate immediately for a responsive tap — don't make the user wait
    // on the mark-read network round trip. The read/invalidate work happens
    // in the background afterwards.
    context.push('/chat/${wave.fromUserId}');
    unawaited(_markRead(ref, wave.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              // TODO: l10n batch
              Text(
                'Intro requests',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _kBananaAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${waves.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: waves.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final wave = waves[index];
              return _IntroCard(
                key: ValueKey(wave.id),
                wave: wave,
                onTap: () => _onCardTap(context, ref, wave),
                onDismiss: () => _markRead(ref, wave.id),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  final Wave wave;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _IntroCard({
    super.key,
    required this.wave,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeAgo = timeago.format(wave.createdAt);
    final preview =
        wave.message?.isNotEmpty == true ? wave.message! : '👋';

    return SizedBox(
      width: 200,
      height: 88,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: _kTealRing, width: 2),
                    ),
                  ),
                  child: CachedCircleAvatar(
                    imageUrl: wave.fromUserImage,
                    radius: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              wave.fromUserName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                    height: 1.1,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: onDismiss,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.1,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              height: 1.0,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
