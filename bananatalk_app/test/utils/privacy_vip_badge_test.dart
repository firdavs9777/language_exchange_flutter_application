import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';

/// showGiftingLevel was saved but PrivacyUtils.shouldShowGiftingLevel was
/// never called: another user's VIP (gifting-level) badge showed regardless.
void main() {
  Community user(Map<String, dynamic> extra) =>
      Community.fromJson({'_id': 'u2', 'name': 'B', ...extra});

  group('PrivacyUtils.showsVipBadge', () {
    test('VIP with no privacy settings: shown', () {
      expect(PrivacyUtils.showsVipBadge(user({'userMode': 'vip'})), isTrue);
    });

    test('VIP who hides the gifting level: hidden', () {
      expect(
        PrivacyUtils.showsVipBadge(user({
          'userMode': 'vip',
          'privacySettings': {'showGiftingLevel': false},
        })),
        isFalse,
      );
    });

    test('not VIP: hidden', () {
      expect(PrivacyUtils.showsVipBadge(user({'userMode': 'regular'})),
          isFalse);
    });
  });

  group('PrivacyUtils.showsVipBadgeFromJson', () {
    test('active subscription counts as VIP', () {
      expect(
        PrivacyUtils.showsVipBadgeFromJson({
          'vipSubscription': {'isActive': true},
        }),
        isTrue,
      );
    });

    test('showGiftingLevel false hides it', () {
      expect(
        PrivacyUtils.showsVipBadgeFromJson({
          'userMode': 'vip',
          'privacySettings': {'showGiftingLevel': false},
        }),
        isFalse,
      );
    });

    test('null payload: hidden', () {
      expect(PrivacyUtils.showsVipBadgeFromJson(null), isFalse);
    });
  });

  test('chat partner from the server honours showGiftingLevel', () {
    final partner = ChatPartnerData.fromJson({
      '_id': 'u2',
      'name': 'B',
      'userMode': 'vip',
      'privacySettings': {'showGiftingLevel': false},
    });
    expect(partner.isVip, isFalse);
  });
}
