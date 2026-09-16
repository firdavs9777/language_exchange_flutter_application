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
  /// Lessons. The lesson builder lives INSIDE this, not beside it — 28 lesson
  /// calls and 28 builder calls in 30 days are one workflow, not two.
  lessons,

  /// One pronunciation entry, not two. PronunciationScreen survives:
  /// 1,025 lines with history, stats and a language selector, against
  /// PronunciationStartScreen's 151. The start screen's only advantage was
  /// offering "use my own sentence" up front, and the surviving screen already
  /// has that field.
  pronunciation,

  quizzes,

  /// Grammar feedback. Kept, and kept LAST: 3 calls from 1 user in 30 days.
  /// Removing a working feature on one month of data is premature; if it is
  /// still at one user in three months it should go.
  writingCheck,
}

/// The order entries appear in the Practice grid, after the tutor hero.
///
/// Ordered by measured 30-day demand, which the old layout was close to
/// inverted against:
///
///   Lessons          28 + 28 builder
///   Pronunciation    21 / 7 users
///   Quizzes           4 / 4 users
///   Writing check     3 / 1 user
///
/// Two entries are deliberately absent:
///
/// **AI Conversation** — superseded by the tutor. Both are roleplay chat, on
/// two separate backends, and the tab was competing with itself. The tutor
/// survives on capability rather than usage (the margin was thin): it has
/// memory, a persona, a daily plan and SRS, so practice accumulates instead of
/// evaporating. Its 141 saved conversations stay readable; only the creation
/// entry point is gone.
///
/// **Translation** — moved to chat, where its 74 users already are. It is used
/// 2.6x more than anything else here and sat fifth of seven on the second tab.
/// Nobody opens a study tab to translate; they translate mid-conversation with
/// a person.
const List<PracticeEntry> practiceEntryOrder = [
  PracticeEntry.lessons,
  PracticeEntry.pronunciation,
  PracticeEntry.quizzes,
  PracticeEntry.writingCheck,
];
