import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';

void main() {
  test('fallback prices match the store pricing decision', () {
    expect(VipPlan.monthly.price, 3.99);
    expect(VipPlan.yearly.price, 24.99);
    expect(VipPlan.visible.contains(VipPlan.quarterly), isFalse);
    expect(VipPlan.visible, [VipPlan.monthly, VipPlan.yearly]);
  });
}
