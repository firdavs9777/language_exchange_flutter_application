import 'package:bananatalk_app/pages/community/filter/filter_state.dart';
import 'package:bananatalk_app/pages/community/partners/partner_query.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// One builder for the Partners list AND the filter sheet's live count
/// (audit 2026-10-30: the count skipped the default language match, sent
/// language picks the other way round and ignored the quick chips, so it
/// promised a different list from the one shown).
PartnerFilterParams _params({
  FilterState filters = const FilterState(),
  PartnerSegment segment = PartnerSegment.all,
  PartnerQuickChips chips = const PartnerQuickChips(),
  bool isVip = false,
}) =>
    partnerParamsFor(
      filters: filters.toJson(),
      myNative: 'English',
      myLearning: 'Korean',
      segment: segment,
      chips: chips,
      isVip: isVip,
    );

void main() {
  test('default: exchange match on my own languages', () {
    final q = _params().toQuery();
    expect(q['matchLanguage'], 'true');
    expect(q['nativeLanguage'], 'English');
    expect(q['learningLanguage'], 'Korean');
  });

  test('Women / Men chips set gender and override the sheet', () {
    const sheet = FilterState(gender: 'Male');
    expect(_params(filters: sheet, chips: const PartnerQuickChips(gender: 'female')).gender, 'female');
    expect(_params(chips: const PartnerQuickChips(gender: 'male')).gender, 'male');
    expect(_params(filters: sheet).gender, 'male');
  });

  test('Same city sends sameCity=true', () {
    expect(_params(chips: const PartnerQuickChips(sameCity: true)).toQuery()['sameCity'], 'true');
    expect(_params().toQuery().containsKey('sameCity'), isFalse);
  });

  test('New members: the sheet toggle and the segment both mean joinedWithin=7d', () {
    expect(_params(filters: const FilterState(newUsersOnly: true)).joinedWithin, '7d');
    expect(_params(segment: PartnerSegment.newMembers).joinedWithin, '7d');
  });

  test('Topic chip filters to that topic', () {
    expect(_params(chips: const PartnerQuickChips(topicId: 'music')).topics, ['music']);
  });

  test('the count query equals the list query minus paging and sort', () {
    final p = _params(
      filters: const FilterState(gender: 'Female', minAge: 25),
      chips: const PartnerQuickChips(sameCity: true, online: true),
    );
    final list = p.toQuery(page: 2, limit: 20, sort: 'smart');
    final count = p.toQuery();
    expect({...list}..removeWhere((k, _) => {'page', 'limit', 'sort'}.contains(k)), count);
  });

  test('a topic chip alone counts as an active filter', () {
    expect(
      hasActivePartnerFilters(const FilterState().toJson(), PartnerSegment.all,
          const PartnerQuickChips(topicId: 'music')),
      isTrue,
    );
    expect(
      hasActivePartnerFilters(const FilterState().toJson(), PartnerSegment.all,
          const PartnerQuickChips()),
      isFalse,
    );
    expect(
      hasActivePartnerFilters(const FilterState(newUsersOnly: true).toJson(),
          PartnerSegment.all, const PartnerQuickChips()),
      isTrue,
    );
  });
}
