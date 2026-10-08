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
    let callId = (extraIn["callId"] as? String) ?? (dict["callId"] as? String) ?? callUuid
    let callerName = (dict["nameCaller"] as? String)
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

    if pushType == "call_cancelled" {
      if isReported(callUuid) {
        endReportedCall(callUuid)
        completion()
      } else {
        // The cancel overtook the invite. PushKit still demands a report:
        // report it, end it at once, and remember it for a late invite.
        rememberCancelled(callUuid)
        reportAndEnd(data, callUuid: callUuid, completion: completion)
      }
      return
    }

    if wasRecentlyCancelled(callUuid) {
      reportAndEnd(data, callUuid: callUuid, completion: completion)
      return
    }

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .showCallkitIncoming(data, fromPushKit: true) {
        completion()
      }
  }

  // MARK: - call_cancelled helpers

  private static func normalizedUuid(_ raw: String?) -> String {
    if let raw = raw, UUID(uuidString: raw) != nil { return raw.lowercased() }
    return UUID().uuidString.lowercased()
  }

  private func isReported(_ callUuid: String) -> Bool {
    let calls = SwiftFlutterCallkitIncomingPlugin.sharedInstance?.activeCalls() ?? []
    return calls.contains { (($0["id"] as? String) ?? "").lowercased() == callUuid }
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
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .showCallkitIncoming(data, fromPushKit: true) { [weak self] in
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
