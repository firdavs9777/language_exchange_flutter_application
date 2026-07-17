import 'package:bananatalk_app/models/learning/vocab_pack_model.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected level filter for the vocab-packs browser (null = all levels).
final vocabPackLevelFilterProvider = StateProvider<String?>((ref) => null);

/// List of packs for the current level filter.
final vocabPacksProvider =
    FutureProvider.family<List<VocabPackSummary>, String?>((ref, level) async {
  return LearningService.getVocabPacks(level: level);
});

/// Full detail (words + exercises) for a single pack.
final vocabPackDetailProvider =
    FutureProvider.family<VocabPack, String>((ref, id) async {
  return LearningService.getVocabPack(id);
});
