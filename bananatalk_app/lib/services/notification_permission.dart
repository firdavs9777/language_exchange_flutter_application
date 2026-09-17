/// What to do about notification permission, decided without touching the OS.
///
/// Pure, and free of Flutter and Firebase imports, so the decision can be
/// tested without a device. The logic it replaces lived inline in
/// `NotificationService.initialize()`, where it did two things wrong: it asked
/// unconditionally on the splash screen, and it treated `provisional` as
/// equivalent to `authorized`.
///
/// That second point is the expensive one. iOS grants provisional silently and
/// then delivers QUIETLY -- no banner, no sound, no lock-screen alert. A daily
/// study reminder delivered that way lands in Notification Center where nobody
/// looks, which is worse than not sending it, because it looks like it works.
library;

/// The permission states that change what we do.
///
/// Mirrors Firebase's `AuthorizationStatus` by name but deliberately not by
/// type, so this file imports nothing and stays testable on its own.
enum NotificationPermission { authorized, provisional, notDetermined, denied }

/// What the app should do next.
///
/// - [none]    leave the user alone
/// - [ask]     request permission for the first time (raises the OS dialog)
/// - [upgrade] ask a provisional iOS user for full, visible delivery
/// - [recover] the OS will not ask again; point at system settings instead
enum NotificationAction { none, ask, upgrade, recover }

/// SharedPreferences key recording that we have already spent our one chance.
const String kPromptedPrefsKey = 'notification_prompt_shown';

/// Decide what to do about this user's notification permission.
///
/// [alreadyPrompted] deliberately does NOT suppress [NotificationAction.recover]:
/// recovery is a piece of UI the user can act on whenever they like, not a
/// one-shot OS dialog, and someone who denied months ago should still be told
/// why their notifications are silent.
NotificationAction notificationActionFor({
  required NotificationPermission permission,
  required bool alreadyPrompted,
}) {
  switch (permission) {
    case NotificationPermission.authorized:
      return NotificationAction.none;
    case NotificationPermission.denied:
      return NotificationAction.recover;
    case NotificationPermission.provisional:
      return alreadyPrompted
          ? NotificationAction.none
          : NotificationAction.upgrade;
    case NotificationPermission.notDetermined:
      return alreadyPrompted ? NotificationAction.none : NotificationAction.ask;
  }
}

/// Map a Firebase `AuthorizationStatus.name` onto [NotificationPermission].
///
/// Anything unrecognised becomes [NotificationPermission.notDetermined] rather
/// than `authorized`. Guessing "authorized" would permanently suppress the ask
/// on a platform whose status name we failed to anticipate, and nothing would
/// ever be shown or logged -- the failure would be invisible in production.
NotificationPermission permissionFromStatusName(String name) {
  switch (name) {
    case 'authorized':
      return NotificationPermission.authorized;
    case 'provisional':
      return NotificationPermission.provisional;
    case 'denied':
      return NotificationPermission.denied;
    default:
      return NotificationPermission.notDetermined;
  }
}
