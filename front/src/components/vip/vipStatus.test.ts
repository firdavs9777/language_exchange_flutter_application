import { isVipUser } from './vipStatus';

it('trusts the server tier over the cached user', () => {
  expect(isVipUser({ userMode: 'vip' }, { data: { tier: 'regular' } })).toBe(false);
  expect(isVipUser({ userMode: 'regular' }, { data: { tier: 'vip' } })).toBe(true);
});

it('falls back to the cached user until the status query answers', () => {
  expect(isVipUser({ userMode: 'vip' })).toBe(true);
  expect(isVipUser({ vipSubscription: { isActive: true } })).toBe(true);
  expect(isVipUser({ userMode: 'regular' })).toBe(false);
  expect(isVipUser(undefined)).toBe(false);
});
