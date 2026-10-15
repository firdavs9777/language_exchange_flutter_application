import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/deep_link_gate.dart';

void main() {
  late String? path;
  late bool signedIn;
  late List<String> pushed;
  late List<String> went;
  late DeepLinkGate gate;

  setUp(() {
    path = '/splash';
    signedIn = false;
    pushed = [];
    went = [];
    gate = DeepLinkGate(
      currentPath: () => path,
      isSignedIn: () => signedIn,
      push: pushed.add,
      go: went.add,
    );
  });

  test('cold start: held through the splash, opened over the shell', () {
    gate.onLink('/moment/m1');
    expect(pushed, isEmpty);
    expect(went, isEmpty, reason: 'the splash must run its gates');

    // Terms/profile gates are pushed over the splash: still held.
    signedIn = true;
    gate.onRouteChanged();
    expect(pushed, isEmpty);

    path = '/home';
    gate.onRouteChanged();
    expect(pushed, ['/moment/m1']);
    expect(gate.pending, isNull);

    // Only once.
    gate.onRouteChanged();
    expect(pushed, ['/moment/m1']);
  });

  test('logged out: held on login, opened after signing in', () {
    gate.onLink('/profile/u1');
    path = '/login';
    gate.onRouteChanged();
    expect(pushed, isEmpty);

    signedIn = true;
    path = '/tabs/2';
    gate.onRouteChanged();
    expect(pushed, ['/profile/u1']);
  });

  test('warm start while signed in: pushed on top at once', () {
    signedIn = true;
    path = '/home';
    gate.onLink('/community/u2');
    expect(pushed, ['/community/u2']);
    expect(gate.pending, isNull);
  });

  test('warm start while signed in on a detail screen: pushed on top', () {
    signedIn = true;
    path = '/chat/u9';
    gate.onLink('/moment/m2');
    expect(pushed, ['/moment/m2']);
  });

  test('warm start on the login screen: held until signed in', () {
    path = '/login';
    gate.onLink('/moment/m3');
    expect(pushed, isEmpty);
    expect(gate.pending, '/moment/m3');
  });

  test('invite links keep their own route (it redirects to the splash)', () {
    gate.onLink('/invite/ABCD');
    expect(went, ['/invite/ABCD']);
    expect(gate.pending, isNull);
  });

  test('a newer link replaces a held one', () {
    gate.onLink('/moment/a');
    gate.onLink('/moment/b');
    signedIn = true;
    path = '/home';
    gate.onRouteChanged();
    expect(pushed, ['/moment/b']);
  });
}
