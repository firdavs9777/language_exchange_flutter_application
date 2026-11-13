import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/language_codes.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/language_names.dart';
import 'package:bananatalk_app/widgets/language_selection/show_language_picker.dart';

/// Shared look and helpers for the correction, quiz and word sticker editors
/// (same dark full-screen route as [PollStickerEditor]).
const Color kStickerEditorTeal = Color(0xFF00BFA5);

/// Length the way the server counts it: after trimming.
int trimmedLength(String text) => text.trim().length;

InputDecoration stickerFieldDecoration({
  required String hint,
  bool error = false,
}) {
  OutlineInputBorder border(Color? color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: color == null
        ? BorderSide.none
        : BorderSide(color: color, width: 1.5),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[500]),
    filled: true,
    fillColor: Colors.grey[900],
    counterText: '',
    border: error ? border(Colors.redAccent) : border(null),
    enabledBorder: error ? border(Colors.redAccent) : border(null),
    focusedBorder: border(error ? Colors.redAccent : kStickerEditorTeal),
  );
}

/// "12/300" counter that counts the trimmed text and turns red when over.
class StickerCounter extends StatelessWidget {
  const StickerCounter({super.key, required this.text, required this.max});

  final String text;
  final int max;

  @override
  Widget build(BuildContext context) {
    final n = trimmedLength(text);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 4),
        child: Text(
          '$n/$max',
          style: TextStyle(
            fontSize: 12,
            color: n > max ? Colors.redAccent : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

/// AppBar "Done" action shared by the editors; disabled until [enabled].
Widget stickerDoneAction(
  BuildContext context, {
  required String label,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return TextButton(
    onPressed: enabled ? onTap : null,
    child: Text(
      label,
      style: TextStyle(
        color: enabled ? kStickerEditorTeal : Colors.white30,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );
}

/// The sticker's language: flag + name, tap to change through the shared
/// language picker. Holds base ISO 639-1 codes (what the server stores);
/// null means "not set" and the sticker goes out without a language.
class StickerLanguageField extends StatelessWidget {
  const StickerLanguageField({
    super.key,
    required this.code,
    required this.onChanged,
  });

  final String? code;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showLanguagePickerSheet(context, currentCode: code);
    final base = picked == null
        ? null
        : LanguageCodes.toBaseIso6391(picked.code);
    if (base != null) onChanged(base);
  }

  @override
  Widget build(BuildContext context) {
    final c = code;
    return InkWell(
      key: const Key('sticker-language'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              c == null ? '🌐' : LanguageFlags.getFlag(c),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c == null ? '' : LanguageNames.of(context, c),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

/// A user's learning-language code reduced to the base code the server
/// accepts, or null when it cannot be represented.
String? stickerLanguageDefault(String? learningLanguage) =>
    learningLanguage == null || learningLanguage.trim().isEmpty
    ? null
    : LanguageCodes.toBaseIso6391(learningLanguage);
