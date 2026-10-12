import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_text_scanner.dart';

void main() {
  test('flags a ternary with English branches', () {
    final hits = scanSource('a.dart',
        "final w = Text(isOut ? 'Daily limit reached' : '\$n left today', style: s);");
    expect(hits, hasLength(1));
    expect(hits.single.text, contains('Daily limit reached'));
  });

  test('flags a ?? fallback', () {
    final hits = scanSource('a.dart', "Text(user.name ?? 'Unknown user')");
    expect(hits, hasLength(1));
  });

  test('flags a plain literal and joined adjacent literals', () {
    expect(scanSource('a.dart', "Text('Hello there')"), hasLength(1));
    expect(scanSource('a.dart', "Text('Hello ' 'there')"), hasLength(1));
  });

  test('no hit for l10n getters, variables or non-text arguments', () {
    expect(scanSource('a.dart', 'Text(l10n.title)'), isEmpty);
    expect(scanSource('a.dart', 'Text(name)'), isEmpty);
    expect(scanSource('a.dart', "Text(name, style: TextStyle(fontFamily: 'Roboto'))"),
        isEmpty);
    expect(scanSource('a.dart', "Text('\${a}\${b}')"), isEmpty);
    expect(scanSource('a.dart', "// Text('Commented out')"), isEmpty);
  });
}
