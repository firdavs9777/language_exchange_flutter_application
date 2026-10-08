import UIKit
import CallKit
import AVFAudio
import PushKit
import Flutter
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

  /// callUuids whose call_cancelled arrived before (or without) the invite.
  /// Kept 60 s so a late invite is reported and ended at once, not rung.
  private var cancelledCallUuids: [String: Date] = [:]
  private let callController = CXCallController()
  private static let appName = "Bananatalk"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

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
