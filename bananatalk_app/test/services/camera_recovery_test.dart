import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/camera_recovery.dart';

/// Android killed the app while the camera was open (2026-10-17, lmkd on a
/// Galaxy Tab); the photo must come back to the screen that asked for it.
class _Picker extends ImagePicker {
  _Picker(this.response);
  final LostDataResponse response;
  int calls = 0;

  @override
  Future<LostDataResponse> retrieveLostData() async {
    calls++;
    return response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final photo = LostDataResponse(file: XFile('/tmp/photo.jpg'), type: RetrieveType.image);

  test('a pending camera photo comes back with the screen that asked', () async {
    SharedPreferences.setMockInitialValues({});
    await CameraRecovery.markPending(CameraRecovery.imageVocab);
    final lost = await CameraRecovery.takeLost(picker: _Picker(photo), isAndroid: true);
    expect(lost?.target, CameraRecovery.imageVocab);
    expect(lost?.file.path, '/tmp/photo.jpg');
    // Taken once: a second launch does not reopen it.
    expect(await CameraRecovery.takeLost(picker: _Picker(photo), isAndroid: true), isNull);
  });

  test('nothing pending: the picker is not even asked', () async {
    SharedPreferences.setMockInitialValues({});
    final picker = _Picker(photo);
    expect(await CameraRecovery.takeLost(picker: picker, isAndroid: true), isNull);
    expect(picker.calls, 0);
  });

  test('the camera returned normally: clear() leaves nothing to recover', () async {
    SharedPreferences.setMockInitialValues({});
    await CameraRecovery.markPending(CameraRecovery.imageVocab);
    await CameraRecovery.clear();
    expect(await CameraRecovery.takeLost(picker: _Picker(photo), isAndroid: true), isNull);
  });

  test('pending but the picker lost nothing: null, and the mark is cleared', () async {
    SharedPreferences.setMockInitialValues({});
    await CameraRecovery.markPending(CameraRecovery.imageVocab);
    expect(await CameraRecovery.takeLost(picker: _Picker(LostDataResponse.empty()), isAndroid: true), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(CameraRecovery.prefsKey), isNull);
  });

  test('iOS never recovers (the app is not restarted that way there)', () async {
    SharedPreferences.setMockInitialValues({});
    await CameraRecovery.markPending(CameraRecovery.imageVocab);
    expect(await CameraRecovery.takeLost(picker: _Picker(photo), isAndroid: false), isNull);
  });
}
