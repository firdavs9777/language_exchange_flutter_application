import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/widgets/story/story_poll_widget.dart';
import 'package:bananatalk_app/widgets/story/story_question_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _story([Map<String, dynamic> extra = const {}]) => {
      '_id': 's1',
      'user': 'owner',
      'mediaType': 'image',
      'mediaUrl': 'https://x/y.jpg',
      ...extra,
    };

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('poll vote state', () {
    test('userVoteIndex from the server is used', () {
      final poll = StoryPoll.fromJson({
        'question': 'Q',
        'userVoteIndex': 1,
        'options': [
          {'text': 'a', 'voteCount': 3},
          {'text': 'b', 'voteCount': 2, 'votes': ['me']},
        ],
      });
      expect(poll.userVoteIndex, 1);
      expect(poll.totalVotes, 5);
    });

    test('falls back to the option flagged voted', () {
      final poll = StoryPoll.fromJson({
        'question': 'Q',
        'options': [
          {'text': 'a'},
          {'text': 'b', 'voted': true},
        ],
      });
      expect(poll.userVoteIndex, 1);
    });

    test('older backend: derived from votes[] for the current user', () {
      final poll = StoryPoll.fromJson({
        'question': 'Q',
        'options': [
          {'text': 'a', 'votes': ['x', 'y']},
          {'text': 'b', 'votes': ['me']},
        ],
      });
      expect(poll.userVoteIndex, isNull);
      expect(poll.options[0].voteCount, 2);
      expect(poll.resolvedFor('me').userVoteIndex, 1);
      expect(poll.resolvedFor('nobody').userVoteIndex, isNull);
      expect(poll.resolvedFor(null).userVoteIndex, isNull);
    });

    testWidgets('the widget opens in the voted state', (tester) async {
      final poll = StoryPoll.fromJson({
        'question': 'Q',
        'userVoteIndex': 0,
        'options': [
          {'text': 'a', 'voteCount': 1},
          {'text': 'b', 'voteCount': 0},
        ],
      });
      int? voted;
      await tester.pumpWidget(_host(StoryPollWidget(
        poll: poll,
        onVote: (i) => voted = i,
      )));
      await tester.tap(find.text('b'));
      await tester.pumpAndSettle();
      expect(voted, isNull, reason: 'a second vote must not be offered');
    });
  });

  group('question box answered state', () {
    test('hasAnswered and responseCount are parsed', () {
      final story = Story.fromJson(_story({
        'questionBox': {
          'prompt': 'Ask',
          'hasAnswered': true,
          'responseCount': 7,
          'responses': [],
        },
      }));
      expect(story.questionBox!.hasAnsweredBy(null), isTrue);
      expect(story.questionBox!.totalResponses, 7);
    });

    test('older backend: answered when a response is the viewer\'s', () {
      final story = Story.fromJson(_story({
        'questionBox': {
          'prompt': 'Ask',
          'responses': [
            {'user': 'me', 'text': 'hi'},
          ],
        },
      }));
      expect(story.questionBox!.hasAnsweredBy('me'), isTrue);
      expect(story.questionBox!.hasAnsweredBy('else'), isFalse);
      expect(story.questionBox!.totalResponses, 1);
    });

    testWidgets('an answered box shows "answer sent", not the input',
        (tester) async {
      await tester.pumpWidget(_host(const StoryQuestionBoxWidget(
        questionBox: StoryQuestionBox(prompt: 'Ask'),
        hasAnswered: true,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('own reaction', () {
    test('myReaction is read, userReaction still works', () {
      expect(Story.fromJson(_story({'myReaction': '🔥'})).reactionOf(null),
          '🔥');
      expect(Story.fromJson(_story({'userReaction': '😂'})).reactionOf(null),
          '😂');
      expect(Story.fromJson(_story({'myReaction': null})).reactionOf(null),
          isNull);
    });

    test('older backend: found in reactions[] by user id', () {
      final story = Story.fromJson(_story({
        'reactions': [
          {'user': 'x', 'emoji': '😢'},
          {'user': 'me', 'emoji': '👏'},
        ],
      }));
      expect(story.reactionOf('me'), '👏');
      expect(story.reactionOf('zz'), isNull);
    });
  });
}
