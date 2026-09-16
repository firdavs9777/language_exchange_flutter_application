/// Pure time helpers for 모임.
///
/// Kept free of Flutter and of `DateTime.now()` — every function takes the
/// clock as a parameter — so the behaviour that decides whether anyone turns
/// up can be table-tested across timezones instead of being verified by
/// waiting.
///
/// The rule these exist to enforce: **a gathering time is always rendered in
/// the viewer's own zone.** An ambiguous time across Shanghai, Seoul and
/// Europe is a guaranteed no-show, and this audience spans all of them.
library;

/// How a start time relates to the viewer's *local* calendar — not to a fixed
/// number of hours away. 23:00 tonight and 01:00 tomorrow are two hours apart
/// and belong in different buckets, because "Tomorrow" is what a person plans
/// around.
enum GatheringDayBucket { past, today, tomorrow, thisWeek, later }

/// Both instants are converted to local time first, then compared by calendar
/// day. Comparing raw `Duration`s is the bug this avoids.
GatheringDayBucket gatheringDayBucket(DateTime startsAt, DateTime now) {
  final start = startsAt.toLocal();
  final local = now.toLocal();

  if (start.isBefore(local)) return GatheringDayBucket.past;

  final startDay = DateTime(start.year, start.month, start.day);
  final today = DateTime(local.year, local.month, local.day);
  final days = startDay.difference(today).inDays;

  if (days <= 0) return GatheringDayBucket.today;
  if (days == 1) return GatheringDayBucket.tomorrow;
  if (days <= 6) return GatheringDayBucket.thisWeek;
  return GatheringDayBucket.later;
}

/// Whole minutes until the start, floored at zero. Used for the "starts in 25
/// minutes" line and for deciding when to stop showing a countdown at all.
int minutesUntil(DateTime startsAt, DateTime now) {
  final diff = startsAt.toLocal().difference(now.toLocal()).inMinutes;
  return diff < 0 ? 0 : diff;
}

/// True inside the last hour before the start — when a countdown in minutes
/// is more useful than a clock time.
bool isImminent(DateTime startsAt, DateTime now) {
  if (startsAt.toLocal().isBefore(now.toLocal())) return false;
  return minutesUntil(startsAt, now) <= 60;
}

/// True once the gathering is under way but not yet over, so the card can say
/// "happening now" rather than showing a time that has passed.
bool isUnderway(DateTime startsAt, int durationMinutes, DateTime now) {
  final start = startsAt.toLocal();
  final local = now.toLocal();
  if (local.isBefore(start)) return false;
  return local.isBefore(start.add(Duration(minutes: durationMinutes)));
}

/// `HH:mm` in the viewer's zone, 24-hour. The headline time on every card.
String formatLocalClock(DateTime startsAt) {
  final local = startsAt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// The host's zone, shown *beneath* the viewer's local time so it is clear
/// whose clock the headline number belongs to.
///
/// Deliberately the IANA zone name and not the host's wall-clock time: the
/// app carries no tz database (`flutter_timezone` reports the device's own
/// zone, it does not convert between zones), and a converted time computed
/// from a fixed offset would be silently wrong across a DST boundary. A zone
/// name that is merely less precise beats a time that is confidently wrong —
/// the whole point of this line is to remove ambiguity, not add a second
/// number that might disagree with the first.
///
/// Returns null when the host has no recorded zone, in which case the caller
/// shows nothing rather than an empty label.
String? hostZoneLabel(String? hostTimezone) {
  final zone = hostTimezone?.trim();
  if (zone == null || zone.isEmpty) return null;
  // "Asia/Seoul" -> "Asia/Seoul"; keep it verbatim. Prettifying by stripping
  // the region would turn "America/New_York" and "Europe/New_York"-style
  // collisions into the same string.
  return zone;
}

/// Whether the viewer and the host are in the same zone, so the host line can
/// be suppressed as noise rather than repeating the time the viewer already
/// sees.
bool hostZoneWorthShowing(String? hostTimezone, String? viewerTimezone) {
  final host = hostTimezone?.trim();
  if (host == null || host.isEmpty) return false;
  final viewer = viewerTimezone?.trim();
  if (viewer == null || viewer.isEmpty) return true;
  return host.toLowerCase() != viewer.toLowerCase();
}

/// The default a create form opens on: tomorrow evening, local, on the hour.
///
/// The empty state is a pre-filled draft rather than an apology, and this is
/// the value it is pre-filled with — 19:00 tomorrow is late enough to be
/// after work in most of this audience and near enough to be real.
DateTime defaultGatheringStart(DateTime now, {int hour = 19}) {
  final local = now.toLocal();
  final tomorrow = DateTime(local.year, local.month, local.day).add(
    const Duration(days: 1),
  );
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour);
}
