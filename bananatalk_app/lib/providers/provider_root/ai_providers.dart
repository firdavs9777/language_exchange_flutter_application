import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/ai_service.dart';
import 'package:bananatalk_app/models/ai/ai_conversation_model.dart';
import 'package:bananatalk_app/models/ai/grammar_feedback_model.dart';
import 'package:bananatalk_app/models/ai/speech_model.dart';
import 'package:bananatalk_app/models/ai/translation_model.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';

// ============================================
// AI CONVERSATION PROVIDERS
// ============================================

/// Active conversation state
class ConversationState {
  final AIConversation? conversation;
  final List<AIMessage> messages;
  final bool isLoading;
  final String? error;

  ConversationState({
    this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationState copyWith({
    AIConversation? conversation,
    List<AIMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ConversationState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier() : super(ConversationState());

  Future<bool> startConversation(StartConversationRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AIService.startConversation(request);
    if (result['success'] == true) {
      final data = result['conversation'];
      AIConversation? conversation;
      if (data is AIConversation) {
        conversation = data;
      } else if (data is Map) {
        conversation = AIConversation.fromJson(Map<String, dynamic>.from(data));
      }
      if (conversation != null) {
        state = state.copyWith(
          conversation: conversation,
          messages: conversation.messages,
          isLoading: false,
        );
        return true;
      }
    }
    state = state.copyWith(
      isLoading: false,
      error: result['message']?.toString() ?? 'Failed to start conversation',
    );
    return false;
  }

  Future<bool> sendMessage(String content, {int? responseTime}) async {
    if (state.conversation == null) return false;

    final userMessage = AIMessage(
      role: 'user',
      content: content,
      responseTime: responseTime,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    final result = await AIService.sendMessage(
      state.conversation!.id,
      SendMessageRequest(content: content, responseTime: responseTime),
    );


    if (result['success'] == true) {
      // Get AI response message
      final msgData = result['message'];
      AIMessage? aiMessage;
      if (msgData is AIMessage) {
        aiMessage = msgData;
      } else if (msgData is Map) {
        aiMessage = AIMessage.fromJson(Map<String, dynamic>.from(msgData));
      }

      // Get user message feedback (grammar corrections)
      final feedbackData = result['feedback'];
      MessageFeedback? userFeedback;
      if (feedbackData is MessageFeedback) {
        userFeedback = feedbackData;
      } else if (feedbackData is Map) {
        userFeedback = MessageFeedback.fromJson(Map<String, dynamic>.from(feedbackData));
      }

      // Update messages list
      final updatedMessages = List<AIMessage>.from(state.messages);

      // If we have feedback, update the user message with it
      if (userFeedback != null && updatedMessages.isNotEmpty) {
        final lastUserMsgIndex = updatedMessages.length - 1;
        final lastUserMsg = updatedMessages[lastUserMsgIndex];
        if (lastUserMsg.role == 'user') {
          updatedMessages[lastUserMsgIndex] = AIMessage(
            role: lastUserMsg.role,
            content: lastUserMsg.content,
            feedback: userFeedback,
            responseTime: lastUserMsg.responseTime,
            timestamp: lastUserMsg.timestamp,
          );
        }
      }

      // Add AI response if available
      if (aiMessage != null) {
        updatedMessages.add(aiMessage);
        state = state.copyWith(
          messages: updatedMessages,
          isLoading: false,
        );
        return true;
      } else {
        // Even without AI message, update with feedback
        state = state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          error: 'No AI response received',
        );
        return false;
      }
    }

    state = state.copyWith(
      isLoading: false,
      error: result['message']?.toString() ?? 'Failed to send message',
    );
    return false;
  }

  Future<ConversationSummary?> endConversation() async {
    if (state.conversation == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    final result = await AIService.endConversation(state.conversation!.id);
    if (result['success'] == true) {
      final data = result['summary'];
      ConversationSummary? summary;
      if (data is ConversationSummary) {
        summary = data;
      } else if (data is Map) {
        summary = ConversationSummary.fromJson(Map<String, dynamic>.from(data));
      }
      state = ConversationState(); // Reset state
      return summary;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message']?.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = ConversationState();
  }
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier();
});

/// Conversation history provider
final conversationHistoryProvider =
    FutureProvider.family<List<AIConversation>, String>((ref, status) async {
  try {
    final result = await AIService.getConversationHistory(status: status);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<AIConversation>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => AIConversation.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Conversation topics provider
final conversationTopicsProvider =
    FutureProvider.family<List<ConversationTopic>, String?>((ref, level) async {
  try {
    final result = await AIService.getTopics(level: level);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<ConversationTopic>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => ConversationTopic.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Practice scenarios provider
final practiceScenariosProvider =
    FutureProvider.family<List<PracticeScenario>, String?>((ref, level) async {
  try {
    final result = await AIService.getScenarios(level: level);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<PracticeScenario>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => PracticeScenario.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

// ============================================
// GRAMMAR FEEDBACK PROVIDERS
// ============================================

/// Grammar feedback history provider
final grammarFeedbackHistoryProvider =
    FutureProvider<List<GrammarFeedback>>((ref) async {
  try {
    final result = await AIService.getFeedbackHistory();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<GrammarFeedback>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => GrammarFeedback.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

// ============================================
// SPEECH PROVIDERS
// ============================================

/// Pronunciation history provider
final pronunciationHistoryProvider =
    FutureProvider.family<List<PronunciationResult>, String?>((ref, language) async {
  try {
    final result = await AIService.getPronunciationHistory(language: language);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<PronunciationResult>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => PronunciationResult.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Pronunciation stats provider
final pronunciationStatsProvider =
    FutureProvider.family<PronunciationStats?, String?>((ref, language) async {
  try {
    final result = await AIService.getPronunciationStats(language: language);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is PronunciationStats) return data;
      if (data is Map) {
        return PronunciationStats.fromJson(Map<String, dynamic>.from(data));
      }
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Available voices provider
final availableVoicesProvider =
    FutureProvider.family<List<VoiceOption>, String?>((ref, language) async {
  try {
    final result = await AIService.getAvailableVoices(language: language);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<VoiceOption>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => VoiceOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

// ============================================
// TRANSLATION PROVIDERS
// ============================================

/// Popular translations provider
final popularTranslationsProvider =
    FutureProvider.family<List<PopularTranslation>, String>((ref, language) async {
  try {
    final result = await AIService.getPopularTranslations(language: language);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<PopularTranslation>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => PopularTranslation.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

// ============================================
// AI QUIZ PROVIDERS
// ============================================

/// AI quizzes provider
final aiQuizzesProvider = FutureProvider<List<AIQuiz>>((ref) async {
  try {
    final result = await AIService.getAIQuizzes();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<AIQuiz>) {
        return data;
      }
      if (data is List) {
        final quizzes = data
            .where((e) => e is Map)
            .map((e) => AIQuiz.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return quizzes;
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// AI quiz stats provider
final aiQuizStatsProvider = FutureProvider<AIQuizStats?>((ref) async {
  try {
    final result = await AIService.getAIQuizStats();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is AIQuizStats) return data;
      if (data is Map) {
        return AIQuizStats.fromJson(Map<String, dynamic>.from(data));
      }
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Active AI quiz state
class AIQuizState {
  final AIQuiz? quiz;
  final int currentIndex;
  final Map<int, String> answers;
  final bool isLoading;
  final String? error;
  final AIQuizResult? result;
  final DateTime? startTime;

  AIQuizState({
    this.quiz,
    this.currentIndex = 0,
    this.answers = const {},
    this.isLoading = false,
    this.error,
    this.result,
    this.startTime,
  });

  AIQuizState copyWith({
    AIQuiz? quiz,
    int? currentIndex,
    Map<int, String>? answers,
    bool? isLoading,
    String? error,
    AIQuizResult? result,
    DateTime? startTime,
  }) {
    return AIQuizState(
      quiz: quiz ?? this.quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      startTime: startTime ?? this.startTime,
    );
  }

  bool get canSubmit => answers.length == (quiz?.questions.length ?? 0);
  AIQuizQuestion? get currentQuestion =>
      quiz != null && currentIndex < quiz!.questions.length
          ? quiz!.questions[currentIndex]
          : null;
}

class AIQuizNotifier extends StateNotifier<AIQuizState> {
  AIQuizNotifier() : super(AIQuizState());

  Future<bool> generateQuiz(GenerateQuizRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AIService.generateQuiz(request);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      AIQuiz? quiz;
      if (data is AIQuiz) {
        quiz = data;
      } else if (data is Map) {
        quiz = AIQuiz.fromJson(Map<String, dynamic>.from(data));
      }
      if (quiz != null) {
        // If quiz has no questions, we need to start it to load questions
        if (quiz.questions.isEmpty && quiz.id.isNotEmpty) {
          return await startQuiz(quiz.id);
        }
        state = state.copyWith(
          quiz: quiz,
          currentIndex: 0,
          answers: {},
          isLoading: false,
          startTime: DateTime.now(),
        );
        return true;
      }
    }
    state = state.copyWith(
      isLoading: false,
      error: result['message']?.toString() ?? 'Failed to generate quiz',
    );
    return false;
  }

  Future<bool> startQuiz(String quizId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AIService.startAIQuiz(quizId);

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      AIQuiz? quiz;
      if (data is AIQuiz) {
        quiz = data;
      } else if (data is Map) {
        quiz = AIQuiz.fromJson(Map<String, dynamic>.from(data));
      }
      if (quiz != null) {
        state = state.copyWith(
          quiz: quiz,
          currentIndex: 0,
          answers: {},
          isLoading: false,
          startTime: DateTime.now(),
        );
        return true;
      }
    }
    state = state.copyWith(
      isLoading: false,
      error: result['message']?.toString() ?? 'Failed to start quiz',
    );
    return false;
  }

  void answerQuestion(int index, String answer) {
    final newAnswers = Map<int, String>.from(state.answers);
    newAnswers[index] = answer;
    state = state.copyWith(answers: newAnswers);
  }

  void nextQuestion() {
    if (state.quiz != null && state.currentIndex < state.quiz!.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<bool> completeQuiz() async {
    if (state.quiz == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    final timeSpent = state.startTime != null
        ? DateTime.now().difference(state.startTime!).inSeconds
        : 0;

    final answersList = List.generate(
      state.quiz!.questions.length,
      (i) => state.answers[i] ?? '',
    );

    final result = await AIService.completeAIQuiz(
      state.quiz!.id,
      CompleteQuizRequest(answers: answersList, timeSpent: timeSpent),
    );

    if (result['success'] == true) {
      final data = result['result'];
      AIQuizResult? quizResult;
      if (data is AIQuizResult) {
        quizResult = data;
      } else if (data is Map) {
        quizResult = AIQuizResult.fromJson(Map<String, dynamic>.from(data));
      }
      if (quizResult != null) {
        state = state.copyWith(result: quizResult, isLoading: false);
        return true;
      }
    }
    state = state.copyWith(
      isLoading: false,
      error: result['message']?.toString() ?? 'Failed to complete quiz',
    );
    return false;
  }

  void reset() {
    state = AIQuizState();
  }
}

final aiQuizProvider = StateNotifierProvider<AIQuizNotifier, AIQuizState>((ref) {
  return AIQuizNotifier();
});

// ============================================
// RECOMMENDATIONS PROVIDERS
// ============================================

/// Adaptive recommendations provider
final adaptiveRecommendationsProvider = FutureProvider((ref) async {
  final result = await AIService.getAdaptiveRecommendations();
  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});

/// Weak areas provider
final weakAreasProvider = FutureProvider<List<WeakArea>>((ref) async {
  try {
    final result = await AIService.getWeakAreas();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      if (data is List<WeakArea>) return data;
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => WeakArea.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});
