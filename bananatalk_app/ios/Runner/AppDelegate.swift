import UIKit
import CallKit
import AVFAudio
import PushKit
import Flutter
import UserNotifications
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

  /// callUuids whose call_cancelled arrived before (or without) the invite.
  /// Kept 60 s so a late invite is reported and ended at once, not rung.
  private var cancelledCallUuids: [String: Date] = [:]
  private let callController = CXCallController()
  private static let appName = "Bananatalk"

  /// Missed-call Call back / Message taps on a REMOTE notification (category
  /// MISSED_CALL). Kept until Dart asks with takePending (cold start), and
  /// also sent as `action` when Dart is already listening (warm).
  private var missedCallChannel: FlutterMethodChannel?
  private var pendingMissedCallAction: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // FlutterAppDelegate forwards notification callbacks to every plugin
    // (firebase_messaging, flutter_local_notifications); being the delegate
    // also lets the override below see MISSED_CALL action taps first.
    UNUserNotificationCenter.current().delegate = self
    if let registrar = self.registrar(forPlugin: "BananatalkMissedCallActions") {
      let channel = FlutterMethodChannel(
        name: "bananatalk/missed_call_actions",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "takePending" {
          result(self?.pendingMissedCallAction)
          self?.pendingMissedCallAction = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      missedCallChannel = channel
    }

    // App icon badge (lib/services/app_icon_badge.dart). The server sets
    // aps.badge to the unread-message count on pushes; Dart sets the same
    // count after reading chats, on launch and to 0 at logout.
    if let registrar = self.registrar(forPlugin: "BananatalkAppBadge") {
      let badgeChannel = FlutterMethodChannel(
        name: "bananatalk/app_badge",
        binaryMessenger: registrar.messenger()
      )
      badgeChannel.setMethodCallHandler { call, result in
        guard call.method == "setBadge" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let args = call.arguments as? [String: Any]
        let count = max(0, args?["count"] as? Int ?? 0)
        if #available(iOS 16.0, *) {
          UNUserNotificationCenter.current().setBadgeCount(count) { _ in
            DispatchQueue.main.async { result(nil) }
          }
        } else {
          DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            result(nil)
          }
        }
      }
    }

    // VoIP push registration. iOS 13+ requires EVERY VoIP push to report a
    // call to CallKit before the handler completes, or the app loses its
    // VoIP entitlement — including call_cancelled pushes (see below).
    let voipRegistry = PKPushRegistry(queue: .main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  // MARK: - Missed-call notification actions

  /// Intercepts only REMOTE (gcm.message_id) MISSED_CALL button taps; every
  /// other response goes to the plugins as before. Local copies (foreground)
  /// are flutter_local_notifications' own and reach Dart through it.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let content = response.notification.request.content
    let action = response.actionIdentifier
    let isRemote = content.userInfo["gcm.message_id"] != nil
    if isRemote && content.categoryIdentifier == "MISSED_CALL"
      && (action == "call_back" || action == "message") {
      let payload: [String: Any] = [
        "action": action,
        "callId": content.userInfo["callId"] as? String ?? "",
        "callerId": content.userInfo["callerId"] as? String ?? "",
        "callType": content.userInfo["callType"] as? String ?? "audio",
      ]
      // Cold start: Dart is not listening yet, so keep it for takePending.
      // Warm: Dart routes the invoke now and clears this copy; the Dart side
      // routes each call once, so a replay is harmless.
      pendingMissedCallAction = payload
      missedCallChannel?.invokeMethod("action", arguments: payload)
      completionHandler()
      return
    }
    // firebase_messaging (no original delegate to forward to) and
    // flutter_local_notifications may both complete: the first call wins.
    var completed = false
    let once: () -> Void = {
      if completed { return }
      completed = true
      completionHandler()
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: once)
  }

  /// Foreground presentation stays what it was before this AppDelegate became
  /// the delegate (firebase alone answered: badge only, per
  /// setForegroundNotificationPresentationOptions(alert: false, sound: false)),
  /// for every notification except the app's own local missed-call copy,
  /// which shows as a banner with its Call back / Message buttons. The
  /// plugins still run (firebase needs it for onMessage); their later
  /// completions are no-ops.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    var completed = false
    let once: (UNNotificationPresentationOptions) -> Void = { options in
      if completed { return }
      completed = true
      completionHandler(options)
    }
    let content = notification.request.content
    let isRemote = content.userInfo["gcm.message_id"] != nil
    if !isRemote && content.categoryIdentifier == "MISSED_CALL" {
      once([.banner, .list, .sound, .badge])
    } else {
      once([.badge])
    }
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: once)
  }

  // MARK: - PKPushRegistryDelegate (VoIP)

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    NSLog("📞 VoIP push token: \(deviceToken)")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    NSLog("📞 VoIP push token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// Incoming VoIP push: an incoming call (`id` = callUuid, `extra.callId` =
  /// server id) or a `call_cancelled`. The CallKit id is always a valid,
  /// lowercase UUID — the plugin force-unwraps UUID(uuidString:).
  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let dict = payload.dictionaryPayload
    let extraIn = dict["extra"] as? [String: Any] ?? [:]
    let pushType = (dict["type"] as? String) ?? "incoming_call"
    let callUuid = AppDelegate.normalizedUuid(
      (dict["callUuid"] as? String) ?? (extraIn["callUuid"] as? String) ?? (dict["id"] as? String)
    )
    // Legacy payloads put the server id (24-hex) in `id`; keep it as callId.
    let legacyId = (dict["id"] as? String).flatMap { UUID(uuidString: $0) == nil ? $0 : nil }
    let callId = (extraIn["callId"] as? String) ?? (dict["callId"] as? String) ?? legacyId ?? callUuid
    let isCancel = pushType == "call_cancelled"
    // A cancel carries no caller: a report-and-end shows the app name, never "Unknown".
    let callerName = isCancel
      ? AppDelegate.appName
      : (dict["nameCaller"] as? String)
        ?? (dict["callerName"] as? String)
        ?? (extraIn["callerName"] as? String)
        ?? "Unknown"
    let handle = (dict["handle"] as? String) ?? (dict["callerId"] as? String) ?? callerName
    let callType = (dict["callType"] as? String) ?? (extraIn["callType"] as? String) ?? "audio"
    let isVideo = (dict["isVideo"] as? Bool) ?? (callType == "video")

    let data = flutter_callkit_incoming.Data(
      id: callUuid,
      nameCaller: callerName,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    // Same CallKit look as CallKitService on the Dart side. The server owns
    // the 45 s ring (it sends call_cancelled); the native 50 s ring is only a
    // safety net, so iOS never times out first and re-reports an ended call.
    data.appName = AppDelegate.appName
    data.iconName = "AppIcon"
    data.duration = 50000
    // Same contract as CallKitService.buildIncomingParams on the Dart side.
    var extra: [String: Any] = [
      "callId": callId,
      "callUuid": callUuid,
      "callType": callType,
      "callerName": callerName,
    ]
    for key in ["callerId", "livekitUrl", "roomName"] {
      if let value = (extraIn[key] as? String) ?? (dict[key] as? String) { extra[key] = value }
    }
    if let avatar = (extraIn["callerAvatar"] as? String) ?? (dict["callerProfilePicture"] as? String) {
      extra["callerAvatar"] = avatar
    }
    data.extra = extra as NSDictionary

    if isCancel {
      // Remember it either way, so a duplicate or late invite never rings.
      rememberCancelled(callUuid)
      // PushKit demands a report for EVERY VoIP push, this one included.
      // If the call is still ringing, CallKit rejects the report with
      // callUUIDAlreadyExists (no second ring; the plugin only calls
      // completion) and the end action stops the ringing call. If the
      // cancel overtook the invite, the report flashes and is ended at once.
      reportAndEnd(data, callUuid: callUuid, completion: completion)
      return
    }

    if wasRecentlyCancelled(callUuid) {
      reportAndEnd(data, callUuid: callUuid, completion: completion)
      return
    }

    guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
      completion()
      return
    }
    plugin.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }

  // MARK: - call_cancelled helpers

  private static func normalizedUuid(_ raw: String?) -> String {
    if let raw = raw, UUID(uuidString: raw) != nil { return raw.lowercased() }
    return UUID().uuidString.lowercased()
  }

  private func endReportedCall(_ callUuid: String) {
    guard let uuid = UUID(uuidString: callUuid) else { return }
    let transaction = CXTransaction(action: CXEndCallAction(call: uuid))
    callController.request(transaction) { error in
      if let error = error { NSLog("📞 ending cancelled call failed: \(error)") }
    }
  }

  private func reportAndEnd(
    _ data: flutter_callkit_incoming.Data,
    callUuid: String,
    completion: @escaping () -> Void
  ) {
    guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
      completion()
      return
    }
    plugin.showCallkitIncoming(data, fromPushKit: true) { [weak self] in
      self?.endReportedCall(callUuid)
      completion()
    }
  }

  private func rememberCancelled(_ callUuid: String) {
    pruneCancelled()
    cancelledCallUuids[callUuid] = Date()
  }

  private func wasRecentlyCancelled(_ callUuid: String) -> Bool {
    pruneCancelled()
    return cancelledCallUuids[callUuid] != nil
  }

  private func pruneCancelled() {
    let cutoff = Date().addingTimeInterval(-60)
    cancelledCallUuids = cancelledCallUuids.filter { $0.value > cutoff }
  }
}
