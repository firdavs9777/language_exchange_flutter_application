/// The Practice tab's entry list, as an ordered, testable value.
///
/// Extracted from the widget tree for the same reason `studyHubTabOrder` was
/// (see study_hub_tabs.dart): an order buried in a list literal inside a build
/// method cannot be asserted, and the two defects this tab actually had were
/// both invisible from inside the widget tree.
///
/// The tab held **12 entry points** — a tutor hero with 5 chips plus a 7-card
/// grid — and two of them existed twice over:
///
///   tutor "chat" chip     -> TutorChatScreen
///   grid "AI Conversation" -> AIConversationScreen
///   tutor "pronounce" chip -> PronunciationStartScreen
///   grid "Pronunciation"   -> PronunciationScreen
///
/// Underneath sat two independent roleplay backends. That duplication is the
/// direct cause of "packed": the tab was competing with itself.
///
/// Making the list a value means a widget test can assert how many entries
/// there are and that every one of them leads somewhere different — the test
/// that would have caught both duplicates.
enum PracticeEntry {
  /// AI Conversation. Superseded by the tutor, which has memory and SRS;
  /// retained here until Task 2 removes it so the extraction is a pure
  /// refactor with no visual change.
  aiConversation,
  lessons,
  grammar,
  pronunciation,
  translation,
  quizzes,
  lessonBuilder,
}

/// The order entries appear in the Practice grid.
///
/// Today this is the order the tab already had. Task 2 of the Study Hub IA
/// plan reorders it by measured demand and merges the duplicates.
const List<PracticeEntry> practiceEntryOrder = [
  PracticeEntry.aiConversation,
  PracticeEntry.lessons,
  PracticeEntry.grammar,
  PracticeEntry.pronunciation,
  PracticeEntry.translation,
  PracticeEntry.quizzes,
  PracticeEntry.lessonBuilder,
];
