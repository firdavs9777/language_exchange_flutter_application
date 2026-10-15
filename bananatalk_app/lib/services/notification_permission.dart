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
///
/// [isAndroid] matters for `denied` only. firebase_messaging on Android never
/// reports notDetermined: Android 12 and below read as authorized, and Android
/// 13+ reads as denied until POST_NOTIFICATIONS is granted -- including on a
/// fresh install that has never been asked. So on Android a `denied` we have
/// not prompted for is really "not asked yet" and gets [NotificationAction.ask];
/// only once [alreadyPrompted] is set is it a real refusal. If the OS has in
/// fact stopped showing the dialog, the prime's request simply comes back
/// denied and the sheet records a decline.
NotificationAction notificationActionFor({
  required NotificationPermission permission,
  required bool alreadyPrompted,
  required bool isAndroid,
}) {
  switch (permission) {
    case NotificationPermission.authorized:
      return NotificationAction.none;
    case NotificationPermission.denied:
      return isAndroid && !alreadyPrompted
          ? NotificationAction.ask
          : NotificationAction.recover;
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

/// Whether to quietly request provisional authorization during start-up.
///
/// iOS only, and only for a user who has never been asked. Provisional is
/// granted WITHOUT a dialog, so this costs the user nothing and yields a token
/// immediately — which is where the app's existing iOS token coverage comes
/// from. Removing it in favour of asking later would trade 407 silent grants
/// for a dialog many users never reach.
///
/// It is deliberately NOT the whole answer: provisional delivers quietly, so
/// [notificationActionFor] still returns [NotificationAction.upgrade] for the
/// resulting state, and the visible-delivery dialog is raised later at a primed
/// moment.
///
/// Android has no provisional concept — `requestPermission` there raises the
/// real POST_NOTIFICATIONS dialog — so asking at start-up would put the cold
/// prompt straight back on the splash screen.
bool shouldRequestProvisionalAtStartup({
  required NotificationPermission permission,
  required bool isIOS,
}) =>
    isIOS && permission == NotificationPermission.notDetermined;

/// Whether a primed-moment sheet may be shown for [action]. Only the two
/// "ask" actions qualify; `recover` has its own settings surface and `null`
/// means the service has not initialised yet.
bool shouldPrimeNotifications(NotificationAction? action) =>
    action == NotificationAction.ask || action == NotificationAction.upgrade;

/// Whether a grant needs the handler and local-notification set-up run now.
///
/// Start-up skips that set-up for a `denied` status, which on Android 13+ is
/// every user who has not yet been asked. Without this, someone who grants
/// from the priming sheet would get a token but no foreground display, tap
/// routing or notification channels until the next cold start.
bool needsDeliverySetUpAfterGrant({
  required bool granted,
  required bool deliverySetUp,
}) =>
    granted && !deliverySetUp;
