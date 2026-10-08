import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/providers/provider_root/profile_visitor_provider.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/session_reset.dart';

/// Every public top-level Riverpod provider declared under lib/.
Set<String> _declaredProviderNames() {
  final names = <String>{};
  final decl = RegExp(
    r'^final\s+([A-Za-z]\w*)\s*=\s*([\s\S]{0,200}?)[(<]',
    multiLine: true,
  );
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    for (final m in decl.allMatches(f.readAsStringSync())) {
      final rhs = m.group(2)!.split('(').first;
      if (RegExp(r'\b\w*Provider\b').hasMatch(rhs)) names.add(m.group(1)!);
    }
  }
  return names;
}

void main() {
  test('every provider in lib/ is classified user- or app-scoped', () {
    // Guards the original bug from coming back: a new user-scoped provider
    // that nobody adds to the reset list survives logout.
    final userNames =
        userScopedProviders.keys.map((k) => k.split(' ').first).toSet();
    final unclassified = _declaredProviderNames()
        .where((n) => !userNames.contains(n))
        .where((n) => !kAppScopedProviderNames.contains(n))
        .toList()
      ..sort();
    expect(unclassified, isEmpty,
        reason: 'Add these to userScopedProviders or kAppScopedProviderNames '
            'in lib/services/session_reset.dart');
  });

  test('no provider is both user- and app-scoped', () {
    final userNames =
        userScopedProviders.keys.map((k) => k.split(' ').first).toSet();
    expect(userNames.intersection(kAppScopedProviderNames), isEmpty);
  });

  test('the reset invalidates the providers that leaked across accounts', () {
    final invalidated = <ProviderOrFamily>[];
    invalidateUserScopedProviders(invalidated.add);

    for (final p in <ProviderOrFamily>[
      authServiceProvider,
      userProvider,
      coinBalanceProvider,
      coinUnlockedFeaturesProvider,
      blockedUsersProvider,
      tutorMemoryAndQuotasProvider,
      tutorDailyPlanProvider,
      dailyMatchesProvider,
      myVisitorStatsProvider,
      notificationSettingsProvider,
      wavesUnreadProvider,
    ]) {
      expect(invalidated.any((i) => identical(i, p)), isTrue, reason: '$p');
    }
  });
}
