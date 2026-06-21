# BananaTalk Learning Module - Frontend Web Developer Guide

## Table of Contents
1. [Overview](#overview)
2. [API Hooks Reference](#api-hooks-reference)
3. [Screen 1: Learning Dashboard](#screen-1-learning-dashboard)
4. [Screen 2: Vocabulary List](#screen-2-vocabulary-list)
5. [Screen 3: Add/Edit Vocabulary](#screen-3-addedit-vocabulary)
6. [Screen 4: Vocabulary Review (Flashcards)](#screen-4-vocabulary-review-flashcards)
7. [Screen 5: Lessons List](#screen-5-lessons-list)
8. [Screen 6: Lesson Detail/Player](#screen-6-lesson-detailplayer)
9. [Screen 7: Quizzes List](#screen-7-quizzes-list)
10. [Screen 8: Quiz Player](#screen-8-quiz-player)
11. [Screen 9: Leaderboard](#screen-9-leaderboard)
12. [Screen 10: Achievements](#screen-10-achievements)
13. [Screen 11: Challenges](#screen-11-challenges)
14. [Screen 12: Daily Goals Settings](#screen-12-daily-goals-settings)
15. [Screen 13: Language Corrections](#screen-13-language-corrections)
16. [Components Library](#components-library)
17. [State Management](#state-management)
18. [Styling Guidelines](#styling-guidelines)

---

## Overview

The Learning Module is a language learning system with:
- **Vocabulary** with SRS (Spaced Repetition System)
- **Lessons** with interactive exercises
- **Quizzes** for testing knowledge
- **Gamification** (XP, streaks, achievements, leaderboards)
- **Language Corrections** for chat messages

### File Structure

```
src/components/learning/
├── LearningDashboard.tsx
├── LearningDashboard.scss
├── Vocabulary/
│   ├── VocabularyList.tsx
│   ├── VocabularyList.scss
│   ├── VocabularyCard.tsx
│   ├── VocabularyForm.tsx
│   └── VocabularyForm.scss
├── Review/
│   ├── VocabularyReview.tsx
│   ├── VocabularyReview.scss
│   ├── Flashcard.tsx
│   └── Flashcard.scss
├── Lessons/
│   ├── LessonsList.tsx
│   ├── LessonsList.scss
│   ├── LessonCard.tsx
│   ├── LessonPlayer.tsx
│   ├── LessonPlayer.scss
│   └── exercises/
│       ├── MultipleChoice.tsx
│       ├── FillInBlank.tsx
│       ├── Matching.tsx
│       ├── Listening.tsx
│       └── Speaking.tsx
├── Quizzes/
│   ├── QuizzesList.tsx
│   ├── QuizCard.tsx
│   ├── QuizPlayer.tsx
│   └── QuizPlayer.scss
├── Gamification/
│   ├── Leaderboard.tsx
│   ├── Leaderboard.scss
│   ├── Achievements.tsx
│   ├── Achievements.scss
│   ├── AchievementBadge.tsx
│   ├── Challenges.tsx
│   ├── ChallengeCard.tsx
│   └── XPDisplay.tsx
├── Goals/
│   ├── DailyGoals.tsx
│   └── GoalsSettings.tsx
├── Corrections/
│   ├── CorrectionModal.tsx
│   ├── CorrectionDiff.tsx
│   └── CorrectionsList.tsx
└── shared/
    ├── ProgressBar.tsx
    ├── StreakCounter.tsx
    ├── LevelBadge.tsx
    └── LanguageSelector.tsx
```

---

## API Hooks Reference

**File:** `src/store/slices/learningSlice.ts`

```typescript
// Progress & Goals
useGetLearningProgressQuery()
useGetDailyGoalsQuery()
useUpdateDailyGoalsMutation()
useGetLeaderboardQuery({ type, language, limit })

// Vocabulary
useGetVocabularyQuery({ language, srsLevel, search, tags, limit, page })
useAddVocabularyMutation()
useUpdateVocabularyMutation()
useDeleteVocabularyMutation()
useGetDueReviewsQuery({ language, limit })
useSubmitReviewMutation()
useGetVocabularyStatsQuery(language)

// Lessons
useGetLessonsQuery({ language, level, category, unit })
useGetRecommendedLessonsQuery({ language, limit })
useGetLessonQuery(lessonId)
useStartLessonMutation()
useSubmitLessonMutation()

// Quizzes
useGetQuizzesQuery({ language, type })
useGetQuizQuery(quizId)
useSubmitQuizMutation()

// Achievements & Challenges
useGetAchievementsQuery()
useGetChallengesQuery()
useJoinChallengeMutation()

// Corrections
useSendCorrectionMutation()
useGetCorrectionsQuery(messageId)
useAcceptCorrectionMutation()
```

---

## Screen 1: Learning Dashboard

**Route:** `/learn`
**File:** `src/components/learning/LearningDashboard.tsx`

### Purpose
Main entry point for the learning module. Shows user's progress, quick actions, and recommendations.

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Learn                                    🏆 2,450 XP       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │  🔥 7 Day Streak!                                   │    │
│  │                                                     │    │
│  │  Daily Goal: ████████████░░░░░░░░ 60%              │    │
│  │  12/20 XP earned today                              │    │
│  │                                                     │    │
│  │  Weekly Goal: ██████░░░░░░░░░░░░░ 35%              │    │
│  │  70/200 XP this week                                │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│  Quick Actions                                              │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐     │
│  │   📚          │ │   📝          │ │   🎯          │     │
│  │   Review      │ │   Lessons     │ │   Quiz        │     │
│  │               │ │               │ │               │     │
│  │  15 words due │ │  Continue     │ │  Daily Quiz   │     │
│  └───────────────┘ └───────────────┘ └───────────────┘     │
├─────────────────────────────────────────────────────────────┤
│  Vocabulary Stats                                           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │  156    │ │   42    │ │   89    │ │   25    │          │
│  │  Total  │ │Mastered │ │Learning │ │  New    │          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
├─────────────────────────────────────────────────────────────┤
│  Continue Learning                                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🇰🇷 Korean Basics - Lesson 3                        │    │
│  │ Greetings and Introductions                         │    │
│  │ ████████░░░░ 65% complete           [Continue →]    │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│  Recommended For You                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ 🇯🇵         │ │ 🇪🇸         │ │ 🇫🇷         │           │
│  │ Numbers     │ │ Food Vocab  │ │ Verbs 101   │           │
│  │ Beginner    │ │ Beginner    │ │ Intermediate│           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  Recent Achievements                                        │
│  🏅 First Steps  🏅 Word Collector  🏅 7 Day Streak        │
│                                          [See All →]        │
└─────────────────────────────────────────────────────────────┘
```

### Component Code

```typescript
// LearningDashboard.tsx
import React from 'react';
import { Link } from 'react-router-dom';
import {
  useGetLearningProgressQuery,
  useGetDailyGoalsQuery,
  useGetDueReviewsQuery,
  useGetRecommendedLessonsQuery,
  useGetVocabularyStatsQuery,
  useGetAchievementsQuery
} from '../../store/slices/learningSlice';
import StreakCounter from './shared/StreakCounter';
import ProgressBar from './shared/ProgressBar';
import XPDisplay from './Gamification/XPDisplay';
import LessonCard from './Lessons/LessonCard';
import AchievementBadge from './Gamification/AchievementBadge';
import './LearningDashboard.scss';

interface LearningProgress {
  totalXP: number;
  currentStreak: number;
  longestStreak: number;
  dailyXP: number;
  weeklyXP: number;
  level: number;
  lessonsCompleted: number;
  wordsLearned: number;
}

interface DailyGoals {
  dailyGoal: number;
  weeklyGoal: number;
  dailyProgress: number;
  weeklyProgress: number;
}

const LearningDashboard: React.FC = () => {
  const { data: progress, isLoading: progressLoading } = useGetLearningProgressQuery();
  const { data: goals } = useGetDailyGoalsQuery();
  const { data: dueReviews } = useGetDueReviewsQuery({ limit: 1 });
  const { data: recommended } = useGetRecommendedLessonsQuery({ limit: 3 });
  const { data: vocabStats } = useGetVocabularyStatsQuery();
  const { data: achievements } = useGetAchievementsQuery();

  const dueCount = dueReviews?.data?.length || 0;
  const recentAchievements = achievements?.data?.filter(a => a.earned).slice(0, 3) || [];

  if (progressLoading) {
    return <div className="loading-spinner">Loading...</div>;
  }

  return (
    <div className="learning-dashboard">
      {/* Header */}
      <header className="dashboard-header">
        <h1>Learn</h1>
        <XPDisplay xp={progress?.data?.totalXP || 0} />
      </header>

      {/* Streak & Goals Card */}
      <section className="streak-goals-card">
        <StreakCounter streak={progress?.data?.currentStreak || 0} />

        <div className="goals-progress">
          <div className="goal-item">
            <span className="goal-label">Daily Goal</span>
            <ProgressBar
              current={goals?.data?.dailyProgress || 0}
              total={goals?.data?.dailyGoal || 20}
            />
            <span className="goal-text">
              {goals?.data?.dailyProgress || 0}/{goals?.data?.dailyGoal || 20} XP today
            </span>
          </div>

          <div className="goal-item">
            <span className="goal-label">Weekly Goal</span>
            <ProgressBar
              current={goals?.data?.weeklyProgress || 0}
              total={goals?.data?.weeklyGoal || 100}
            />
            <span className="goal-text">
              {goals?.data?.weeklyProgress || 0}/{goals?.data?.weeklyGoal || 100} XP this week
            </span>
          </div>
        </div>
      </section>

      {/* Quick Actions */}
      <section className="quick-actions">
        <h2>Quick Actions</h2>
        <div className="actions-grid">
          <Link to="/learn/review" className="action-card review">
            <span className="action-icon">📚</span>
            <span className="action-title">Review</span>
            <span className="action-subtitle">
              {dueCount > 0 ? `${dueCount} words due` : 'All caught up!'}
            </span>
          </Link>

          <Link to="/learn/lessons" className="action-card lessons">
            <span className="action-icon">📝</span>
            <span className="action-title">Lessons</span>
            <span className="action-subtitle">Continue learning</span>
          </Link>

          <Link to="/learn/quizzes" className="action-card quiz">
            <span className="action-icon">🎯</span>
            <span className="action-title">Quiz</span>
            <span className="action-subtitle">Test yourself</span>
          </Link>
        </div>
      </section>

      {/* Vocabulary Stats */}
      <section className="vocab-stats">
        <h2>Vocabulary Stats</h2>
        <div className="stats-grid">
          <div className="stat-item">
            <span className="stat-value">{vocabStats?.data?.total || 0}</span>
            <span className="stat-label">Total</span>
          </div>
          <div className="stat-item mastered">
            <span className="stat-value">{vocabStats?.data?.mastered || 0}</span>
            <span className="stat-label">Mastered</span>
          </div>
          <div className="stat-item learning">
            <span className="stat-value">{vocabStats?.data?.learning || 0}</span>
            <span className="stat-label">Learning</span>
          </div>
          <div className="stat-item new">
            <span className="stat-value">{vocabStats?.data?.new || 0}</span>
            <span className="stat-label">New</span>
          </div>
        </div>
      </section>

      {/* Recommended Lessons */}
      {recommended?.data?.length > 0 && (
        <section className="recommended">
          <div className="section-header">
            <h2>Recommended For You</h2>
            <Link to="/learn/lessons">See All →</Link>
          </div>
          <div className="lessons-scroll">
            {recommended.data.map((lesson: any) => (
              <LessonCard key={lesson._id} lesson={lesson} compact />
            ))}
          </div>
        </section>
      )}

      {/* Recent Achievements */}
      {recentAchievements.length > 0 && (
        <section className="recent-achievements">
          <div className="section-header">
            <h2>Recent Achievements</h2>
            <Link to="/learn/achievements">See All →</Link>
          </div>
          <div className="achievements-row">
            {recentAchievements.map((achievement: any) => (
              <AchievementBadge
                key={achievement._id}
                achievement={achievement}
                size="small"
              />
            ))}
          </div>
        </section>
      )}
    </div>
  );
};

export default LearningDashboard;
```

### SCSS Styles

```scss
// LearningDashboard.scss
.learning-dashboard {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;

  .dashboard-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;

    h1 {
      font-size: 28px;
      font-weight: 700;
      color: #1a1a1a;
    }
  }

  .streak-goals-card {
    background: linear-gradient(135deg, #00BFA5 0%, #008E76 100%);
    border-radius: 16px;
    padding: 24px;
    color: white;
    margin-bottom: 24px;

    .goals-progress {
      margin-top: 20px;

      .goal-item {
        margin-bottom: 16px;

        .goal-label {
          font-size: 14px;
          opacity: 0.9;
        }

        .goal-text {
          font-size: 12px;
          opacity: 0.8;
        }
      }
    }
  }

  .quick-actions {
    margin-bottom: 24px;

    h2 {
      font-size: 18px;
      margin-bottom: 16px;
    }

    .actions-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;

      .action-card {
        background: white;
        border-radius: 12px;
        padding: 20px;
        text-align: center;
        text-decoration: none;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        transition: transform 0.2s, box-shadow 0.2s;

        &:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
        }

        .action-icon {
          font-size: 32px;
          display: block;
          margin-bottom: 8px;
        }

        .action-title {
          font-size: 16px;
          font-weight: 600;
          color: #1a1a1a;
          display: block;
        }

        .action-subtitle {
          font-size: 12px;
          color: #666;
          display: block;
          margin-top: 4px;
        }

        &.review {
          border-left: 4px solid #00BFA5;
        }

        &.lessons {
          border-left: 4px solid #FFD54F;
        }

        &.quiz {
          border-left: 4px solid #7C4DFF;
        }
      }
    }
  }

  .vocab-stats {
    margin-bottom: 24px;

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;

      .stat-item {
        background: white;
        border-radius: 12px;
        padding: 16px;
        text-align: center;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);

        .stat-value {
          font-size: 24px;
          font-weight: 700;
          display: block;
        }

        .stat-label {
          font-size: 12px;
          color: #666;
        }

        &.mastered .stat-value { color: #4CAF50; }
        &.learning .stat-value { color: #FF9800; }
        &.new .stat-value { color: #2196F3; }
      }
    }
  }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;

    h2 {
      font-size: 18px;
    }

    a {
      color: #00BFA5;
      text-decoration: none;
      font-size: 14px;

      &:hover {
        text-decoration: underline;
      }
    }
  }

  .lessons-scroll {
    display: flex;
    gap: 12px;
    overflow-x: auto;
    padding-bottom: 8px;

    &::-webkit-scrollbar {
      height: 4px;
    }

    &::-webkit-scrollbar-thumb {
      background: #00BFA5;
      border-radius: 2px;
    }
  }

  .achievements-row {
    display: flex;
    gap: 16px;
  }
}

// Responsive
@media (max-width: 768px) {
  .learning-dashboard {
    .quick-actions .actions-grid {
      grid-template-columns: repeat(3, 1fr);
    }

    .vocab-stats .stats-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }
}
```

---

## Screen 2: Vocabulary List

**Route:** `/learn/vocabulary`
**File:** `src/components/learning/Vocabulary/VocabularyList.tsx`

### Purpose
Display all saved vocabulary words with filtering and search.

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Vocabulary                      [+ Add Word]     │
├─────────────────────────────────────────────────────────────┤
│  [🔍 Search words...]                                       │
├─────────────────────────────────────────────────────────────┤
│  Language: [All ▼]   Level: [All ▼]   Tags: [All ▼]        │
├─────────────────────────────────────────────────────────────┤
│  [All] [New] [Learning] [Mastered]                  156     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 안녕하세요                              SRS: ████░   │    │
│  │ Hello (formal greeting)                             │    │
│  │ 🇰🇷 Korean  •  Greetings  •  Due in 2 days         │    │
│  │                                    [Edit] [Delete]  │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 감사합니다                              SRS: █████   │    │
│  │ Thank you (formal)                                  │    │
│  │ 🇰🇷 Korean  •  Phrases  •  Mastered ✓              │    │
│  │                                    [Edit] [Delete]  │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 사랑해요                                SRS: ██░░░   │    │
│  │ I love you                                          │    │
│  │ 🇰🇷 Korean  •  Phrases  •  Review now!             │    │
│  │                                    [Edit] [Delete]  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [Load More]                                                │
└─────────────────────────────────────────────────────────────┘
```

### Component Code

```typescript
// VocabularyList.tsx
import React, { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import {
  useGetVocabularyQuery,
  useDeleteVocabularyMutation
} from '../../../store/slices/learningSlice';
import { useGetLanguagesQuery } from '../../../store/slices/communitySlice';
import VocabularyCard from './VocabularyCard';
import VocabularyForm from './VocabularyForm';
import Modal from '../../shared/Modal';
import './VocabularyList.scss';

type SRSFilter = 'all' | 'new' | 'learning' | 'mastered';

interface VocabularyFilters {
  language: string;
  srsLevel: string;
  search: string;
  tags: string;
}

const VocabularyList: React.FC = () => {
  const [filters, setFilters] = useState<VocabularyFilters>({
    language: '',
    srsLevel: '',
    search: '',
    tags: ''
  });
  const [srsFilter, setSrsFilter] = useState<SRSFilter>('all');
  const [page, setPage] = useState(1);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingWord, setEditingWord] = useState<any>(null);

  const { data: vocabularyData, isLoading, refetch } = useGetVocabularyQuery({
    ...filters,
    srsLevel: srsFilter === 'all' ? '' : srsFilter,
    page,
    limit: 20
  });

  const { data: languagesData } = useGetLanguagesQuery();
  const [deleteVocabulary] = useDeleteVocabularyMutation();

  const vocabulary = vocabularyData?.data || [];
  const pagination = vocabularyData?.pagination;

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilters(prev => ({ ...prev, search: e.target.value }));
    setPage(1);
  };

  const handleLanguageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setFilters(prev => ({ ...prev, language: e.target.value }));
    setPage(1);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this word?')) {
      await deleteVocabulary(id);
      refetch();
    }
  };

  const handleEdit = (word: any) => {
    setEditingWord(word);
    setShowAddModal(true);
  };

  const handleCloseModal = () => {
    setShowAddModal(false);
    setEditingWord(null);
  };

  const handleSaveSuccess = () => {
    handleCloseModal();
    refetch();
  };

  const getSrsFilterCount = (filter: SRSFilter) => {
    // This would ideally come from the API
    return vocabulary.filter((v: any) => {
      if (filter === 'all') return true;
      if (filter === 'new') return v.srsLevel === 0;
      if (filter === 'learning') return v.srsLevel > 0 && v.srsLevel < 5;
      if (filter === 'mastered') return v.srsLevel === 5;
      return false;
    }).length;
  };

  return (
    <div className="vocabulary-list">
      {/* Header */}
      <header className="vocab-header">
        <div className="header-left">
          <Link to="/learn" className="back-btn">←</Link>
          <h1>Vocabulary</h1>
        </div>
        <button
          className="add-btn"
          onClick={() => setShowAddModal(true)}
        >
          + Add Word
        </button>
      </header>

      {/* Search */}
      <div className="search-bar">
        <input
          type="text"
          placeholder="Search words..."
          value={filters.search}
          onChange={handleSearch}
        />
      </div>

      {/* Filters */}
      <div className="filters-row">
        <select value={filters.language} onChange={handleLanguageChange}>
          <option value="">All Languages</option>
          {languagesData?.data?.map((lang: any) => (
            <option key={lang.code} value={lang.code}>
              {lang.name}
            </option>
          ))}
        </select>

        <select
          value={filters.tags}
          onChange={(e) => setFilters(prev => ({ ...prev, tags: e.target.value }))}
        >
          <option value="">All Tags</option>
          <option value="greetings">Greetings</option>
          <option value="phrases">Phrases</option>
          <option value="verbs">Verbs</option>
          <option value="nouns">Nouns</option>
        </select>
      </div>

      {/* SRS Tabs */}
      <div className="srs-tabs">
        {(['all', 'new', 'learning', 'mastered'] as SRSFilter[]).map(filter => (
          <button
            key={filter}
            className={`srs-tab ${srsFilter === filter ? 'active' : ''}`}
            onClick={() => { setSrsFilter(filter); setPage(1); }}
          >
            {filter.charAt(0).toUpperCase() + filter.slice(1)}
          </button>
        ))}
        <span className="total-count">{vocabulary.length}</span>
      </div>

      {/* Vocabulary Items */}
      <div className="vocab-items">
        {isLoading ? (
          <div className="loading">Loading...</div>
        ) : vocabulary.length === 0 ? (
          <div className="empty-state">
            <p>No vocabulary words found.</p>
            <button onClick={() => setShowAddModal(true)}>
              Add your first word
            </button>
          </div>
        ) : (
          vocabulary.map((word: any) => (
            <VocabularyCard
              key={word._id}
              word={word}
              onEdit={() => handleEdit(word)}
              onDelete={() => handleDelete(word._id)}
            />
          ))
        )}
      </div>

      {/* Load More */}
      {pagination?.hasMore && (
        <button
          className="load-more-btn"
          onClick={() => setPage(prev => prev + 1)}
        >
          Load More
        </button>
      )}

      {/* Add/Edit Modal */}
      {showAddModal && (
        <Modal onClose={handleCloseModal}>
          <VocabularyForm
            editWord={editingWord}
            onSuccess={handleSaveSuccess}
            onCancel={handleCloseModal}
          />
        </Modal>
      )}
    </div>
  );
};

export default VocabularyList;
```

### VocabularyCard Component

```typescript
// VocabularyCard.tsx
import React from 'react';
import { formatDistanceToNow } from 'date-fns';
import './VocabularyCard.scss';

interface VocabularyCardProps {
  word: {
    _id: string;
    word: string;
    translation: string;
    language: string;
    pronunciation?: string;
    tags: string[];
    srsLevel: number;
    nextReviewDate: Date;
  };
  onEdit: () => void;
  onDelete: () => void;
}

const SRS_LABELS = ['New', 'Apprentice 1', 'Apprentice 2', 'Guru', 'Master', 'Mastered'];
const SRS_COLORS = ['#2196F3', '#FF9800', '#FF9800', '#9C27B0', '#4CAF50', '#4CAF50'];

const VocabularyCard: React.FC<VocabularyCardProps> = ({ word, onEdit, onDelete }) => {
  const isOverdue = new Date(word.nextReviewDate) < new Date();
  const isMastered = word.srsLevel === 5;

  const getReviewText = () => {
    if (isMastered) return 'Mastered ✓';
    if (isOverdue) return 'Review now!';
    return `Due ${formatDistanceToNow(new Date(word.nextReviewDate), { addSuffix: true })}`;
  };

  const getLanguageFlag = (code: string) => {
    const flags: Record<string, string> = {
      ko: '🇰🇷', ja: '🇯🇵', zh: '🇨🇳', es: '🇪🇸', fr: '🇫🇷',
      de: '🇩🇪', it: '🇮🇹', pt: '🇵🇹', ru: '🇷🇺', en: '🇺🇸'
    };
    return flags[code] || '🌐';
  };

  return (
    <div className={`vocabulary-card ${isOverdue ? 'overdue' : ''}`}>
      <div className="card-main">
        <div className="word-content">
          <h3 className="word">{word.word}</h3>
          <p className="translation">{word.translation}</p>
          {word.pronunciation && (
            <span className="pronunciation">{word.pronunciation}</span>
          )}
        </div>

        <div className="srs-indicator">
          <div className="srs-bar">
            {[...Array(5)].map((_, i) => (
              <div
                key={i}
                className={`srs-segment ${i < word.srsLevel ? 'filled' : ''}`}
                style={{ backgroundColor: i < word.srsLevel ? SRS_COLORS[word.srsLevel] : '#e0e0e0' }}
              />
            ))}
          </div>
          <span className="srs-label">{SRS_LABELS[word.srsLevel]}</span>
        </div>
      </div>

      <div className="card-footer">
        <div className="meta">
          <span className="language">
            {getLanguageFlag(word.language)} {word.language.toUpperCase()}
          </span>
          {word.tags.map(tag => (
            <span key={tag} className="tag">{tag}</span>
          ))}
          <span className={`review-status ${isOverdue ? 'overdue' : ''}`}>
            {getReviewText()}
          </span>
        </div>

        <div className="actions">
          <button onClick={onEdit} className="edit-btn">Edit</button>
          <button onClick={onDelete} className="delete-btn">Delete</button>
        </div>
      </div>
    </div>
  );
};

export default VocabularyCard;
```

---

## Screen 3: Add/Edit Vocabulary

**File:** `src/components/learning/Vocabulary/VocabularyForm.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Add New Word                                    [X Close]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Word *                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 안녕하세요                                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Translation *                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Hello (formal greeting)                             │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Language *                                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Korean                                          [▼] │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Pronunciation                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ an-nyeong-ha-se-yo                                  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Part of Speech                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Phrase                                          [▼] │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Example Sentence                                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 안녕하세요, 저는 John입니다.                        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Example Translation                                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Hello, I am John.                                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Tags                                                       │
│  [Greetings] [Formal] [+ Add Tag]                          │
│                                                             │
│  Notes                                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Used in formal situations...                        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [Cancel]                                      [Save Word]  │
└─────────────────────────────────────────────────────────────┘
```

### Component Code

```typescript
// VocabularyForm.tsx
import React, { useState, useEffect } from 'react';
import {
  useAddVocabularyMutation,
  useUpdateVocabularyMutation
} from '../../../store/slices/learningSlice';
import { useGetLanguagesQuery } from '../../../store/slices/communitySlice';
import './VocabularyForm.scss';

interface VocabularyFormProps {
  editWord?: any;
  onSuccess: () => void;
  onCancel: () => void;
}

interface FormData {
  word: string;
  translation: string;
  language: string;
  pronunciation: string;
  partOfSpeech: string;
  exampleSentence: string;
  exampleTranslation: string;
  tags: string[];
  notes: string;
}

const PARTS_OF_SPEECH = [
  'Noun', 'Verb', 'Adjective', 'Adverb', 'Phrase',
  'Pronoun', 'Preposition', 'Conjunction', 'Interjection'
];

const VocabularyForm: React.FC<VocabularyFormProps> = ({
  editWord,
  onSuccess,
  onCancel
}) => {
  const [formData, setFormData] = useState<FormData>({
    word: '',
    translation: '',
    language: '',
    pronunciation: '',
    partOfSpeech: '',
    exampleSentence: '',
    exampleTranslation: '',
    tags: [],
    notes: ''
  });
  const [newTag, setNewTag] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  const { data: languagesData } = useGetLanguagesQuery();
  const [addVocabulary, { isLoading: isAdding }] = useAddVocabularyMutation();
  const [updateVocabulary, { isLoading: isUpdating }] = useUpdateVocabularyMutation();

  const isLoading = isAdding || isUpdating;
  const isEditing = !!editWord;

  useEffect(() => {
    if (editWord) {
      setFormData({
        word: editWord.word || '',
        translation: editWord.translation || '',
        language: editWord.language || '',
        pronunciation: editWord.pronunciation || '',
        partOfSpeech: editWord.partOfSpeech || '',
        exampleSentence: editWord.exampleSentence || '',
        exampleTranslation: editWord.exampleTranslation || '',
        tags: editWord.tags || [],
        notes: editWord.notes || ''
      });
    }
  }, [editWord]);

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const handleAddTag = () => {
    if (newTag.trim() && !formData.tags.includes(newTag.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, newTag.trim()]
      }));
      setNewTag('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(tag => tag !== tagToRemove)
    }));
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.word.trim()) {
      newErrors.word = 'Word is required';
    }
    if (!formData.translation.trim()) {
      newErrors.translation = 'Translation is required';
    }
    if (!formData.language) {
      newErrors.language = 'Language is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validate()) return;

    try {
      if (isEditing) {
        await updateVocabulary({
          id: editWord._id,
          ...formData
        }).unwrap();
      } else {
        await addVocabulary(formData).unwrap();
      }
      onSuccess();
    } catch (error) {
      console.error('Failed to save vocabulary:', error);
    }
  };

  return (
    <form className="vocabulary-form" onSubmit={handleSubmit}>
      <h2>{isEditing ? 'Edit Word' : 'Add New Word'}</h2>

      <div className="form-group">
        <label htmlFor="word">Word *</label>
        <input
          type="text"
          id="word"
          name="word"
          value={formData.word}
          onChange={handleChange}
          placeholder="Enter word"
          className={errors.word ? 'error' : ''}
        />
        {errors.word && <span className="error-text">{errors.word}</span>}
      </div>

      <div className="form-group">
        <label htmlFor="translation">Translation *</label>
        <input
          type="text"
          id="translation"
          name="translation"
          value={formData.translation}
          onChange={handleChange}
          placeholder="Enter translation"
          className={errors.translation ? 'error' : ''}
        />
        {errors.translation && <span className="error-text">{errors.translation}</span>}
      </div>

      <div className="form-group">
        <label htmlFor="language">Language *</label>
        <select
          id="language"
          name="language"
          value={formData.language}
          onChange={handleChange}
          className={errors.language ? 'error' : ''}
        >
          <option value="">Select language</option>
          {languagesData?.data?.map((lang: any) => (
            <option key={lang.code} value={lang.code}>
              {lang.name}
            </option>
          ))}
        </select>
        {errors.language && <span className="error-text">{errors.language}</span>}
      </div>

      <div className="form-group">
        <label htmlFor="pronunciation">Pronunciation</label>
        <input
          type="text"
          id="pronunciation"
          name="pronunciation"
          value={formData.pronunciation}
          onChange={handleChange}
          placeholder="How to pronounce"
        />
      </div>

      <div className="form-group">
        <label htmlFor="partOfSpeech">Part of Speech</label>
        <select
          id="partOfSpeech"
          name="partOfSpeech"
          value={formData.partOfSpeech}
          onChange={handleChange}
        >
          <option value="">Select part of speech</option>
          {PARTS_OF_SPEECH.map(pos => (
            <option key={pos} value={pos.toLowerCase()}>
              {pos}
            </option>
          ))}
        </select>
      </div>

      <div className="form-group">
        <label htmlFor="exampleSentence">Example Sentence</label>
        <input
          type="text"
          id="exampleSentence"
          name="exampleSentence"
          value={formData.exampleSentence}
          onChange={handleChange}
          placeholder="Example using this word"
        />
      </div>

      <div className="form-group">
        <label htmlFor="exampleTranslation">Example Translation</label>
        <input
          type="text"
          id="exampleTranslation"
          name="exampleTranslation"
          value={formData.exampleTranslation}
          onChange={handleChange}
          placeholder="Translation of example"
        />
      </div>

      <div className="form-group">
        <label>Tags</label>
        <div className="tags-container">
          {formData.tags.map(tag => (
            <span key={tag} className="tag">
              {tag}
              <button type="button" onClick={() => handleRemoveTag(tag)}>×</button>
            </span>
          ))}
          <div className="add-tag">
            <input
              type="text"
              value={newTag}
              onChange={(e) => setNewTag(e.target.value)}
              placeholder="Add tag"
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
            />
            <button type="button" onClick={handleAddTag}>+</button>
          </div>
        </div>
      </div>

      <div className="form-group">
        <label htmlFor="notes">Notes</label>
        <textarea
          id="notes"
          name="notes"
          value={formData.notes}
          onChange={handleChange}
          placeholder="Additional notes..."
          rows={3}
        />
      </div>

      <div className="form-actions">
        <button type="button" onClick={onCancel} className="cancel-btn">
          Cancel
        </button>
        <button type="submit" className="save-btn" disabled={isLoading}>
          {isLoading ? 'Saving...' : isEditing ? 'Update Word' : 'Save Word'}
        </button>
      </div>
    </form>
  );
};

export default VocabularyForm;
```

---

## Screen 4: Vocabulary Review (Flashcards)

**Route:** `/learn/review`
**File:** `src/components/learning/Review/VocabularyReview.tsx`

### Purpose
Flashcard-based SRS review session for due vocabulary words.

### UI States

**State 1: Question (Front of Card)**
```
┌─────────────────────────────────────────────────────────────┐
│  Review              [3/15]               [X End Session]   │
├─────────────────────────────────────────────────────────────┤
│  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░ (20%)             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                                                             │
│                       안녕하세요                             │
│                                                             │
│                     🇰🇷 Korean                              │
│                                                             │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│              (Tap card or button to reveal)                 │
│                                                             │
│                   [Show Answer]                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**State 2: Answer (Back of Card)**
```
┌─────────────────────────────────────────────────────────────┐
│  Review              [3/15]               [X End Session]   │
├─────────────────────────────────────────────────────────────┤
│  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░ (20%)             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                       안녕하세요                             │
│                      ──────────                             │
│                        Hello                                │
│                  (formal greeting)                          │
│                                                             │
│                  "an-nyeong-ha-se-yo"                       │
│                                                             │
│     Example: 안녕하세요, 저는 John입니다.                    │
│              Hello, I am John.                              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│            How well did you remember this?                  │
│                                                             │
│     ┌──────────┐                    ┌──────────┐           │
│     │          │                    │          │           │
│     │ ❌ Wrong  │                    │ ✅ Correct│           │
│     │          │                    │          │           │
│     └──────────┘                    └──────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**State 3: Session Complete**
```
┌─────────────────────────────────────────────────────────────┐
│                    🎉 Session Complete!                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                        Great job!                           │
│                                                             │
│     ┌─────────────────────────────────────────────────┐     │
│     │                                                 │     │
│     │              📚 15 words reviewed               │     │
│     │                                                 │     │
│     │      ✅ 12 correct        ❌ 3 wrong            │     │
│     │                                                 │     │
│     │              🏆 +45 XP earned                   │     │
│     │                                                 │     │
│     │              ⏱️ 4 minutes                       │     │
│     │                                                 │     │
│     └─────────────────────────────────────────────────┘     │
│                                                             │
│                                                             │
│     ┌───────────────┐         ┌───────────────┐            │
│     │ Review Again  │         │   Go Home     │            │
│     └───────────────┘         └───────────────┘            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Code

```typescript
// VocabularyReview.tsx
import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  useGetDueReviewsQuery,
  useSubmitReviewMutation
} from '../../../store/slices/learningSlice';
import Flashcard from './Flashcard';
import ProgressBar from '../shared/ProgressBar';
import './VocabularyReview.scss';

interface ReviewStats {
  total: number;
  correct: number;
  wrong: number;
  xpEarned: number;
  startTime: number;
}

const VocabularyReview: React.FC = () => {
  const navigate = useNavigate();
  const [currentIndex, setCurrentIndex] = useState(0);
  const [showAnswer, setShowAnswer] = useState(false);
  const [isComplete, setIsComplete] = useState(false);
  const [stats, setStats] = useState<ReviewStats>({
    total: 0,
    correct: 0,
    wrong: 0,
    xpEarned: 0,
    startTime: Date.now()
  });

  const { data: reviewsData, isLoading, refetch } = useGetDueReviewsQuery({ limit: 20 });
  const [submitReview] = useSubmitReviewMutation();

  const reviews = reviewsData?.data || [];
  const currentWord = reviews[currentIndex];
  const progress = reviews.length > 0 ? ((currentIndex) / reviews.length) * 100 : 0;

  useEffect(() => {
    if (reviews.length > 0) {
      setStats(prev => ({ ...prev, total: reviews.length }));
    }
  }, [reviews.length]);

  const handleShowAnswer = useCallback(() => {
    setShowAnswer(true);
  }, []);

  const handleAnswer = useCallback(async (correct: boolean) => {
    const responseTime = Date.now() - stats.startTime;

    try {
      await submitReview({
        vocabularyId: currentWord._id,
        correct,
        responseTime
      }).unwrap();

      setStats(prev => ({
        ...prev,
        correct: correct ? prev.correct + 1 : prev.correct,
        wrong: !correct ? prev.wrong + 1 : prev.wrong,
        xpEarned: prev.xpEarned + (correct ? 5 : 1)
      }));

      // Move to next word or complete
      if (currentIndex + 1 >= reviews.length) {
        setIsComplete(true);
      } else {
        setCurrentIndex(prev => prev + 1);
        setShowAnswer(false);
      }
    } catch (error) {
      console.error('Failed to submit review:', error);
    }
  }, [currentWord, currentIndex, reviews.length, submitReview, stats.startTime]);

  const handleEndSession = () => {
    if (window.confirm('End review session?')) {
      setIsComplete(true);
    }
  };

  const handleReviewAgain = () => {
    setCurrentIndex(0);
    setShowAnswer(false);
    setIsComplete(false);
    setStats({
      total: 0,
      correct: 0,
      wrong: 0,
      xpEarned: 0,
      startTime: Date.now()
    });
    refetch();
  };

  const getSessionDuration = () => {
    const duration = Math.floor((Date.now() - stats.startTime) / 1000 / 60);
    return duration < 1 ? 'Less than a minute' : `${duration} minutes`;
  };

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyPress = (e: KeyboardEvent) => {
      if (isComplete) return;

      if (e.code === 'Space' && !showAnswer) {
        e.preventDefault();
        handleShowAnswer();
      } else if (showAnswer) {
        if (e.code === 'ArrowLeft' || e.key === '1') {
          handleAnswer(false);
        } else if (e.code === 'ArrowRight' || e.key === '2') {
          handleAnswer(true);
        }
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [showAnswer, isComplete, handleShowAnswer, handleAnswer]);

  if (isLoading) {
    return <div className="loading-screen">Loading reviews...</div>;
  }

  if (reviews.length === 0) {
    return (
      <div className="empty-review">
        <h2>All caught up! 🎉</h2>
        <p>No words due for review right now.</p>
        <button onClick={() => navigate('/learn')}>Go to Dashboard</button>
      </div>
    );
  }

  if (isComplete) {
    return (
      <div className="review-complete">
        <div className="complete-header">
          <span className="emoji">🎉</span>
          <h1>Session Complete!</h1>
          <p>Great job!</p>
        </div>

        <div className="stats-card">
          <div className="stat-row">
            <span className="stat-icon">📚</span>
            <span className="stat-text">{stats.total} words reviewed</span>
          </div>
          <div className="stat-row">
            <span className="stat-icon">✅</span>
            <span className="stat-text correct">{stats.correct} correct</span>
            <span className="stat-icon">❌</span>
            <span className="stat-text wrong">{stats.wrong} wrong</span>
          </div>
          <div className="stat-row">
            <span className="stat-icon">🏆</span>
            <span className="stat-text">+{stats.xpEarned} XP earned</span>
          </div>
          <div className="stat-row">
            <span className="stat-icon">⏱️</span>
            <span className="stat-text">{getSessionDuration()}</span>
          </div>
        </div>

        <div className="complete-actions">
          <button onClick={handleReviewAgain} className="review-again-btn">
            Review Again
          </button>
          <button onClick={() => navigate('/learn')} className="go-home-btn">
            Go Home
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="vocabulary-review">
      {/* Header */}
      <header className="review-header">
        <h1>Review</h1>
        <span className="progress-text">{currentIndex + 1}/{reviews.length}</span>
        <button onClick={handleEndSession} className="end-btn">
          ✕ End Session
        </button>
      </header>

      {/* Progress Bar */}
      <div className="progress-container">
        <ProgressBar current={currentIndex} total={reviews.length} />
      </div>

      {/* Flashcard */}
      <div className="flashcard-container">
        <Flashcard
          word={currentWord}
          showAnswer={showAnswer}
          onFlip={handleShowAnswer}
        />
      </div>

      {/* Actions */}
      <div className="review-actions">
        {!showAnswer ? (
          <>
            <p className="hint">Tap card or press Space to reveal</p>
            <button onClick={handleShowAnswer} className="show-answer-btn">
              Show Answer
            </button>
          </>
        ) : (
          <>
            <p className="hint">How well did you remember this?</p>
            <div className="answer-buttons">
              <button onClick={() => handleAnswer(false)} className="wrong-btn">
                <span className="btn-icon">❌</span>
                <span className="btn-text">Wrong</span>
              </button>
              <button onClick={() => handleAnswer(true)} className="correct-btn">
                <span className="btn-icon">✅</span>
                <span className="btn-text">Correct</span>
              </button>
            </div>
            <p className="keyboard-hint">
              Keyboard: ← Wrong | → Correct
            </p>
          </>
        )}
      </div>
    </div>
  );
};

export default VocabularyReview;
```

### Flashcard Component

```typescript
// Flashcard.tsx
import React from 'react';
import './Flashcard.scss';

interface FlashcardProps {
  word: {
    word: string;
    translation: string;
    language: string;
    pronunciation?: string;
    exampleSentence?: string;
    exampleTranslation?: string;
  };
  showAnswer: boolean;
  onFlip: () => void;
}

const getLanguageFlag = (code: string) => {
  const flags: Record<string, string> = {
    ko: '🇰🇷', ja: '🇯🇵', zh: '🇨🇳', es: '🇪🇸', fr: '🇫🇷',
    de: '🇩🇪', it: '🇮🇹', pt: '🇵🇹', ru: '🇷🇺', en: '🇺🇸'
  };
  return flags[code] || '🌐';
};

const Flashcard: React.FC<FlashcardProps> = ({ word, showAnswer, onFlip }) => {
  return (
    <div
      className={`flashcard ${showAnswer ? 'flipped' : ''}`}
      onClick={!showAnswer ? onFlip : undefined}
    >
      <div className="flashcard-inner">
        {/* Front - Question */}
        <div className="flashcard-front">
          <div className="word-display">
            <h2 className="word">{word.word}</h2>
            <span className="language">
              {getLanguageFlag(word.language)} {word.language.toUpperCase()}
            </span>
          </div>
        </div>

        {/* Back - Answer */}
        <div className="flashcard-back">
          <div className="answer-content">
            <h2 className="word">{word.word}</h2>
            <div className="divider" />
            <h3 className="translation">{word.translation}</h3>

            {word.pronunciation && (
              <p className="pronunciation">"{word.pronunciation}"</p>
            )}

            {word.exampleSentence && (
              <div className="example">
                <p className="example-native">{word.exampleSentence}</p>
                {word.exampleTranslation && (
                  <p className="example-translation">{word.exampleTranslation}</p>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Flashcard;
```

### SCSS Styles

```scss
// Flashcard.scss
.flashcard {
  width: 100%;
  max-width: 400px;
  height: 300px;
  perspective: 1000px;
  cursor: pointer;
  margin: 0 auto;

  .flashcard-inner {
    width: 100%;
    height: 100%;
    position: relative;
    transition: transform 0.6s;
    transform-style: preserve-3d;
  }

  &.flipped .flashcard-inner {
    transform: rotateY(180deg);
  }

  .flashcard-front,
  .flashcard-back {
    position: absolute;
    width: 100%;
    height: 100%;
    backface-visibility: hidden;
    border-radius: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  }

  .flashcard-front {
    background: linear-gradient(135deg, #00BFA5 0%, #008E76 100%);
    color: white;

    .word-display {
      text-align: center;

      .word {
        font-size: 36px;
        font-weight: 700;
        margin-bottom: 16px;
      }

      .language {
        font-size: 16px;
        opacity: 0.9;
      }
    }
  }

  .flashcard-back {
    background: white;
    transform: rotateY(180deg);
    border: 2px solid #00BFA5;

    .answer-content {
      text-align: center;
      width: 100%;

      .word {
        font-size: 24px;
        color: #00BFA5;
        margin-bottom: 8px;
      }

      .divider {
        width: 60px;
        height: 2px;
        background: #00BFA5;
        margin: 8px auto;
      }

      .translation {
        font-size: 28px;
        color: #1a1a1a;
        margin-bottom: 12px;
      }

      .pronunciation {
        font-size: 16px;
        color: #666;
        font-style: italic;
        margin-bottom: 16px;
      }

      .example {
        margin-top: 16px;
        padding-top: 16px;
        border-top: 1px solid #e0e0e0;

        .example-native {
          font-size: 14px;
          color: #333;
          margin-bottom: 4px;
        }

        .example-translation {
          font-size: 13px;
          color: #666;
        }
      }
    }
  }
}
```

---

## Screen 5: Lessons List

**Route:** `/learn/lessons`
**File:** `src/components/learning/Lessons/LessonsList.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Lessons                                          │
├─────────────────────────────────────────────────────────────┤
│  Language: [Korean ▼]     Level: [All ▼]                   │
├─────────────────────────────────────────────────────────────┤
│  Category: [All] [Grammar] [Vocabulary] [Conversation]      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Continue Learning                                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🇰🇷                                                 │    │
│  │ Korean Basics - Lesson 3                            │    │
│  │ Greetings and Introductions                         │    │
│  │                                                     │    │
│  │ ████████░░░░ 65%                    [Continue →]    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Beginner                                                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ ✓ Completed │ │ ✓ Completed │ │ 🔒 Locked   │           │
│  │ Hangul 1    │ │ Hangul 2    │ │ Hangul 3    │           │
│  │ ★★★★★     │ │ ★★★★☆     │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
│  ┌─────────────┐ ┌─────────────┐                           │
│  │ ◐ Progress  │ │ ○ Not Start │                           │
│  │ Greetings   │ │ Numbers     │                           │
│  │ 65%         │ │             │                           │
│  └─────────────┘ └─────────────┘                           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Intermediate                                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ 🔒 Locked   │ │ 🔒 Locked   │ │ 🔒 Locked   │           │
│  │ Grammar 1   │ │ Verbs       │ │ Honorifics  │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Lesson Card States

```
Completed:        In Progress:      Not Started:      Locked:
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│     ✓     │     │     ◐     │     │     ○     │     │     🔒    │
│ Lesson 1  │     │ Lesson 3  │     │ Lesson 5  │     │ Lesson 7  │
│ ★★★★★   │     │ ████░ 65% │     │           │     │           │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
   Green            Teal              Gray              Dark Gray
```

---

## Screen 6: Lesson Detail/Player

**Route:** `/learn/lessons/:lessonId`
**File:** `src/components/learning/Lessons/LessonPlayer.tsx`

### Lesson Flow

```
Introduction → Content → Exercise 1 → Exercise 2 → ... → Summary → Complete
```

### UI States

**Introduction Screen:**
```
┌─────────────────────────────────────────────────────────────┐
│  [X Close]                                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                          🇰🇷                                │
│                                                             │
│                Korean Greetings                             │
│                      Lesson 3                               │
│                                                             │
│              Learn common greetings and                     │
│              how to introduce yourself                      │
│                                                             │
│     ┌────────────────────────────────────────┐              │
│     │  📚 5 new words                        │              │
│     │  📝 4 exercises                        │              │
│     │  ⏱️ ~10 minutes                        │              │
│     │  🏆 +30 XP                             │              │
│     └────────────────────────────────────────┘              │
│                                                             │
│                                                             │
│                  [Start Lesson →]                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Content Screen:**
```
┌─────────────────────────────────────────────────────────────┐
│  Lesson 3                              ████░░░░░ 2/6        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                        안녕하세요                            │
│                     (an-nyeong-ha-se-yo)                    │
│                                                             │
│                    🔊 [Play Audio]                          │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│                         Hello                               │
│                   (formal greeting)                         │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  📝 Note:                                                   │
│  This is the most common formal greeting in Korean.         │
│  Use it when meeting someone for the first time or          │
│  with people older than you.                                │
│                                                             │
│                                                             │
│  [← Previous]                             [Continue →]      │
└─────────────────────────────────────────────────────────────┘
```

**Exercise: Multiple Choice**
```
┌─────────────────────────────────────────────────────────────┐
│  Lesson 3                              ██████░░░ 4/6        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│            What does "안녕하세요" mean?                      │
│                                                             │
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │  A) Goodbye                                 │         │
│     └─────────────────────────────────────────────┘         │
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │  B) Hello                              ✓    │ ← Selected
│     └─────────────────────────────────────────────┘         │
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │  C) Thank you                               │         │
│     └─────────────────────────────────────────────┘         │
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │  D) Sorry                                   │         │
│     └─────────────────────────────────────────────┘         │
│                                                             │
│                                                             │
│                                       [Check Answer]        │
└─────────────────────────────────────────────────────────────┘
```

**Exercise: Fill in the Blank**
```
┌─────────────────────────────────────────────────────────────┐
│  Lesson 3                              ███████░░ 5/6        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│            Complete the sentence:                           │
│                                                             │
│            ________, 저는 John입니다.                        │
│            (Hello, I am John.)                              │
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │                                             │         │
│     └─────────────────────────────────────────────┘         │
│                                                             │
│     Word Bank:                                              │
│     [안녕하세요] [감사합니다] [미안해요] [네]               │
│                                                             │
│                                                             │
│                                       [Check Answer]        │
└─────────────────────────────────────────────────────────────┘
```

**Lesson Complete:**
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                         🎉                                  │
│                                                             │
│                   Lesson Complete!                          │
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │                                             │         │
│     │            Score: 90%                       │         │
│     │         ★★★★★ (5 stars)                   │         │
│     │                                             │         │
│     │            4/4 correct                      │         │
│     │            +35 XP earned                    │         │
│     │                                             │         │
│     │     🔓 New words added to vocabulary        │         │
│     │                                             │         │
│     └─────────────────────────────────────────────┘         │
│                                                             │
│     ┌───────────────┐         ┌───────────────┐            │
│     │ Review Words  │         │ Next Lesson → │            │
│     └───────────────┘         └───────────────┘            │
│                                                             │
│                     [Back to Lessons]                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 7: Quizzes List

**Route:** `/learn/quizzes`
**File:** `src/components/learning/Quizzes/QuizzesList.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Quizzes                                          │
├─────────────────────────────────────────────────────────────┤
│  [Daily] [Weekly] [Topic] [Custom]                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Daily Challenge                                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🎯 Today's Quiz                                     │    │
│  │ Test your knowledge with 10 random questions        │    │
│  │                                                     │    │
│  │ 🏆 +50 XP  •  ⏱️ 5 min  •  10 questions            │    │
│  │                                                     │    │
│  │                              [Start Quiz →]         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Topic Quizzes                                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ 🇰🇷         │ │ 🇯🇵         │ │ 🇪🇸         │           │
│  │ Korean      │ │ Japanese    │ │ Spanish     │           │
│  │ Greetings   │ │ Hiragana    │ │ Numbers     │           │
│  │ 15 Q • +30  │ │ 20 Q • +40  │ │ 10 Q • +20  │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Recent Results                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Korean Greetings    │ 90% │ ★★★★★ │ 2h ago      │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ Daily Quiz          │ 75% │ ★★★★☆ │ Yesterday   │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ Japanese Hiragana   │ 85% │ ★★★★☆ │ 2 days ago  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 8: Quiz Player

**Route:** `/learn/quizzes/:quizId`
**File:** `src/components/learning/Quizzes/QuizPlayer.tsx`

Similar to Lesson Player but focused on assessment with:
- Timer countdown
- No hints or learning content
- Immediate feedback optional
- Final score summary

---

## Screen 9: Leaderboard

**Route:** `/learn/leaderboard`
**File:** `src/components/learning/Gamification/Leaderboard.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Leaderboard                                      │
├─────────────────────────────────────────────────────────────┤
│  [Daily] [Weekly] [Monthly] [All-Time]                      │
├─────────────────────────────────────────────────────────────┤
│  Language: [All ▼]                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│     ┌─────────────────────────────────────────────┐         │
│     │          🥇                                 │         │
│     │         ┌───┐                               │         │
│     │         │ 1 │  Sarah Kim                    │         │
│     │         └───┘  4,520 XP                     │         │
│     │    🥈         🥉                            │         │
│     │   ┌───┐     ┌───┐                           │         │
│     │   │ 2 │     │ 3 │                           │         │
│     │   └───┘     └───┘                           │         │
│     │ John D.   Alex P.                           │         │
│     │ 3,890 XP  3,450 XP                          │         │
│     └─────────────────────────────────────────────┘         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  4.  🖼️ Mike Johnson         2,890 XP                       │
│  5.  🖼️ Emma Wilson          2,650 XP                       │
│  6.  🖼️ David Lee            2,420 XP                       │
│  7.  🖼️ Lisa Chen            2,180 XP                       │
│  ─────────────────────────────────────────────────────────  │
│  23. 🖼️ You                  1,250 XP  ←                    │
│  ─────────────────────────────────────────────────────────  │
│  24. 🖼️ Tom Brown            1,220 XP                       │
│  25. 🖼️ Amy White            1,180 XP                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 10: Achievements

**Route:** `/learn/achievements`
**File:** `src/components/learning/Gamification/Achievements.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Achievements                     12/45 Unlocked  │
├─────────────────────────────────────────────────────────────┤
│  [All] [Unlocked] [Locked]                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Learning                                                   │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐        │
│  │ 🏅    │ │ 🏅    │ │ 🏅    │ │ 🔒    │ │ 🔒    │        │
│  │ First │ │ Word  │ │ Lesson│ │ Quiz  │ │ 100   │        │
│  │ Word  │ │ Master│ │ Done  │ │ Ace   │ │ Words │        │
│  └───────┘ └───────┘ └───────┘ └───────┘ └───────┘        │
│                                                             │
│  Streaks                                                    │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐        │
│  │ 🔥    │ │ 🔥    │ │ 🔒    │ │ 🔒    │ │ 🔒    │        │
│  │ 3 Day │ │ 7 Day │ │ 14 Day│ │ 30 Day│ │ 100Day│        │
│  │ Streak│ │ Streak│ │ Streak│ │ Streak│ │ Streak│        │
│  └───────┘ └───────┘ └───────┘ └───────┘ └───────┘        │
│                                                             │
│  Social                                                     │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐                   │
│  │ 🏅    │ │ 🔒    │ │ 🔒    │ │ 🔒    │                   │
│  │ Helper│ │ 10    │ │ 50    │ │ 100   │                   │
│  │       │ │Correct│ │Correct│ │Correct│                   │
│  └───────┘ └───────┘ └───────┘ └───────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Achievement Badge Component

```typescript
// AchievementBadge.tsx
interface Achievement {
  _id: string;
  name: string;
  description: string;
  icon: string;
  category: 'learning' | 'streak' | 'social' | 'special';
  earned: boolean;
  earnedAt?: Date;
  progress?: number;
  target?: number;
  xpReward: number;
}

interface AchievementBadgeProps {
  achievement: Achievement;
  size?: 'small' | 'medium' | 'large';
  onClick?: () => void;
}
```

---

## Screen 11: Challenges

**Route:** `/learn/challenges`
**File:** `src/components/learning/Gamification/Challenges.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Challenges                                       │
├─────────────────────────────────────────────────────────────┤
│  [Active] [Upcoming] [Completed]                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  This Week's Challenge                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🏆 Learn 50 New Words                               │    │
│  │                                                     │    │
│  │ Add and review 50 vocabulary words this week        │    │
│  │                                                     │    │
│  │ Progress: ██████████████░░░░░ 32/50                 │    │
│  │                                                     │    │
│  │ 🏅 Prize: +200 XP, Special Badge                    │    │
│  │ ⏱️ Ends: 3 days left                                │    │
│  │                                                     │    │
│  │ 1,234 participants  •  You're #45                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Community Challenges                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🇰🇷 Korean Masters                                  │    │
│  │ Score highest in Korean quizzes                     │    │
│  │ 892 joined  •  5 days left           [Join →]      │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🔥 Streak Warriors                                  │    │
│  │ Maintain a 14-day streak                            │    │
│  │ 2,341 joined  •  12 days left        [Joined ✓]    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 12: Daily Goals Settings

**Route:** `/learn/settings/goals`
**File:** `src/components/learning/Goals/GoalsSettings.tsx`

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]  Daily Goals                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Set your learning goals to stay motivated!                 │
│                                                             │
│  Daily XP Goal                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │    [10]  [20]  [30]  [50]  [Custom]                │    │
│  │            ▲                                        │    │
│  │         Selected                                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  📊 With 20 XP/day, you can:                               │
│     • Review ~15 vocabulary words                           │
│     • Complete 1 short lesson                               │
│     • Take 1 daily quiz                                     │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Weekly XP Goal                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │    [50]  [100]  [150]  [200]  [Custom]             │    │
│  │            ▲                                        │    │
│  │         Selected                                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Reminder Notifications                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Daily reminder              [Toggle ON]             │    │
│  │ Time: 8:00 PM               [Change]                │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                        [Save Changes]                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 13: Language Corrections

**File:** `src/components/learning/Corrections/CorrectionModal.tsx`

This is a modal that appears in the chat when correcting someone's message.

### UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Correct Message                                   [X]      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Original:                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ I goed to the store yesterday.                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Your Correction:                                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ I went to the store yesterday.                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Preview:                                                   │
│  "I [goed→went] to the store yesterday."                   │
│                                                             │
│  Explanation (optional):                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ "Went" is the past tense of "go". English uses      │    │
│  │ irregular verbs for common words like go/went.      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [Cancel]                              [Send Correction]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### CorrectionDiff Component

Shows the difference between original and corrected text:

```typescript
// CorrectionDiff.tsx
interface CorrectionDiffProps {
  original: string;
  corrected: string;
}

// Output example:
// "I [goed→went] to the store yesterday."
// With styling: struck-through red for removed, green for added
```

---

## Components Library

### Shared Components for Learning Module

```typescript
// ProgressBar.tsx
interface ProgressBarProps {
  current: number;
  total: number;
  color?: 'primary' | 'success' | 'warning';
  showLabel?: boolean;
  height?: number;
}

// StreakCounter.tsx
interface StreakCounterProps {
  streak: number;
  showFlame?: boolean;
  size?: 'small' | 'medium' | 'large';
}

// XPDisplay.tsx
interface XPDisplayProps {
  xp: number;
  showIcon?: boolean;
  animated?: boolean;
}

// LevelBadge.tsx
interface LevelBadgeProps {
  level: number;
  progress?: number; // progress to next level
}

// LanguageSelector.tsx
interface LanguageSelectorProps {
  value: string;
  onChange: (code: string) => void;
  multiple?: boolean;
  placeholder?: string;
}

// Timer.tsx
interface TimerProps {
  seconds: number;
  onComplete?: () => void;
  paused?: boolean;
}

// StarRating.tsx
interface StarRatingProps {
  score: number; // 0-100
  maxStars?: number; // default 5
  size?: 'small' | 'medium' | 'large';
}
```

---

## State Management

### Local State (Component Level)

```typescript
// For Review Session
interface ReviewSessionState {
  currentIndex: number;
  showAnswer: boolean;
  answers: Array<{ wordId: string; correct: boolean; time: number }>;
  startTime: number;
  isComplete: boolean;
}

// For Lesson Player
interface LessonPlayerState {
  currentStep: number;
  answers: Map<string, string | string[]>;
  startTime: number;
  isComplete: boolean;
}
```

### Redux State (Already in learningSlice)

RTK Query handles caching and server state automatically.

---

## Styling Guidelines

### Colors for Learning Module

```scss
// SRS Levels
$srs-new: #2196F3;        // Blue
$srs-apprentice: #FF9800; // Orange
$srs-guru: #9C27B0;       // Purple
$srs-master: #4CAF50;     // Green
$srs-burned: #4CAF50;     // Green (with checkmark)

// Achievement States
$achievement-locked: #9E9E9E;
$achievement-unlocked: #FFD700;
$achievement-rare: #7C4DFF;

// Progress
$progress-empty: #E0E0E0;
$progress-fill: #00BFA5;
$progress-complete: #4CAF50;

// Feedback
$answer-correct: #4CAF50;
$answer-wrong: #E53935;
$answer-selected: #00BFA5;
```

### Animation Keyframes

```scss
@keyframes xp-pop {
  0% { transform: scale(1); }
  50% { transform: scale(1.2); }
  100% { transform: scale(1); }
}

@keyframes streak-flame {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1) rotate(-5deg); }
}

@keyframes correct-flash {
  0% { background-color: transparent; }
  50% { background-color: rgba(76, 175, 80, 0.3); }
  100% { background-color: transparent; }
}

@keyframes wrong-shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}
```

---

## Testing Checklist

### Vocabulary
- [ ] Add new word with all fields
- [ ] Edit existing word
- [ ] Delete word with confirmation
- [ ] Filter by language/SRS level
- [ ] Search works correctly
- [ ] Pagination/infinite scroll

### Review
- [ ] Cards flip correctly
- [ ] Keyboard shortcuts work
- [ ] SRS level updates after answer
- [ ] Session stats accurate
- [ ] XP awarded correctly

### Lessons
- [ ] Progress saves correctly
- [ ] All exercise types work
- [ ] Audio playback works
- [ ] Completion stats accurate
- [ ] Words added to vocabulary

### Quizzes
- [ ] Timer works correctly
- [ ] Score calculated correctly
- [ ] Results saved

### Gamification
- [ ] Leaderboard updates
- [ ] Achievements unlock
- [ ] Challenges progress track
- [ ] Streak counts correctly

---

## API Error Handling

```typescript
// Common error handling pattern
const { data, error, isLoading, refetch } = useGetVocabularyQuery();

if (isLoading) {
  return <LoadingSpinner />;
}

if (error) {
  return (
    <ErrorState
      message="Failed to load vocabulary"
      onRetry={refetch}
    />
  );
}
```

---

## Performance Tips

1. **Virtualize long lists** - Use react-window for vocabulary lists
2. **Lazy load lessons** - Don't load all lesson content upfront
3. **Cache audio files** - Use service worker for offline audio
4. **Debounce search** - Wait 300ms before API call
5. **Optimistic updates** - Update UI before API confirms

---

## Contact

For questions about the Learning module implementation, contact the development team.
