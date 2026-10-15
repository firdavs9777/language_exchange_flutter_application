import 'dart:io';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/providers/provider_models/comments_model.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// #27: a failed comment cleared the text and bumped the count with no
/// rollback; the box went dead after the limit dialog; no 500-char limit.
class _FailingCommentsService extends CommentsService {
  int calls = 0;

  @override
  Future<Comments> createComment({
    required String title,
    required String id,
    String? parentCommentId,
    String? imageUrl,
    File? image,
    Map<String, dynamic>? correction,
  }) async {
    calls++;
    throw Exception('offline');
  }
}

void main() {
  late _FailingCommentsService service;
  late int added;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = _FailingCommentsService();
    added = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [commentsServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CreateComment(
              id: 'm1',
              focusNode: FocusNode(),
              onCommentAdded: () => added++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a failed comment keeps its text and does not bump the count',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'hello there');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(find.text('hello there'), findsOneWidget);
    expect(added, 0);

    // And the box is not dead: a second send goes out.
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
  });

  testWidgets('the comment box stops at 500 characters', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'a' * 600);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, kCommentMaxLength);
  });
}
