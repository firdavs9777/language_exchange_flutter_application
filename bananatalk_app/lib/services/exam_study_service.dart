import 'dart:convert';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_section.dart';
import 'package:bananatalk_app/providers/provider_models/exam/evaluation_status.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_submission_result.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_type.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_question.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_exam_progress.dart';
import 'package:bananatalk_app/providers/provider_models/exam/user_study_plan.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client for the backend `/exam-study/*` endpoints.
///
/// Only the read endpoints are wired in Chunk A — submit/poll/progress/
/// study-plan land in later chunks. Authentication header pattern mirrors
/// [MessageService] so the same token plumbing applies.
class ExamStudyService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// List of supported study languages (English / Spanish / Korean in MVP).
  Future<List<ExamLanguage>> getLanguages() async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('${Endpoints.baseURL}${Endpoints.examStudyLanguagesURL}'),
      headers: _headers(token),
    );
    return _decodeList(resp, ExamLanguage.fromJson);
  }

  /// Exams available for a language (e.g. IELTS / TOEFL for English).
  Future<List<ExamType>> getExamsForLanguage(String languageId) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse(
        '${Endpoints.baseURL}${Endpoints.examStudyExamsForLanguageURL(languageId)}',
      ),
      headers: _headers(token),
    );
    return _decodeList(resp, ExamType.fromJson);
  }

  /// Sections within an exam (Reading / Writing).
  Future<List<ExamSection>> getSectionsForExam(String examId) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse(
        '${Endpoints.baseURL}${Endpoints.examStudySectionsForExamURL(examId)}',
      ),
      headers: _headers(token),
    );
    return _decodeList(resp, ExamSection.fromJson);
  }

  /// Practice questions for a section. Optional filters mirror the
  /// backend `?limit=&difficulty=&source=` query params.
  Future<List<ExamQuestion>> getQuestionsForSection(
    String sectionId, {
    int limit = 10,
    int skip = 0,
    String? difficulty, // "easy" | "medium" | "hard"
    String? source, // "builtin" | "ai-generated"
  }) async {
    final token = await _getToken();
    final qp = <String, String>{
      'limit': '$limit',
      'skip': '$skip',
      if (difficulty != null) 'difficulty': difficulty,
      if (source != null) 'source': source,
    };
    final uri = Uri.parse(
      '${Endpoints.baseURL}${Endpoints.examStudyQuestionsForSectionURL(sectionId)}',
    ).replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _headers(token));
    return _decodeList(resp, ExamQuestion.fromJson);
  }

  /// Submit an answer to a question.
  ///
  /// MC returns an [InstantResult] (200). Essay/speaking returns an
  /// [AsyncResult] with the poll URL (202). Chunk D will wire the
  /// polling endpoint; for now an [AsyncResult] just surfaces the id
  /// so the UI can show "Evaluating…" + retry later.
  Future<ExamSubmissionResult> submitAnswer({
    required String questionId,
    required String userAnswer,
    int? timeSpent,
  }) async {
    final token = await _getToken();
    final resp = await http.post(
      Uri.parse(
        '${Endpoints.baseURL}${Endpoints.examStudySubmitAnswerURL(questionId)}',
      ),
      headers: _headers(token),
      body: json.encode({
        'userAnswer': userAnswer,
        if (timeSpent != null) 'timeSpent': timeSpent,
      }),
    );

    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    // Backend uses 501 to signal the essay/speaking path isn't wired
    // yet (Chunk D). Surface a recognizable error so the UI can show
    // a friendly "coming soon" instead of a generic failure.
    if (resp.statusCode == 501) {
      throw ExamFeatureUnavailableException(
        _decodeMessage(resp) ?? 'This question type is not yet supported.',
      );
    }
    if (resp.statusCode == 202) {
      return AsyncResult.fromJson(_decodeMap(resp));
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return InstantResult.fromJson(_decodeMap(resp));
    }
    throw Exception(
      'submit-answer failed (${resp.statusCode}): ${resp.body}',
    );
  }

  /// Poll an in-flight essay/speaking evaluation. The caller is
  /// expected to retry on a timer until [EvaluationStatus.isPending]
  /// returns false.
  Future<EvaluationStatus> pollEvaluation(String evaluationId) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse(
        '${Endpoints.baseURL}${Endpoints.examStudyEvaluationURL(evaluationId)}',
      ),
      headers: _headers(token),
    );
    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (resp.statusCode == 404) {
      throw Exception('Evaluation not found.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'poll evaluation failed (${resp.statusCode}): ${resp.body}',
      );
    }
    return EvaluationStatus.fromJson(_decodeMap(resp));
  }

  /// Fetch the user's progress for a specific exam. Returns null on 404
  /// (no progress yet) — the screen treats that as "not started".
  Future<UserExamProgress?> getUserProgress({
    required String userId,
    required String examId,
  }) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse(
        '${Endpoints.baseURL}${Endpoints.examStudyProgressURL(userId, examId)}',
      ),
      headers: _headers(token),
    );
    if (resp.statusCode == 404) return null;
    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'progress fetch failed (${resp.statusCode}): ${resp.body}',
      );
    }
    return UserExamProgress.fromJson(_decodeMap(resp));
  }

  /// Trigger backend AI generation of a study plan. Returns the saved
  /// plan doc. Replaces any existing active plan for this exam.
  Future<UserStudyPlan> generateStudyPlan({
    required String userId,
    required String examId,
    required num targetScore,
    required DateTime examDate,
  }) async {
    final token = await _getToken();
    final resp = await http.post(
      Uri.parse(
        '${Endpoints.baseURL}${Endpoints.examStudyGenerateStudyPlanURL(userId, examId)}',
      ),
      headers: _headers(token),
      body: json.encode({
        'targetScore': targetScore,
        'examDate': examDate.toIso8601String(),
      }),
    );
    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'generate-study-plan failed (${resp.statusCode}): ${resp.body}',
      );
    }
    return UserStudyPlan.fromJson(_decodeMap(resp));
  }

  /// Fetch the active study plan for an exam. Returns null on 404
  /// (no plan yet — UI shows the setup screen instead).
  Future<UserStudyPlan?> getActiveStudyPlan({
    required String userId,
    required String examId,
  }) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse(
        '${Endpoints.baseURL}exam-study/users/$userId/exams/$examId/study-plan',
      ),
      headers: _headers(token),
    );
    if (resp.statusCode == 404) return null;
    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'study-plan fetch failed (${resp.statusCode}): ${resp.body}',
      );
    }
    return UserStudyPlan.fromJson(_decodeMap(resp));
  }

  Map<String, dynamic> _decodeMap(http.Response resp) {
    final body = json.decode(resp.body);
    if (body is Map<String, dynamic>) {
      // Common envelope: {success, data: {...}}. Unwrap when present.
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return const {};
  }

  String? _decodeMessage(http.Response resp) {
    try {
      final body = json.decode(resp.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    } catch (_) {}
    return null;
  }

  /// Helper: turn a JSON response into a typed list. Throws on non-2xx
  /// so the caller can surface the error via AsyncValue.error.
  List<T> _decodeList<T>(
    http.Response resp,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (resp.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Exam-study request failed (${resp.statusCode}): ${resp.body}',
      );
    }
    final body = json.decode(resp.body);
    // Backend may return either a bare array or `{ data: [...] }`. Handle both.
    final list = body is List
        ? body
        : (body is Map<String, dynamic> ? (body['data'] as List? ?? const []) : const []);
    return list
        .whereType<Map>()
        .map((m) => fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

/// Thrown when the backend reports a feature (e.g. essay evaluation) is
/// not yet implemented. UI can catch this and show a "coming soon"
/// message instead of a generic error toast.
class ExamFeatureUnavailableException implements Exception {
  ExamFeatureUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}
