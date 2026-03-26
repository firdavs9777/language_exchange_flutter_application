// Conditional export based on platform
// Uses mobile implementation on iOS/Android, stub on desktop
export 'voice_recorder_stub.dart'
    if (dart.library.io) 'voice_recorder_mobile.dart';
