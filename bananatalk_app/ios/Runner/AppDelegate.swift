import UIKit
import CallKit
import AVFAudio
import PushKit
import Flutter
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // VoIP push registration — required for reliable incoming-call delivery
    // when the app is backgrounded or killed. iOS 13+ enforces that EVERY
    // VoIP push must call CXProvider.reportNewIncomingCall within seconds
    // of receipt; failure to do so causes Apple to revoke the app's VoIP
    // entitlement. flutter_callkit_incoming's
    // showCallkitIncoming(_:fromPushKit:) handles that contract, so we
    // forward every push to it unconditionally below.
    //
    // Info.plist already declares `UIBackgroundModes: voip`. The backend
    // additionally needs a separate APNs auth key/cert with the VoIP
    // Services capability — see backend/services/voipPushService.js.
    let voipRegistry = PKPushRegistry(queue: .main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Google Sign-In URL handler — keep existing behavior (FlutterAppDelegate's
  // base implementation forwards to plugins, including google_sign_in).
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  // MARK: - PKPushRegistryDelegate (VoIP)

  /// Apple has issued (or rotated) a VoIP push token for this device. The
  /// token is hex-encoded and forwarded to the Dart layer via the plugin,
  /// which fires `Event.actionDidUpdateDevicePushTokenVoip`. Dart-side code
  /// uploads it to the backend so future incoming calls can be sent here.
  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let deviceToken = credentials.token
      .map { String(format: "%02x", $0) }
      .joined()
    NSLog("📞 VoIP push token: \(deviceToken)")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .setDevicePushTokenVoIP(deviceToken)
  }

  /// Apple invalidated the VoIP token (uninstall, log-out, etc.). Forward
  /// an empty token so the backend can purge the stale entry on its next
  /// refresh.
  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    NSLog("📞 VoIP push token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .setDevicePushTokenVoIP("")
  }

  /// An incoming VoIP push arrived. iOS 13+ REQUIRES that we report a new
  /// incoming call to CallKit synchronously (via the plugin's
  /// `showCallkitIncoming(_:fromPushKit:)`) before this handler returns —
  /// otherwise iOS terminates the app and may revoke the VoIP entitlement
  /// after repeated offenses. So we always call into the plugin regardless
  /// of payload sanity; missing fields just yield "Unknown caller" instead
  /// of nothing.
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

    let callId = dict["id"] as? String
      ?? dict["callId"] as? String
      ?? UUID().uuidString
    let callerName = dict["nameCaller"] as? String
      ?? dict["callerName"] as? String
      ?? "Unknown"
    let handle = dict["handle"] as? String
      ?? dict["callerId"] as? String
      ?? callerName
    let isVideo = (dict["isVideo"] as? Bool)
      ?? ((dict["callType"] as? String) == "video")

    let data = flutter_callkit_incoming.Data(
      id: callId,
      nameCaller: callerName,
      handle: handle,
      type: isVideo ? 1 : 0
    )

    // Carry pre-minted LiveKit credentials through to the accept handler so
    // the receiving side doesn't need a second /accept round-trip just to
    // get a token. NotificationRouter on the Dart side rehydrates the
    // CallModel from this `extra` payload (see notification_router.dart
    // _handleIncomingCallNotification).
    var extra: [String: Any] = ["callId": callId]
    if let token = dict["livekitToken"] as? String { extra["livekitToken"] = token }
    if let url = dict["livekitUrl"] as? String { extra["livekitUrl"] = url }
    if let room = dict["roomName"] as? String { extra["roomName"] = room }
    if let avatar = dict["callerProfilePicture"] as? String { extra["callerAvatar"] = avatar }
    if let callerId = dict["callerId"] as? String { extra["callerId"] = callerId }
    if let callType = dict["callType"] as? String { extra["callType"] = callType }
    data.extra = extra

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .showCallkitIncoming(data, fromPushKit: true) {
        completion()
      }
  }
}
