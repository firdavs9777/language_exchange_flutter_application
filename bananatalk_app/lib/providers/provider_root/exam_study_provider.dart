import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_topic.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_exam_progress.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_study_plan.dart';
import 'package:bananatalk_app/services/exam_study_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton service. Stateless beyond the auth header so a single instance
/// is fine for the whole app.
final examStudyServiceProvider = Provider<ExamStudyService>(
  (ref) => ExamStudyService(),
);

/// All active study languages. Refetched only on invalidate — the list is
/// small and changes rarely.
final examLanguagesProvider = FutureProvider<List<ExamLanguage>>((ref) {
  return ref.watch(examStudyServiceProvider).getLanguages();
});

/// Exams available for a given language.
final examsForLanguageProvider =
    FutureProvider.family<List<ExamType>, String>((ref, languageId) {
  return ref.watch(examStudyServiceProvider).getExamsForLanguage(languageId);
});

/// Sections within an exam.
final sectionsForExamProvider =
    FutureProvider.family<List<ExamSection>, String>((ref, examId) {
  return ref.watch(examStudyServiceProvider).getSectionsForExam(examId);
});

/// Question-list query parameters. Carried as a value object so the family
/// key has stable equality (lists/maps don't compare structurally).
class QuestionsQuery {
  const QuestionsQuery({
    required this.sectionId,
    this.limit = 10,
    this.skip = 0,
    this.difficulty,
    this.source,
    this.topic,
  });

  final String sectionId;
  final int limit;
  final int skip;
  final String? difficulty;
  final String? source;
  /// Filters the question pool to a specific topic. Null = all topics
  /// (matches the "All topics" tile on the picker).
  final String? topic;

  @override
  bool operator ==(Object other) =>
      other is QuestionsQuery &&
      other.sectionId == sectionId &&
      other.limit == limit &&
      other.skip == skip &&
      other.difficulty == difficulty &&
      other.source == source &&
      other.topic == topic;

  @override
  int get hashCode =>
      Object.hash(sectionId, limit, skip, difficulty, source, topic);
}

/// Practice questions for a section (paginated + filtered).
final questionsForSectionProvider =
    FutureProvider.family<List<ExamQuestion>, QuestionsQuery>((ref, q) {
  return ref.watch(examStudyServiceProvider).getQuestionsForSection(
        q.sectionId,
        limit: q.limit,
        skip: q.skip,
        difficulty: q.difficulty,
        source: q.source,
        topic: q.topic,
      );
});

/// Distinct topics in a given section, with question counts. Powers the
/// topic-picker grid.
final topicsForSectionProvider =
    FutureProvider.family<List<ExamTopic>, String>((ref, sectionId) {
  return ref.watch(examStudyServiceProvider).getTopicsForSection(sectionId);
});

/// Compound key for `userExamProgressProvider` so the family has stable
/// equality (records also work but a small value object reads better at
/// the call sites).
class ProgressKey {
  const ProgressKey({required this.userId, required this.examId});
  final String userId;
  final String examId;

  @override
  bool operator ==(Object other) =>
      other is ProgressKey &&
      other.userId == userId &&
      other.examId == examId;

  @override
  int get hashCode => Object.hash(userId, examId);
}

/// User's progress for a given exam. Null = not started yet (backend 404).
/// Invalidate after each MC submission so the dashboard / section tile
/// progress bars refresh.
final userExamProgressProvider =
    FutureProvider.family<UserExamProgress?, ProgressKey>((ref, key) {
  return ref.watch(examStudyServiceProvider).getUserProgress(
        userId: key.userId,
        examId: key.examId,
      );
});

/// Active study plan for a (user, exam). Null = no plan generated yet
/// (the UI routes to the setup screen in that case). Invalidate after
/// a successful generate so the plan screen picks up the new milestones.
final userStudyPlanProvider =
    FutureProvider.family<UserStudyPlan?, ProgressKey>((ref, key) {
  return ref.watch(examStudyServiceProvider).getActiveStudyPlan(
        userId: key.userId,
        examId: key.examId,
      );
});
