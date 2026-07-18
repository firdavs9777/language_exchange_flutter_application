import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/room.dart';

/// Unit tests for `Room.fromJson`/`copyWith`, covering the fields added for
/// user-created topic rooms + moderation (Workstream D, client layer A):
/// `roomType`, `isSeeded`, `isBanned`, `hasPendingRequest`,
/// `pendingRequestCount`, `ownerId`, and the `isTopicRoom` getter.
void main() {
  group('Room.fromJson — new topic-room + moderation fields', () {
    test('parses a full topic-room payload', () {
      final room = Room.fromJson({
        '_id': 'room1',
        'roomType': 'topic',
        'title': 'Travel Spanish',
        'description': 'Talk about travel',
        'emojiFlag': '🧳',
        'targetLanguage': 'es',
        'owner': 'user1',
        'memberCount': 5,
        'onlineCount': 2,
        'isMember': true,
        'isOwnerOrAdmin': true,
        'isSeeded': false,
        'isBanned': false,
        'hasPendingRequest': false,
        'pendingRequestCount': 3,
      });

      expect(room.roomType, 'topic');
      expect(room.isTopicRoom, isTrue);
      expect(room.ownerId, 'user1');
      expect(room.isSeeded, isFalse);
      expect(room.isBanned, isFalse);
      expect(room.hasPendingRequest, isFalse);
      expect(room.pendingRequestCount, 3);
    });

    test('parses a populated owner object (id under _id)', () {
      final room = Room.fromJson({
        '_id': 'room1',
        'owner': {'_id': 'user1', 'name': 'Jane'},
      });
      expect(room.ownerId, 'user1');
    });

    test('parses a populated owner object (id under id)', () {
      final room = Room.fromJson({
        '_id': 'room1',
        'owner': {'id': 'user2', 'name': 'Jane'},
      });
      expect(room.ownerId, 'user2');
    });

    test('defaults are tolerant of old payloads lacking the new fields', () {
      final room = Room.fromJson({
        '_id': 'room1',
        'title': 'General Chat',
        'emojiFlag': '🇪🇸',
        'targetLanguage': 'es',
        'memberCount': 10,
        'onlineCount': 1,
        'isMember': true,
      });

      expect(room.roomType, 'hub');
      expect(room.isTopicRoom, isFalse);
      expect(room.ownerId, isNull);
      expect(room.isSeeded, isFalse);
      expect(room.isBanned, isFalse);
      expect(room.hasPendingRequest, isFalse);
      expect(room.pendingRequestCount, 0);
    });

    test('a hub with roomType explicitly set is not a topic room', () {
      final room = Room.fromJson({'_id': 'room1', 'roomType': 'hub'});
      expect(room.isTopicRoom, isFalse);
    });
  });

  group('Room.copyWith — new fields', () {
    test('overrides new fields independently while preserving the rest', () {
      const original = Room(
        id: 'room1',
        title: 'Title',
        emojiFlag: '🇰🇷',
        targetLanguage: 'ko',
        memberCount: 1,
        onlineCount: 0,
        description: '',
        isMember: false,
      );

      final updated = original.copyWith(
        roomType: 'topic',
        isSeeded: true,
        isBanned: true,
        hasPendingRequest: true,
        pendingRequestCount: 7,
        ownerId: 'ownerX',
      );

      expect(updated.roomType, 'topic');
      expect(updated.isTopicRoom, isTrue);
      expect(updated.isSeeded, isTrue);
      expect(updated.isBanned, isTrue);
      expect(updated.hasPendingRequest, isTrue);
      expect(updated.pendingRequestCount, 7);
      expect(updated.ownerId, 'ownerX');
      // Unrelated fields untouched.
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.targetLanguage, original.targetLanguage);
    });

    test('omitting new fields keeps their previous values', () {
      const original = Room(
        id: 'room1',
        title: 'Title',
        emojiFlag: '🇰🇷',
        targetLanguage: 'ko',
        memberCount: 1,
        onlineCount: 0,
        description: '',
        isMember: false,
        roomType: 'topic',
        isSeeded: true,
        isBanned: true,
        hasPendingRequest: true,
        pendingRequestCount: 2,
        ownerId: 'ownerX',
      );

      final updated = original.copyWith(title: 'New Title');

      expect(updated.title, 'New Title');
      expect(updated.roomType, 'topic');
      expect(updated.isSeeded, isTrue);
      expect(updated.isBanned, isTrue);
      expect(updated.hasPendingRequest, isTrue);
      expect(updated.pendingRequestCount, 2);
      expect(updated.ownerId, 'ownerX');
    });
  });
}
