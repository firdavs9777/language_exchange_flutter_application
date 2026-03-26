// Voice recorder widget with platform detection
// Uses mobile implementation on iOS/Android, stub on desktop/web

export 'voice_recorder/voice_recorder_mobile.dart'
    if (dart.library.js_interop) 'voice_recorder/voice_recorder_stub.dart';
