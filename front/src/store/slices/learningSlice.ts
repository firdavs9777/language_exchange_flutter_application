import { LEARNING_URL } from "../../constants";
import { apiSlice } from "./apiSlice";

export const learningApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // Progress
    getLearningProgress: builder.query({
      query: () => ({
        url: `${LEARNING_URL}/progress`,
      }),
      providesTags: ["Learning"],
    }),
    getLeaderboard: builder.query({
      query: ({ type = 'weekly', language, limit = 50 }: {
        type?: 'daily' | 'weekly' | 'monthly' | 'all-time';
        language?: string;
        limit?: number;
      } = {}) => {
        let url = `${LEARNING_URL}/leaderboard?type=${type}&limit=${limit}`;
        if (language) url += `&language=${language}`;
        return { url };
      },
    }),
    getDailyGoals: builder.query({
      query: () => ({
        url: `${LEARNING_URL}/goals`,
      }),
      providesTags: ["Learning"],
    }),
    updateDailyGoals: builder.mutation({
      query: ({ dailyGoal, weeklyGoal }: { dailyGoal: number; weeklyGoal: number }) => ({
        url: `${LEARNING_URL}/goals`,
        method: "PUT",
        body: { dailyGoal, weeklyGoal },
      }),
      invalidatesTags: ["Learning"],
    }),

    // Vocabulary
    getVocabulary: builder.query({
      query: ({ language, srsLevel, search, tags, limit = 50, page = 1 }: {
        language?: string;
        srsLevel?: string;
        search?: string;
        tags?: string;
        limit?: number;
        page?: number;
      } = {}) => {
        let url = `${LEARNING_URL}/vocabulary?limit=${limit}&page=${page}`;
        if (language) url += `&language=${language}`;
        if (srsLevel) url += `&srsLevel=${srsLevel}`;
        if (search) url += `&query=${encodeURIComponent(search)}`;
        if (tags) url += `&tags=${tags}`;
        return { url };
      },
      providesTags: ["Vocabulary"],
    }),
    addVocabulary: builder.mutation({
      query: (data: {
        word: string;
        translation: string;
        language: string;
        pronunciation?: string;
        partOfSpeech?: string;
        exampleSentence?: string;
        exampleTranslation?: string;
        tags?: string[];
        notes?: string;
      }) => ({
        url: `${LEARNING_URL}/vocabulary`,
        method: "POST",
        body: data,
      }),
      invalidatesTags: ["Vocabulary"],
    }),
    updateVocabulary: builder.mutation({
      query: ({ id, ...data }: { id: string; [key: string]: any }) => ({
        url: `${LEARNING_URL}/vocabulary/${id}`,
        method: "PUT",
        body: data,
      }),
      invalidatesTags: ["Vocabulary"],
    }),
    deleteVocabulary: builder.mutation({
      query: (id: string) => ({
        url: `${LEARNING_URL}/vocabulary/${id}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Vocabulary"],
    }),
    getDueReviews: builder.query({
      query: ({ language, limit = 20 }: { language?: string; limit?: number } = {}) => {
        let url = `${LEARNING_URL}/vocabulary/review?limit=${limit}`;
        if (language) url += `&language=${language}`;
        return { url };
      },
      providesTags: ["Vocabulary"],
    }),
    submitReview: builder.mutation({
      query: ({ vocabularyId, correct, responseTime }: {
        vocabularyId: string;
        correct: boolean;
        responseTime?: number;
      }) => ({
        url: `${LEARNING_URL}/vocabulary/${vocabularyId}/review`,
        method: "POST",
        body: { correct, responseTime },
      }),
      invalidatesTags: ["Vocabulary", "Learning"],
    }),
    getVocabularyStats: builder.query({
      query: (language?: string) => ({
        url: `${LEARNING_URL}/vocabulary/stats${language ? `?language=${language}` : ''}`,
      }),
    }),

    // Lessons
    getLessons: builder.query({
      query: ({ language, level, category, unit }: {
        language?: string;
        level?: string;
        category?: string;
        unit?: number;
      } = {}) => {
        let url = `${LEARNING_URL}/lessons`;
        const params: string[] = [];
        if (language) params.push(`language=${language}`);
        if (level) params.push(`level=${level}`);
        if (category) params.push(`category=${category}`);
        if (unit) params.push(`unit=${unit}`);
        if (params.length > 0) url += `?${params.join('&')}`;
        return { url };
      },
      providesTags: ["Lessons"],
    }),
    getRecommendedLessons: builder.query({
      query: ({ language, limit = 5 }: { language?: string; limit?: number } = {}) => ({
        url: `${LEARNING_URL}/lessons/recommended${language ? `?language=${language}&limit=${limit}` : `?limit=${limit}`}`,
      }),
      providesTags: ["Lessons"],
    }),
    getLesson: builder.query({
      query: (lessonId: string) => ({
        url: `${LEARNING_URL}/lessons/${lessonId}`,
      }),
    }),
    startLesson: builder.mutation({
      query: (lessonId: string) => ({
        url: `${LEARNING_URL}/lessons/${lessonId}/start`,
        method: "POST",
      }),
    }),
    submitLesson: builder.mutation({
      query: ({ lessonId, answers, timeSpent }: {
        lessonId: string;
        answers: Array<{ questionId: string; answer: string | string[] }>;
        timeSpent: number;
      }) => ({
        url: `${LEARNING_URL}/lessons/${lessonId}/submit`,
        method: "POST",
        body: { answers, timeSpent },
      }),
      invalidatesTags: ["Lessons", "Learning"],
    }),

    // Quizzes
    getQuizzes: builder.query({
      query: ({ language, type }: { language?: string; type?: string } = {}) => {
        let url = `${LEARNING_URL}/quizzes`;
        const params: string[] = [];
        if (language) params.push(`language=${language}`);
        if (type) params.push(`type=${type}`);
        if (params.length > 0) url += `?${params.join('&')}`;
        return { url };
      },
      providesTags: ["Quizzes"],
    }),
    getQuiz: builder.query({
      query: (quizId: string) => ({
        url: `${LEARNING_URL}/quizzes/${quizId}`,
      }),
    }),
    submitQuiz: builder.mutation({
      query: ({ quizId, answers, timeSpent }: {
        quizId: string;
        answers: Array<{ questionId: string; answer: string | string[] }>;
        timeSpent: number;
      }) => ({
        url: `${LEARNING_URL}/quizzes/${quizId}/submit`,
        method: "POST",
        body: { answers, timeSpent },
      }),
      invalidatesTags: ["Quizzes", "Learning"],
    }),

    // Achievements
    getAchievements: builder.query({
      query: () => ({
        url: `${LEARNING_URL}/achievements`,
      }),
      providesTags: ["Learning"],
    }),

    // Challenges
    getChallenges: builder.query({
      query: () => ({
        url: `${LEARNING_URL}/challenges`,
      }),
      providesTags: ["Learning"],
    }),
    joinChallenge: builder.mutation({
      query: (challengeId: string) => ({
        url: `${LEARNING_URL}/challenges/${challengeId}/join`,
        method: "POST",
      }),
      invalidatesTags: ["Learning"],
    }),

    // Corrections (for language exchange)
    sendCorrection: builder.mutation({
      query: ({ messageId, originalText, correctedText, explanation }: {
        messageId: string;
        originalText: string;
        correctedText: string;
        explanation?: string;
      }) => ({
        url: `/api/v1/messages/${messageId}/corrections`,
        method: "POST",
        body: { originalText, correctedText, explanation },
      }),
    }),
    getCorrections: builder.query({
      query: (messageId: string) => ({
        url: `/api/v1/messages/${messageId}/corrections`,
      }),
    }),
    acceptCorrection: builder.mutation({
      query: ({ messageId, correctionId }: { messageId: string; correctionId: string }) => ({
        url: `/api/v1/messages/${messageId}/corrections/${correctionId}/accept`,
        method: "POST",
      }),
    }),
  }),
});

export const {
  // Progress
  useGetLearningProgressQuery,
  useGetLeaderboardQuery,
  useGetDailyGoalsQuery,
  useUpdateDailyGoalsMutation,
  // Vocabulary
  useGetVocabularyQuery,
  useAddVocabularyMutation,
  useUpdateVocabularyMutation,
  useDeleteVocabularyMutation,
  useGetDueReviewsQuery,
  useSubmitReviewMutation,
  useGetVocabularyStatsQuery,
  // Lessons
  useGetLessonsQuery,
  useGetRecommendedLessonsQuery,
  useGetLessonQuery,
  useStartLessonMutation,
  useSubmitLessonMutation,
  // Quizzes
  useGetQuizzesQuery,
  useGetQuizQuery,
  useSubmitQuizMutation,
  // Achievements & Challenges
  useGetAchievementsQuery,
  useGetChallengesQuery,
  useJoinChallengeMutation,
  // Corrections
  useSendCorrectionMutation,
  useGetCorrectionsQuery,
  useAcceptCorrectionMutation,
} = learningApiSlice;

export default learningApiSlice.reducer;
