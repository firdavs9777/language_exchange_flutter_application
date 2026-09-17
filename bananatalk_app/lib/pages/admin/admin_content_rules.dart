/// The decisions behind a moderation row, separated from how it is drawn.
///
/// AdminService talks to the network through top-level `http` functions, so
/// the screen itself cannot be driven from a test without refactoring a
/// service every admin screen shares. These are the parts that can actually be
/// WRONG — which action a row offers, whether it has already been acted on,
/// what it says about itself — so they are pulled out where they can be
/// checked.
library;

/// Statuses that mean "already removed from discovery".
///
/// A club is archived; a gathering is cancelled. Both are states the app
/// already filters on, which is why moderation uses them instead of deleting.
const Set<String> kRemovedStatuses = {'archived', 'cancelled'};

bool isRemoved(String? status) =>
    status != null && kRemovedStatuses.contains(status);

/// What the row's button does.
///
/// A club can be put back, so its action flips to Restore once archived. A
/// gathering cannot be un-cancelled — people were told it was off, and
/// silently reinstating it would summon them back to something they have
/// stopped planning around — so it keeps saying Cancel and the server rejects
/// a second attempt.
String moderationActionLabel({required bool isClub, String? status}) {
  if (!isClub) return 'Cancel';
  return isRemoved(status) ? 'Restore' : 'Archive';
}

/// Whether taking this action needs a reason.
///
/// Removing something does; putting it back does not. The reason lands in the
/// audit log, and an entry reading only "a club was archived" cannot be
/// reviewed later by anyone, including the moderator who wrote it.
bool actionNeedsReason({required bool isClub, String? status}) =>
    !(isClub && isRemoved(status));

/// The one-line summary under the name: who made it, its state, how big it is.
///
/// Empty parts are dropped rather than rendered as stray separators — an owner
/// with no name is common in unpopulated payloads.
String moderationSubtitle({
  required bool isClub,
  String? ownerName,
  String? status,
  int count = 0,
}) {
  final parts = <String>[
    if (ownerName != null && ownerName.trim().isNotEmpty) ownerName.trim(),
    if (status != null && status.trim().isNotEmpty) status.trim(),
    isClub ? '$count members' : '$count going',
  ];
  return parts.join(' · ');
}
