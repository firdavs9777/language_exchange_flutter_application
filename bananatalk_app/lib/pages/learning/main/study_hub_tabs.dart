/// Study Hub sub-tab order.
///
/// Extracted from the widget tree so the order is a testable value, and so a
/// future reorder cannot silently break `animateTo` call sites that used to
/// pass magic numbers.
///
/// Today leads because it hosts the daily drop — the one action we want a
/// user to take every day. Exam Study used to lead despite having 74 progress
/// docs against the AI tutor's 309 sessions.
enum StudyHubTab { today, aiTools, examStudy }

const List<StudyHubTab> studyHubTabOrder = [
  StudyHubTab.today,
  StudyHubTab.aiTools,
  StudyHubTab.examStudy,
];

int indexOfTab(StudyHubTab tab) => studyHubTabOrder.indexOf(tab);
