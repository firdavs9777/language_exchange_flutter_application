import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bananatalk_app/services/call/call_platform.dart';

void main() {
  const granted = PermissionStatus.granted;
  const denied = PermissionStatus.denied;
  const permanentlyDenied = PermissionStatus.permanentlyDenied;

  List<Permission> ask({
    bool video = false,
    bool android = true,
    PermissionStatus mic = granted,
    PermissionStatus cam = granted,
    PermissionStatus bluetooth = granted,
  }) =>
      DeviceCallPlatform.callPermissionsToRequest(
        video: video,
        isAndroid: android,
        mic: mic,
        cam: cam,
        bluetooth: bluetooth,
      );

  group('call permissions (Bluetooth headset on Android 12+)', () {
    test('Bluetooth is asked together with the microphone on Android', () {
      expect(ask(mic: denied, bluetooth: denied), [Permission.microphone, Permission.bluetoothConnect]);
      expect(ask(video: true, mic: denied, cam: denied, bluetooth: denied),
          [Permission.microphone, Permission.camera, Permission.bluetoothConnect]);
    });

    test('Bluetooth alone is asked when the microphone is already granted', () {
      expect(ask(bluetooth: denied), [Permission.bluetoothConnect]);
    });

    test('never on iOS, and not again once permanently denied', () {
      expect(ask(android: false, mic: denied, bluetooth: denied), [Permission.microphone]);
      expect(ask(bluetooth: permanentlyDenied), isEmpty);
    });

    test('nothing to ask when everything is granted', () {
      expect(ask(video: true), isEmpty);
    });
  });
}
