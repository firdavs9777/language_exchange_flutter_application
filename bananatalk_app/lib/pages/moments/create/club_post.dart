import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

/// Clubs v2 slice 3: what the composer sends for a club post.
///
/// Members-only (`'club'`) unless shared to Moments (`'public'`). Distance is
/// typed in km and time in minutes; the server stores metres and seconds.
/// Unreadable or empty numbers are simply left out.
({String privacy, Map<String, int>? activity}) clubPostFields({
  required bool shareToMoments,
  required String distanceKm,
  required String timeMin,
}) {
  double? read(String s) {
    final v = double.tryParse(s.trim().replaceAll(',', '.'));
    return v == null || v < 0 ? null : v;
  }

  final km = read(distanceKm);
  final min = read(timeMin);
  final activity = <String, int>{
    if (km != null) 'distanceM': (km * 1000).round(),
    if (min != null) 'durationS': (min * 60).round(),
  };
  return (
    privacy: shareToMoments ? 'public' : 'club',
    activity: activity.isEmpty ? null : activity,
  );
}

String _clock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// "5.2 km · 31:00 · 5:58/km" — whichever parts the post has.
String clubActivityLine(AppLocalizations l10n, MomentActivity a) {
  final parts = <String>[];
  final d = a.distanceM;
  final t = a.durationS;
  if (d != null && d > 0) {
    final km = d / 1000;
    parts.add(l10n.clubActivityKm(
        km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1)));
  }
  if (t != null && t > 0) parts.add(_clock(t));
  if (d != null && d > 0 && t != null && t > 0) {
    parts.add(l10n.clubActivityPace(_clock((t / (d / 1000)).round())));
  }
  return parts.join(' · ');
}

/// What the person chose in [ClubPostOptions].
class ClubPostOptionsValue {
  final bool shareToMoments;
  final String distanceKm;
  final String timeMin;

  const ClubPostOptionsValue({
    this.shareToMoments = false,
    this.distanceKm = '',
    this.timeMin = '',
  });
}

/// The club-post part of the composer, in place of the privacy picker:
/// "Also share to Moments" (off by default) and optional distance / time.
class ClubPostOptions extends StatefulWidget {
  const ClubPostOptions({super.key, required this.onChanged});

  final ValueChanged<ClubPostOptionsValue> onChanged;

  @override
  State<ClubPostOptions> createState() => _ClubPostOptionsState();
}

class _ClubPostOptionsState extends State<ClubPostOptions> {
  bool _share = false;
  final _distance = TextEditingController();
  final _time = TextEditingController();

  @override
  void dispose() {
    _distance.dispose();
    _time.dispose();
    super.dispose();
  }

  void _report() => widget.onChanged(ClubPostOptionsValue(
        shareToMoments: _share,
        distanceKm: _distance.text,
        timeMin: _time.text,
      ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const numbers = TextInputType.numberWithOptions(decimal: true);
    return Column(
      key: const Key('club-post-options'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.clubShareToMoments),
          subtitle: Text(l10n.clubShareToMomentsHint),
          value: _share,
          onChanged: (v) {
            setState(() => _share = v);
            _report();
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('club-activity-distance'),
                controller: _distance,
                keyboardType: numbers,
                onChanged: (_) => _report(),
                decoration: InputDecoration(labelText: l10n.clubActivityDistance),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('club-activity-time'),
                controller: _time,
                keyboardType: numbers,
                onChanged: (_) => _report(),
                decoration: InputDecoration(labelText: l10n.clubActivityTime),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
