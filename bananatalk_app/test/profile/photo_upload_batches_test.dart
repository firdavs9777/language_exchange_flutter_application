import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/profile/edit/picture_edit/photo_upload_handler.dart';

/// The server accepts at most 6 files per request and rejects the whole
/// request beyond that; the picker allows up to 10.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'token': 'jwt'});
    dir = await Directory.systemTemp.createTemp('photo-batches');
  });
  tearDown(() => dir.delete(recursive: true));

  List<File> photos(int n) => [
        for (var i = 0; i < n; i++)
          File('${dir.path}/p$i.jpg')..writeAsBytesSync([1, 2, 3]),
      ];

  Future<PhotoUploadResult> upload(
    List<File> files,
    Future<http.Response> Function(int call, int files) respond,
  ) async {
    var call = 0;
    return http.runWithClient(
      () => const PhotoUploadHandler(userId: 'u1').uploadPhotos(
        files,
        noTokenMessage: 'no token',
        fileTooLargeMessage: 'too large',
        unsupportedFormatPrefix: 'unsupported',
        failedMessage: 'failed',
      ),
      () => MockClient.streaming((req, body) async {
        final bytes = await body.toBytes();
        final count = 'name="photos"'.allMatches(latin1.decode(bytes)).length;
        final res = await respond(++call, count);
        return http.StreamedResponse(
            Stream.value(res.bodyBytes), res.statusCode);
      }),
    );
  }

  http.Response ok(List<String> images) => http.Response(
      jsonEncode({'success': true, 'message': 'ok', 'images': images}), 200);

  test('8 photos go up as 6 + 2', () async {
    final sizes = <int>[];
    final result = await upload(photos(8), (call, files) async {
      sizes.add(files);
      return ok(List.filled(call == 1 ? 7 : 9, 'u'));
    });
    expect(sizes, [6, 2]);
    expect(result.success, isTrue);
    expect(result.uploadedCount, 8);
    expect(result.imageUrls, hasLength(9));
  });

  test('up to 6 photos: one request', () async {
    final sizes = <int>[];
    await upload(photos(6), (call, files) async {
      sizes.add(files);
      return ok(['u']);
    });
    expect(sizes, [6]);
  });

  test('second batch fails: reports what already landed', () async {
    final result = await upload(photos(8), (call, files) async {
      if (call == 1) return ok(List.filled(7, 'u'));
      return http.Response(jsonEncode({'error': 'boom'}), 500);
    });
    expect(result.success, isFalse);
    expect(result.message, 'boom');
    expect(result.uploadedCount, 6);
    expect(result.imageUrls, hasLength(7));
  });
}
