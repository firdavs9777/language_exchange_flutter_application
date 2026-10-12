import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/launch_modal_coordinator.dart';

class _Fake implements LaunchCandidate {
  _Fake(
    this.id,
    this.log, {
    this.due = true,
    this.allowedForNewUsers = false,
    this.throwInIsDue = false,
    this.throwInShow = false,
    this.onIsDue,
  });
  @override
  final String id;
  @override
  final bool allowedForNewUsers;
  final bool due;
  final bool throwInIsDue;
  final bool throwInShow;
  final Future<void> Function()? onIsDue;
  final List<String> log;
  @override
  Future<bool> isDue() async {
    await onIsDue?.call();
    if (throwInIsDue) throw StateError('isDue boom');
    return due;
  }

  @override
  Future<void> show(BuildContext context) async {
    if (throwInShow) throw StateError('show boom');
    log.add(id);
  }
}

Future<BuildContext> _context(WidgetTester t) async {
  late BuildContext ctx;
  await t.pumpWidget(
    Builder(
      builder: (c) {
        ctx = c;
        return const SizedBox();
      },
    ),
  );
  return ctx;
}

void main() {
  setUp(PopupBudget.debugReset);

  testWidgets('shows only the first due candidate, in order', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log, due: false),
      _Fake('ads_notice', log, allowedForNewUsers: true),
      _Fake('feature_spotlight', log),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(log, ['ads_notice']);
    expect(PopupBudget.tryConsume(), isFalse, reason: 'budget spent');
  });

  testWidgets('guide period: only new-user-safe candidates', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log),
      _Fake('ads_notice', log, allowedForNewUsers: true),
    ]).run(await _context(t), guidePeriod: true, updateShown: false);
    expect(log, ['ads_notice']);
  });

  testWidgets('an update dialog was this launch\'s pop-up', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log),
    ]).run(await _context(t), guidePeriod: false, updateShown: true);
    expect(log, isEmpty);
  });

  testWidgets('priming already took the budget: nothing, not even isDue', (
    t,
  ) async {
    expect(PopupBudget.tryConsume(), isTrue);
    final log = <String>[];
    var asked = false;
    await LaunchModalCoordinator([
      _Fake(
        'announcement',
        log,
        onIsDue: () async {
          asked = true;
        },
      ),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(log, isEmpty);
    expect(asked, isFalse);
  });

  testWidgets('nothing due leaves the budget for priming', (t) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log, due: false),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(PopupBudget.tryConsume(), isTrue);
  });

  testWidgets('isDue that throws is skipped; next candidate still shows', (
    t,
  ) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log, throwInIsDue: true),
      _Fake('ads_notice', log),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(log, ['ads_notice']);
  });

  testWidgets('show that throws does not crash, refunds the budget, moves on', (
    t,
  ) async {
    final log = <String>[];
    await LaunchModalCoordinator([
      _Fake('announcement', log, throwInShow: true),
      _Fake('ads_notice', log),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(log, ['ads_notice']);

    PopupBudget.debugReset();
    await LaunchModalCoordinator([
      _Fake('announcement', log, throwInShow: true),
    ]).run(await _context(t), guidePeriod: false, updateShown: false);
    expect(PopupBudget.tryConsume(), isTrue, reason: 'failed show not spent');
  });

  testWidgets('stops when the context unmounts between candidates', (t) async {
    final log = <String>[];
    final ctx = await _context(t);
    await LaunchModalCoordinator([
      _Fake(
        'announcement',
        log,
        onIsDue: () async {
          await t.pumpWidget(const SizedBox());
        },
      ),
      _Fake('ads_notice', log),
    ]).run(ctx, guidePeriod: false, updateShown: false);
    expect(log, isEmpty);
    expect(PopupBudget.spent, isFalse);
  });

  test('tryConsume is a synchronous check-and-set', () {
    expect(PopupBudget.tryConsume(), isTrue);
    expect(PopupBudget.tryConsume(), isFalse);
  });
}
