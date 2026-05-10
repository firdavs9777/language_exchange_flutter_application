// lib/providers/provider_root/learning_providers.dart
//
// Barrel re-export. Individual providers live under learning/ subfolder.
// Keeps existing import paths working without callsite changes.
//
// Note: learningServiceProvider does not exist as a standalone provider;
// LearningService is used directly (static methods) in each feature file.

export 'learning/progress_providers.dart';
export 'learning/vocabulary_providers.dart';
export 'learning/lessons_providers.dart';
export 'learning/quizzes_providers.dart';
export 'learning/challenges_providers.dart';
export 'learning/achievements_providers.dart';
export 'learning/leaderboard_providers.dart';
