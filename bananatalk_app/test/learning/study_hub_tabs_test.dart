import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_tabs.dart';

void main() {
  test('Today is the landing tab', () {
    expect(studyHubTabOrder.first, StudyHubTab.today);
    expect(indexOfTab(StudyHubTab.today), 0);
  });

  test('AI Tools stays at index 1 so the existing animateTo(1) is still correct', () {
    expect(indexOfTab(StudyHubTab.aiTools), 1);
  });

  test('Exam Study moves off the front door', () {
    expect(indexOfTab(StudyHubTab.examStudy), 2);
  });

  test('the order covers every tab exactly once', () {
    expect(studyHubTabOrder.length, StudyHubTab.values.length);
    expect(studyHubTabOrder.toSet().length, studyHubTabOrder.length);
  });
}
