import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/stories/create/studio/overlay_draft.dart';

void main() {
  test('defaults + toJson match backend schema keys', () {
    final d = OverlayDraft(content: 'hello');
    final j = d.toJson();
    expect(j['type'], 'text');
    expect(j['content'], 'hello');
    expect(j['x'], 0.5);
    expect(j['y'], 0.4);
    expect(j['scale'], 1.0);
    expect(j['color'], '#FFFFFF');
    expect(j['fontStyle'], 'sans-serif');
    expect(j['bgMode'], 'none');
  });

  test('clamp enforces x,y in [0,1] and scale in [0.5,3.0]', () {
    final d = OverlayDraft(content: 'x')
      ..x = 1.4
      ..y = -0.2
      ..scale = 9;
    d.clamp();
    expect(d.x, 1.0);
    expect(d.y, 0.0);
    expect(d.scale, 3.0);
    d.scale = 0.1;
    d.clamp();
    expect(d.scale, 0.5);
  });
}
