import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:bananatalk_app/providers/tutor_provider.dart' show tutorMemoryAndQuotasProvider;
import 'package:bananatalk_app/widgets/tutor/tutor_quota_indicator.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Describe-a-photo exercise.
///
/// Stage 1: pick an image → backend returns a target-language prompt
///          + visible vocab.
/// Stage 2: user writes a description → backend grades it → result
///          card with score, feedback, grammar notes, missing items.
class ImageVocabScreen extends ConsumerStatefulWidget {
  const ImageVocabScreen({super.key});

  @override
  ConsumerState<ImageVocabScreen> createState() => _ImageVocabScreenState();
}

enum _Stage { pick, describe, grading, result }

class _ImageVocabScreenState extends ConsumerState<ImageVocabScreen> {
  final _picker = ImagePicker();
  final _descCtl = TextEditingController();

  _Stage _stage = _Stage.pick;
  XFile? _image;
  String? _prompt;
  List<Map<String, String>> _suggestedVocab = const [];

  // Grading result fields
  int? _score;
  String? _feedback;
  List<Map<String, String>> _grammarNotes = const [];
  List<String> _missingItems = const [];

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _descCtl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        _image = picked;
        _loading = true;
        _error = null;
      });
      await _requestPrompt();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _error = l10n.aiTutorImagePickError(e.toString());
      });
    }
  }

  Future<void> _requestPrompt() async {
    if (_image == null) return;
    try {
      final body = await _postImage('tutor/image-vocab/describe');
      // Step 13A: refresh quota state after the gated action succeeded.
      ref.invalidate(tutorMemoryAndQuotasProvider);
      if (!mounted) return;
      setState(() {
        _prompt = (body['prompt'] as String?) ?? 'Describe what you see.';
        _suggestedVocab = ((body['suggestedVocab'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => {
                  'word': (m['word'] ?? '').toString(),
                  'definition': (m['definition'] ?? '').toString(),
                })
            .toList();
        _stage = _Stage.describe;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitDescription() async {
    if (_image == null || _descCtl.text.trim().isEmpty) return;
    setState(() {
      _stage = _Stage.grading;
      _loading = true;
      _error = null;
    });
    try {
      final body = await _postImage(
        'tutor/image-vocab/grade',
        fields: {'description': _descCtl.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _score = (body['score'] as num?)?.toInt() ?? 0;
        _feedback = (body['feedback'] as String?) ?? '';
        _grammarNotes = ((body['grammarNotes'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => {
                  'wrong': (m['wrong'] ?? '').toString(),
                  'correct': (m['correct'] ?? '').toString(),
                  'note': (m['note'] ?? '').toString(),
                })
            .toList();
        _missingItems = ((body['missingItems'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
        _stage = _Stage.result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.describe;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Multipart POST via ApiClient — auth header + token refresh come
  /// for free. Unwraps the {success, data} envelope.
  Future<Map<String, dynamic>> _postImage(
    String endpoint, {
    Map<String, String> fields = const {},
  }) async {
    final file = await http.MultipartFile.fromPath(
      'image',
      _image!.path,
      filename: _image!.name,
    );
    final res = await ApiClient().postMultipart(
      endpoint,
      fields: fields,
      files: [file],
    );
    if (!res.success || res.data == null) {
      throw StateError(res.error ?? 'Request failed');
    }
    final raw = res.data;
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return const {};
  }

  void _retry() {
    setState(() {
      _stage = _Stage.pick;
      _image = null;
      _prompt = null;
      _suggestedVocab = const [];
      _descCtl.clear();
      _score = null;
      _feedback = null;
      _grammarNotes = const [];
      _missingItems = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiTutorImageVocabTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: TutorQuotaIndicator(featureKey: 'photo')),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_stage) {
            _Stage.pick => _PickStage(
                loading: _loading,
                error: _error,
                onCamera: () => _pick(ImageSource.camera),
                onGallery: () => _pick(ImageSource.gallery),
              ),
            _Stage.describe => _DescribeStage(
                image: _image!,
                prompt: _prompt ?? '',
                suggestedVocab: _suggestedVocab,
                controller: _descCtl,
                onSubmit: _submitDescription,
                onRetry: _retry,
                error: _error,
              ),
            _Stage.grading => const Center(child: CircularProgressIndicator()),
            _Stage.result => _ResultStage(
                image: _image!,
                description: _descCtl.text,
                score: _score!,
                feedback: _feedback ?? '',
                grammarNotes: _grammarNotes,
                missingItems: _missingItems,
                onTryAnother: _retry,
              ),
          },
        ),
      ),
    );
  }
}

class _PickStage extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _PickStage({
    required this.loading,
    required this.error,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📷', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(l10n.aiTutorImagePickHeader,
            style: context.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          l10n.aiTutorImagePickSubtitle,
          textAlign: TextAlign.center,
          style: context.bodySmall.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 220,
          height: 48,
          child: FilledButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera),
            label: Text(l10n.aiTutorImagePickCamera),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 220,
          height: 48,
          child: FilledButton.tonalIcon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library),
            label: Text(l10n.aiTutorImagePickGallery),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!,
              style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _DescribeStage extends StatelessWidget {
  final XFile image;
  final String prompt;
  final List<Map<String, String>> suggestedVocab;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final String? error;
  const _DescribeStage({
    required this.image,
    required this.prompt,
    required this.suggestedVocab,
    required this.controller,
    required this.onSubmit,
    required this.onRetry,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: AppRadius.borderMD,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.file(File(image.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderMD,
              ),
              child: Text(prompt,
                  style: context.bodyLarge
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            if (suggestedVocab.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in suggestedVocab)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        v['definition']?.isNotEmpty == true
                            ? '${v['word']} (${v['definition']})'
                            : v['word'] ?? '',
                        style: context.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              minLines: 4,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.aiTutorImageDescriptionHint,
                hintStyle: TextStyle(color: context.textMuted),
                filled: true,
                fillColor: context.containerColor,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderMD,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    child: Text(l10n.aiTutorImageDifferentPhoto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onSubmit,
                    child: Text(l10n.aiTutorImageSubmit),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultStage extends StatelessWidget {
  final XFile image;
  final String description;
  final int score;
  final String feedback;
  final List<Map<String, String>> grammarNotes;
  final List<String> missingItems;
  final VoidCallback onTryAnother;
  const _ResultStage({
    required this.image,
    required this.description,
    required this.score,
    required this.feedback,
    required this.grammarNotes,
    required this.missingItems,
    required this.onTryAnother,
  });

  Color _scoreColor() {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: AppRadius.borderMD,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.file(File(image.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$score/100',
              style: context.titleLarge.copyWith(
                color: _scoreColor(),
                fontWeight: FontWeight.w800,
                fontSize: 44,
              ),
            ),
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(feedback, style: context.bodyMedium),
          ],
          if (grammarNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.aiTutorImageGrammarNotes,
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final g in grammarNotes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g['wrong'] ?? '',
                      style: context.bodyMedium.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      g['correct'] ?? '',
                      style: context.bodyMedium.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((g['note'] ?? '').isNotEmpty)
                      Text(g['note'] ?? '',
                          style: context.bodySmall
                              .copyWith(color: context.textMuted, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
          ],
          if (missingItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.aiTutorImageThingsYouMissed,
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in missingItems)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(s,
                        style: context.bodySmall.copyWith(color: Colors.orange.shade900)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onTryAnother,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.aiTutorImageTryAnother),
            ),
          ),
        ],
      ),
    );
  }
}
