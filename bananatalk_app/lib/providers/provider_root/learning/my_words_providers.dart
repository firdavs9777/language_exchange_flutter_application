import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/study/my_words.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/study/my_words_api.dart';

/// The learner's words and mistakes. [MyWords.empty], with no request, while
/// the server switch is off.
final myWordsProvider = FutureProvider.autoDispose<MyWords>((ref) async {
  if (!ref.watch(studyFromChatsEnabledProvider)) return MyWords.empty;
  return ref.read(myWordsApiProvider).fetch();
});
