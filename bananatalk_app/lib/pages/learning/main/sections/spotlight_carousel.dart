import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/pages/announcements/announcement_screen.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/promo/announcement_modal.dart';

/// Which spotlight announcements this account dismissed. User-scoped prefs
/// (cleared at logout). Unreadable storage -> empty set, i.e. show them.
class SpotlightDismissStore {
  static const key = 'study_spotlight_dismissed';

  static Future<Set<String>> read() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(key) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> dismiss(String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      final cur = p.getStringList(key) ?? <String>[];
      if (!cur.contains(id)) await p.setStringList(key, [...cur, id]);
    } catch (_) {}
  }
}

final spotlightDismissedProvider =
    FutureProvider<Set<String>>((ref) => SpotlightDismissStore.read());

/// Not dismissed, server order, at most 3.
List<Announcement> spotlightItems(List<Announcement> all, Set<String> dismissed) =>
    all.where((a) => !dismissed.contains(a.id)).take(3).toList();

class SpotlightCarousel extends ConsumerStatefulWidget {
  const SpotlightCarousel({super.key});

  @override
  ConsumerState<SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends ConsumerState<SpotlightCarousel> {
  int _page = 0;

  void _open(Announcement a) {
    AnalyticsService.instance.studySpotlightTap(a.id);
    if (a.hasButton) {
      openAnnouncementLink(a.buttonUrl!);
    } else {
      Navigator.push(context, AppPageRoute(builder: (_) => AnnouncementScreen(id: a.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(appConfigProvider).valueOrNull?.announcements ?? const <Announcement>[];
    final dismissed = ref.watch(spotlightDismissedProvider).valueOrNull ?? const <String>{};
    final items = spotlightItems(all, dismissed);
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final page = _page.clamp(0, items.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: StudyHubMetrics.carouselCardHeight,
          child: PageView.builder(
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final a = items[i];
              return Padding(
                padding: const EdgeInsets.only(right: StudyHubMetrics.tileGap),
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(StudyHubMetrics.cardRadius),
                    onTap: () => _open(a),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          if (a.emoji != null) ...[
                            Text(a.emoji!, style: text.headlineSmall),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                if (a.hasButton)
                                  Text(a.buttonLabel!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.labelLarge?.copyWith(color: scheme.primary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                            onPressed: () async {
                              await SpotlightDismissStore.dismiss(a.id);
                              ref.invalidate(spotlightDismissedProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
