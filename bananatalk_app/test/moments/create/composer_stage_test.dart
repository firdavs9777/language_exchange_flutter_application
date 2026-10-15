import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/create/composer_stage.dart';

void main() {
  group('navigation', () {
    test('compose is first, details is last', () {
      expect(ComposerStage.compose.isFirst, isTrue);
      expect(ComposerStage.details.isLast, isTrue);
    });

    test('next and previous stop at the ends rather than wrapping', () {
      expect(ComposerStage.compose.next, ComposerStage.details);
      expect(ComposerStage.details.next, ComposerStage.details);
      expect(ComposerStage.details.previous, ComposerStage.compose);
      expect(ComposerStage.compose.previous, ComposerStage.compose);
    });

    test('index matches declaration order', () {
      expect(ComposerStage.compose.index, 0);
      expect(ComposerStage.details.index, 1);
    });
  });

  group('canAdvanceFrom', () {
    test('GLOBAL CONSTRAINT: a caption alone is enough', () {
      // This app allows text-only moments with gradient backgrounds. Requiring
      // media would refuse half the posts it exists for.
      expect(
        canAdvanceFrom(
            stage: ComposerStage.compose, hasCaption: true, hasMedia: false),
        isTrue,
      );
    });

    test('GLOBAL CONSTRAINT: media alone is enough', () {
      expect(
        canAdvanceFrom(
            stage: ComposerStage.compose, hasCaption: false, hasMedia: true),
        isTrue,
      );
    });

    test('an empty compose step cannot advance', () {
      expect(
        canAdvanceFrom(
            stage: ComposerStage.compose, hasCaption: false, hasMedia: false),
        isFalse,
      );
    });

    test('both together is obviously fine', () {
      expect(
        canAdvanceFrom(
            stage: ComposerStage.compose, hasCaption: true, hasMedia: true),
        isTrue,
      );
    });

    test('the details step never blocks', () {
      // Everything on it is optional; the post button does its own validation.
      expect(
        canAdvanceFrom(
            stage: ComposerStage.details, hasCaption: false, hasMedia: false),
        isTrue,
      );
    });
  });

  // #25: system back / iOS swipe on step 2 closed the composer and dropped
  // the draft; closing step 1 with content asked nothing.
  group('composerBackAction', () {
    test('back on the details step returns to compose, draft or not', () {
      expect(
        composerBackAction(
            stage: ComposerStage.details, hasUnsavedContent: true),
        ComposerBackAction.previousStage,
      );
      expect(
        composerBackAction(
            stage: ComposerStage.details, hasUnsavedContent: false),
        ComposerBackAction.previousStage,
      );
    });

    test('leaving compose with content asks first', () {
      expect(
        composerBackAction(
            stage: ComposerStage.compose, hasUnsavedContent: true),
        ComposerBackAction.confirmDiscard,
      );
    });

    test('an empty compose step just closes', () {
      expect(
        composerBackAction(
            stage: ComposerStage.compose, hasUnsavedContent: false),
        ComposerBackAction.leave,
      );
    });
  });
}
