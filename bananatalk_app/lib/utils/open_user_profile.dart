import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Opens a person's profile from anywhere (room messages, member lists).
/// The full profile is fetched by id; [fallback] (e.g. the partial sender
/// embedded in a message) is shown if that fails, so a tap never dead-ends.
Future<void> openUserProfile(
  BuildContext context,
  String userId, {
  Community? fallback,
}) async {
  if (userId.isEmpty) return;
  Community? community = fallback;
  try {
    final full = await ProviderScope.containerOf(context, listen: false)
        .read(communityServiceProvider)
        .getSingleCommunity(id: userId);
    if (full != null) community = full;
  } catch (_) {}
  if (community == null || !context.mounted) return;
  await Navigator.push(
    context,
    AppPageRoute(builder: (_) => SingleCommunity(community: community!)),
  );
}
