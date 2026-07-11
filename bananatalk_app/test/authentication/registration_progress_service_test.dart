import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/authentication/register/registration_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save then load round-trips step and fields', () async {
    final svc = RegistrationProgressService();
    await svc.save(RegistrationProgress(step: 2, fields: {'email': 'a@b.com', 'name': 'Kim'}));
    final loaded = await svc.load();
    expect(loaded!.step, 2);
    expect(loaded.fields['email'], 'a@b.com');
  });

  test('load returns null when nothing saved', () async {
    expect(await RegistrationProgressService().load(), isNull);
  });

  test('clear removes progress', () async {
    final svc = RegistrationProgressService();
    await svc.save(RegistrationProgress(step: 1, fields: {}));
    await svc.clear();
    expect(await svc.load(), isNull);
  });

  test('stale progress (>7 days) is discarded', () async {
    final svc = RegistrationProgressService();
    await svc.save(RegistrationProgress(
        step: 1, fields: {}, savedAt: DateTime.now().subtract(const Duration(days: 8))));
    expect(await svc.load(), isNull);
  });
}
