import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_text_scanner.dart';

/// Guard: no NEW English `Text('...')` / `SelectableText('...')` literal in lib/.
///
/// Three layers decide whether a scanner hit is acceptable:
///  1. [_allowedPaths] / [_allowedTexts] / [_brandTokens]: English by design.
///  2. `no_hardcoded_text_allowlist.txt`: a frozen snapshot of the literals that
///     already existed when this guard landed (2026-10-12). Each line is a JSON
///     `[path, text]` pair, matched by path + text (never line number, so edits
///     above a literal do not break it). The same pair may appear several times:
///     each line allows one occurrence.
///  3. Anything else fails the test.
///
/// The snapshot may only shrink: an entry that no longer matches a hit (the
/// literal was localized, edited or its file deleted) FAILS the test until the
/// line is deleted. So fixing a literal forces the list down and it can never
/// quietly grow back.
///
/// To add a screen's literals legitimately, localize them instead. If a literal
/// truly must stay English, add it to [_allowedTexts] with a reason.

/// Paths (a file, or a directory ending in '/') that may keep English Text literals.
const _allowedPaths = <String, String>{
  'lib/pages/admin/': 'staff-only admin console, English by design',
  'lib/pages/reports/admin_reports_screen.dart': 'staff-only admin console',
  'lib/screens/livekit_test_screen.dart': 'debug-only test screen',
};

/// Exact literals allowed in one file. Empty: the VIP payment debug block is
/// now `kDebugMode`-only and built outside a `Text('...')` literal.
const _allowedTexts = <String, Set<String>>{};

/// Words that are the same in every locale: brands and units.
const _brandTokens = {'VIP', 'XP', 'HD', 'MB', 'km', 'GIPHY', 'Bananatalk', 'BananaTalk', 'firdavsDev'};

const _allowlistFile = 'test/l10n/no_hardcoded_text_allowlist.txt';

final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
final _word = RegExp(r'[A-Za-z]+');

bool _isAllowedByDesign(HardcodedText h) {
  if (_allowedPaths.keys.any((p) => p.endsWith('/') ? h.path.startsWith(p) : h.path == p)) {
    return true;
  }
  if (_allowedTexts[h.path]?.contains(h.text) ?? false) return true;
  final words = _word.allMatches(h.text.replaceAll(_interpolation, '')).map((m) => m.group(0)!);
  return words.every(_brandTokens.contains);
}

String _key(String path, String text) => jsonEncode([path, text]);

List<HardcodedText> _scanLib() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.dart') && !p.startsWith('lib/l10n/') && !p.endsWith('.g.dart'))
      .toList()
    ..sort();
  return scanFiles(files);
}

void main() {
  test('the scanner finds what it must and skips what it must', () {
    expect(scanSource('x.dart', "Text('Hello there')"), hasLength(1));
    expect(scanSource('x.dart', "Text(\n  'Multi ' 'line')").single.text, 'Multi line');
    expect(scanSource('x.dart', "Text('\${a ? 'yes' : 'no'} items')"), hasLength(1));
    expect(scanSource('x.dart', 'Text(l10n.hello)'), isEmpty);
    expect(scanSource('x.dart', "// Text('Hello')"), isEmpty);
    expect(scanSource('x.dart', "Text('\${n}')"), isEmpty);
    expect(scanSource('x.dart', "RichText(text: x)"), isEmpty);
  });

  test('every by-design path still exists', () {
    for (final p in [..._allowedPaths.keys, ..._allowedTexts.keys]) {
      final exists = p.endsWith('/') ? Directory(p).existsSync() : File(p).existsSync();
      expect(exists, isTrue, reason: '$p is allowlisted but gone: remove it from the list');
    }
  });

  test('no NEW English Text literal in lib/, and the snapshot allowlist only shrinks', () {
    // Remaining allowances, as a multiset of path+text keys.
    final remaining = <String, int>{};
    for (final line in File(_allowlistFile).readAsLinesSync().where((l) => l.trim().isNotEmpty)) {
      final pair = (jsonDecode(line) as List).cast<String>();
      remaining.update(_key(pair[0], pair[1]), (n) => n + 1, ifAbsent: () => 1);
    }

    final offenders = <HardcodedText>[];
    for (final h in _scanLib().where((h) => !_isAllowedByDesign(h))) {
      final k = _key(h.path, h.text);
      final left = remaining[k] ?? 0;
      if (left > 0) {
        remaining[k] = left - 1;
      } else {
        offenders.add(h);
      }
    }
    final stale = [
      for (final e in remaining.entries)
        for (var i = 0; i < e.value; i++) e.key,
    ];

    expect(offenders, isEmpty,
        reason: 'Hardcoded English reaches users of every language. Add a key to '
            'lib/l10n/app_en.arb + the 18 other app_*.arb files and use AppLocalizations:\n'
            '${offenders.join('\n')}');
    expect(stale, isEmpty,
        reason: 'These literals were localized or removed. Delete their lines from '
            '$_allowlistFile so the allowlist keeps shrinking:\n${stale.join('\n')}');
  });
}
