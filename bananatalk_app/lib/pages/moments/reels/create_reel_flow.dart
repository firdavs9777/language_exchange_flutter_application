import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/pages/moments/reels/reel_policy_dialog.dart';

/// Thin orchestrator over the existing composer/editor pieces (Workstream
/// G, Task 6): enforces the one-time content-policy gate before the first
/// reel post, then hands off to [CreateMoment] in `isReel` mode, which
/// re-enables its video button/preview, prompts for record-or-gallery
/// immediately, caps the trim/compression at 180s, and posts with
/// `isReel: true` (+ `promptId` when prompt-launched).
///
/// The record/gallery -> trim/filter editor -> caption+language -> upload
/// pipeline itself is entirely the composer's existing pipeline — nothing
/// new is duplicated here, per the plan's "thin orchestrator" framing.
class CreateReelFlow extends ConsumerStatefulWidget {
  const CreateReelFlow({
    super.key,
    this.prefillPrompt,
    this.prefillPromptId,
    this.prefillLanguage,
  });

  /// Prompt text shown as context (see `CreateMoment`'s reel-mode prefill —
  /// it's displayed via the dismissible prompt chip, not written into the
  /// caption, since a reel is the user's own spoken answer).
  final String? prefillPrompt;
  final String? prefillPromptId;

  /// ISO 639-1 language code to default the composer's language dropdown
  /// to (the prompt's language when prompt-launched).
  final String? prefillLanguage;

  @override
  ConsumerState<CreateReelFlow> createState() => _CreateReelFlowState();
}

class _CreateReelFlowState extends ConsumerState<CreateReelFlow> {
  bool _checking = true;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    // The policy gate also guards the grid (Task 4), but a user can reach
    // this flow directly from the prompt-of-day card without ever opening
    // the Reels tab, so it must be checked here too.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPolicy());
  }

  Future<void> _checkPolicy() async {
    final accepted = await ReelPolicyGate.ensureAccepted(context, ref);
    if (!mounted) return;
    if (!accepted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _checking = false;
      _accepted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_accepted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CreateMoment(
      isReel: true,
      prefillPrompt: widget.prefillPrompt,
      prefillPromptId: widget.prefillPromptId,
      prefillLanguage: widget.prefillLanguage,
    );
  }
}
