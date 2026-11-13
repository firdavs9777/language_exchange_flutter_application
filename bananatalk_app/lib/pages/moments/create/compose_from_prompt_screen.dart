import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The prompt to fill the composer with: today's prompt only when its id is
/// the one asked for, else none. Pure.
({String text, String id})? promptToPrefill(
  Map<String, dynamic>? today,
  String? requestedId,
) {
  if (today == null || requestedId == null || requestedId.isEmpty) return null;
  final id = today['promptId']?.toString();
  final text = today['text'];
  if (id != requestedId || text is! String || text.isEmpty) return null;
  return (text: text, id: id!);
}

/// `/moments/compose?promptId=<id>` (the daily_prompt push). Opens the
/// moment composer with today's prompt filled in when its id matches; when
/// the prompt cannot be fetched or has moved on, a plain composer. A signed
/// out visitor (no stored token) is sent to the login screen.
class ComposeFromPromptScreen extends ConsumerStatefulWidget {
  const ComposeFromPromptScreen({super.key, this.promptId});

  final String? promptId;

  @override
  ConsumerState<ComposeFromPromptScreen> createState() =>
      _ComposeFromPromptScreenState();
}

class _ComposeFromPromptScreenState
    extends ConsumerState<ComposeFromPromptScreen> {
  late final Future<Map<String, dynamic>?> _today = _fetch();

  Future<Map<String, dynamic>?> _fetch() async {
    final id = widget.promptId;
    if (id == null || id.isEmpty) return null;
    try {
      // Straight from the service: promptOfDayProvider is cached for the life
      // of the app and may hold yesterday's prompt. The server derives the
      // language from the profile, so the push's `language` is not needed.
      return await ref
          .read(momentsServiceProvider)
          .getPromptOfDay()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  /// Signed in = a stored token (the one the services send), not the
  /// in-memory flag: on a cold start from the push that flag only turns true
  /// after the token is validated over the network.
  late final Future<bool> _signedIn = _hasStoredToken();

  Future<bool> _hasStoredToken() async {
    if (ref.read(authServiceProvider).isLoggedIn) return true;
    try {
      final token = (await SharedPreferences.getInstance()).getString('token');
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _signedIn.then((signedIn) {
      if (!signedIn && mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _signedIn,
      builder: (context, signedIn) {
        if (signedIn.data != true) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: _today,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final prompt = promptToPrefill(snapshot.data, widget.promptId);
            if (prompt == null) return const CreateMoment();
            return CreateMoment(
              prefillPrompt: prompt.text,
              prefillPromptId: prompt.id,
            );
          },
        );
      },
    );
  }
}
