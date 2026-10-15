import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// A picked comment photo used to be dropped: only the GIF URL was sent, so
/// a photo-only comment posted blank.
void main() {
  final url = Uri.parse('https://api.example/api/v1/moments/m1/comments');

  test('a photo comment is a multipart POST with the photo as "image"',
      () async {
    final dir = await Directory.systemTemp.createTemp('comment_photo');
    final photo = File('${dir.path}/pic.jpg')..writeAsBytesSync([1, 2, 3]);
    addTearDown(() => dir.deleteSync(recursive: true));

    final request = await CommentsService.buildCreateCommentRequest(
      url: url,
      token: 't',
      text: '',
      parentCommentId: 'p1',
      image: photo,
    );

    expect(request, isA<http.MultipartRequest>());
    final multipart = request as http.MultipartRequest;
    expect(multipart.method, 'POST');
    expect(multipart.headers['Authorization'], 'Bearer t');
    expect(multipart.fields['text'], '');
    expect(multipart.fields['parentComment'], 'p1');
    expect(multipart.files.single.field, 'image');
    expect(multipart.files.single.contentType.mimeType, 'image/jpeg');
  });

  test('a text or GIF comment stays a JSON POST', () async {
    final request = await CommentsService.buildCreateCommentRequest(
      url: url,
      token: 't',
      text: 'hi',
      imageUrl: 'https://media.giphy.com/media/x/giphy.gif',
    );

    expect(request, isA<http.Request>());
    final body = jsonDecode((request as http.Request).body);
    expect(body['text'], 'hi');
    expect(body['imageUrl'], 'https://media.giphy.com/media/x/giphy.gif');
  });
}
