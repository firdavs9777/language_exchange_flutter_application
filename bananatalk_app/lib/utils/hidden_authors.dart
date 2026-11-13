import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

/// [moments] without posts by [blocked] or [muted] authors: the client-side
/// filter every moments list applies (mute is local only; the block list
/// includes the remembered one when it cannot be fetched).
List<Moments> withoutHiddenAuthors(
  List<Moments> moments, {
  required Set<String> blocked,
  required Set<String> muted,
}) =>
    moments
        .where((m) => !blocked.contains(m.user.id) && !muted.contains(m.user.id))
        .toList();
