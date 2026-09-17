import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/create/moment_upload_retry.dart';

void main() {
  group('decideRetry', () {
    test('offers a retry while attempts remain', () {
      for (var made = 0; made < kMaxUploadRetries; made++) {
        expect(decideRetry(attemptsMade: made), UploadRetryDecision.offerRetry,
            reason: 'attempt $made should still offer');
      }
    });

    test('GLOBAL CONSTRAINT: gives up at the cap, and stays given up', () {
      // The bug: the old path recursed without any cap, so a user could stack
      // an unbounded number of nested dialog futures by tapping retry.
      expect(decideRetry(attemptsMade: kMaxUploadRetries),
          UploadRetryDecision.giveUp);
      expect(decideRetry(attemptsMade: kMaxUploadRetries + 50),
          UploadRetryDecision.giveUp);
    });
  });

  group('retriesRemaining', () {
    test('counts down', () {
      expect(retriesRemaining(attemptsMade: 0), kMaxUploadRetries);
      expect(retriesRemaining(attemptsMade: 1), kMaxUploadRetries - 1);
    });

    test('never goes negative', () {
      expect(retriesRemaining(attemptsMade: kMaxUploadRetries + 9), 0);
    });
  });

  group('uploadFailureMessage', () {
    test('strips the Exception prefix users should never see', () {
      final msg = uploadFailureMessage(
        attemptsMade: 0,
        reason: 'Exception: connection closed',
      );
      expect(msg, contains('connection closed'));
      expect(msg, isNot(contains('Exception:')));
    });

    test('an empty reason still says something useful', () {
      final msg = uploadFailureMessage(attemptsMade: 0, reason: '   ');
      expect(msg.trim(), isNotEmpty);
      expect(msg, contains('did not complete'));
    });

    test('the message changes as attempts are used up', () {
      // The old code said "Upload failed again" on the tenth try exactly as on
      // the second, which is what makes a retry button feel broken.
      final first = uploadFailureMessage(attemptsMade: 0, reason: 'x');
      final second = uploadFailureMessage(attemptsMade: 1, reason: 'x');
      expect(first, isNot(equals(second)));
    });

    test('singular and plural are both right', () {
      final one = uploadFailureMessage(
          attemptsMade: kMaxUploadRetries - 1, reason: 'x');
      expect(one, contains('1 try left'));
      expect(one, isNot(contains('1 tries')));
    });

    test('the final message stops promising a retry and says what to do', () {
      final last =
          uploadFailureMessage(attemptsMade: kMaxUploadRetries, reason: 'x');
      expect(last, isNot(contains('tries left')));
      expect(last, contains('already posted'),
          reason: 'the moment survived; only the voice note did not');
      expect(last, contains('editing'));
    });
  });
}
