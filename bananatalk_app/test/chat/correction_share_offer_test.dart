import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/share_offer_policy.dart';
import 'package:bananatalk_app/widgets/correction_message_bubble.dart';
import 'package:bananatalk_app/widgets/share_as_moment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/community_fixture.dart';

Message _original(String senderId) => Message(
  id: 'orig',
  sender: buildCommunity(id: senderId),
  receiver: buildCommunity(id: 'x'),
  message: 'i goed home',
  createdAt: DateTime.now().toIso8601String(),
  version: 0,
  read: true,
);

Message _correctionMsg(String correctorId) => Message(
  id: 'correction_c1',
  sender: buildCommunity(id: correctorId),
  receiver: buildCommunity(id: 'x'),
  message: '',
  createdAt: DateTime.now().toIso8601String(),
  version: 0,
  read: true,
  type: 'correction',
  corrections: [
    MessageCorrection(
      id: 'c1',
      corrector: buildCommunity(id: correctorId),
      originalText: 'i goed home',
      correctedText: 'I went home',
      createdAt: DateTime.now().toIso8601String(),
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('mayOfferCorrectionShare', () {
    bool run({
      bool isGroup = false,
      String? me = 'me',
      Message? original,
      String corrector = 'partner',
    }) => mayOfferCorrectionShare(
      isGroup: isGroup,
      currentUserId: me,
      originalMessage: original,
      correctorId: corrector,
    );

    test('my message, partner corrected, 1:1: yes', () {
      expect(run(original: _original('me')), isTrue);
    });
    test('a correction I authored: no', () {
      expect(run(original: _original('me'), corrector: 'me'), isFalse);
    });
    test("a correction of the partner's message: no", () {
      expect(run(original: _original('partner')), isFalse);
    });
    test('null or empty current user: no', () {
      expect(run(me: null, original: _original('me')), isFalse);
      expect(run(me: '', original: _original('')), isFalse);
    });
    test('group chat: no', () {
      expect(run(isGroup: true, original: _original('me')), isFalse);
    });
    test('original not resolved: no', () {
      expect(run(original: null), isFalse);
    });
  });

  var userReads = 0;
  setUp(() => userReads = 0);

  Future<void> pump(
    WidgetTester t, {
    required bool offerShare,
    bool flag = true,
    ShareOfferPolicy? policy,
  }) async {
    // A fresh ProviderScope per pump (overrides cannot change in place).
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWith(
            (ref) async => AppConfig(
              minVersion: '1',
              latestVersion: '1',
              forceUpdate: false,
              iosUrl: '',
              androidUrl: '',
              releaseNotes: '',
              shareOffersEnabled: flag,
            ),
          ),
          userProvider.overrideWith((ref) {
            userReads++;
            return Future<Community>.value(buildCommunity(id: 'me'));
          }),
          if (policy != null) shareOfferPolicyProvider.overrideWithValue(policy),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CorrectionMessageBubble(
                message: _correctionMsg('partner'),
                isMe: false,
                otherUserName: 'Partner',
                originalMessageId: 'orig',
                isCorrector: false,
                offerShare: offerShare,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('offerShare true: card with exactly my corrected sentence', (
    t,
  ) async {
    await pump(t, offerShare: true);
    final card = t.widget<ShareAsMomentCard>(find.byType(ShareAsMomentCard));
    expect(card.prefillText, 'I went home');
    expect(card.slot, 'correction:correction_c1');
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('offerShare false: no card is built', (t) async {
    await pump(t, offerShare: false);
    expect(find.byType(ShareAsMomentCard), findsNothing);
  });

  double bubbleHeight(WidgetTester t) =>
      t.getSize(find.byType(CorrectionMessageBubble)).height;

  testWidgets('flag off: no card, no extra space, no user read', (t) async {
    await pump(t, offerShare: false);
    final baseline = bubbleHeight(t);
    await pump(t, offerShare: true, flag: false);
    expect(find.byType(ShareAsMomentCard), findsNothing);
    expect(bubbleHeight(t), baseline);
    expect(userReads, 0);
  });

  testWidgets('flag on but no offer today: no extra space', (t) async {
    await pump(t, offerShare: false);
    final baseline = bubbleHeight(t);
    await pump(t, offerShare: true, policy: _FixedPolicy(false));
    expect(bubbleHeight(t), baseline);
  });

  testWidgets('flag on and shown: the spacing is part of the card', (t) async {
    await pump(t, offerShare: false);
    final baseline = bubbleHeight(t);
    await pump(t, offerShare: true, policy: _FixedPolicy(true));
    final card = find.byType(ShareAsMomentCard);
    expect(t.getSize(card).height, greaterThan(10));
    expect(bubbleHeight(t), baseline + t.getSize(card).height);
  });
}

class _FixedPolicy extends ShareOfferPolicy {
  _FixedPolicy(this.allowed);
  final bool allowed;
  @override
  Future<bool> tryClaim(DateTime now, {required String slot}) async => allowed;
}
