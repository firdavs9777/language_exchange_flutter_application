import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/corrections/correction_sheet.dart';

void main() {
  group('diffWords', () {
    test('identical strings produce all equal spans', () {
      final spans = diffWords('I go to school', 'I go to school');

      expect(spans, everyElement(predicate((DiffSpan s) => s.op == DiffOp.equal)));
      expect(spans.map((s) => s.text).join(' '), 'I go to school');
    });

    test('single word replaced produces removed + added spans', () {
      final spans = diffWords('I go to school', 'I went to school');

      expect(
        spans.where((s) => s.op == DiffOp.removed).map((s) => s.text),
        ['go'],
      );
      expect(
        spans.where((s) => s.op == DiffOp.added).map((s) => s.text),
        ['went'],
      );
      expect(
        spans.where((s) => s.op == DiffOp.equal).map((s) => s.text),
        ['I', 'to', 'school'],
      );
    });

    test('word inserted produces an added span with no removed span', () {
      final spans = diffWords('I go school', 'I go to school');

      expect(spans.where((s) => s.op == DiffOp.removed), isEmpty);
      expect(
        spans.where((s) => s.op == DiffOp.added).map((s) => s.text),
        ['to'],
      );
      expect(
        spans.where((s) => s.op == DiffOp.equal).map((s) => s.text),
        ['I', 'go', 'school'],
      );
    });

    test('word deleted produces a removed span with no added span', () {
      final spans = diffWords('I go to to school', 'I go to school');

      expect(spans.where((s) => s.op == DiffOp.added), isEmpty);
      expect(
        spans.where((s) => s.op == DiffOp.removed).map((s) => s.text),
        ['to'],
      );
      expect(
        spans.where((s) => s.op == DiffOp.equal).map((s) => s.text),
        ['I', 'go', 'to', 'school'],
      );
    });

    test('empty original with non-empty corrected is all added', () {
      final spans = diffWords('', 'hello world');

      expect(spans.where((s) => s.op == DiffOp.equal), isEmpty);
      expect(
        spans.where((s) => s.op == DiffOp.added).map((s) => s.text),
        ['hello', 'world'],
      );
    });

    test('empty corrected with non-empty original is all removed', () {
      final spans = diffWords('hello world', '');

      expect(spans.where((s) => s.op == DiffOp.equal), isEmpty);
      expect(
        spans.where((s) => s.op == DiffOp.removed).map((s) => s.text),
        ['hello', 'world'],
      );
    });
  });
}
