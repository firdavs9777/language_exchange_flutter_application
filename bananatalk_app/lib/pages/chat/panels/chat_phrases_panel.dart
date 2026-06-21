import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/panels/data/chat_topics.dart';
import 'package:bananatalk_app/pages/chat/panels/saved_phrases_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// HelloTalk-style phrase + topic panel that lives below the chat composer.
///
/// Tabs:
///   * Most Used — user-saved phrases (SharedPreferences). Tap inserts the
///     phrase into the composer; long-press shows a delete option. A
///     floating "+ Add a phrase" pill opens an inline editor sheet.
///   * Topics — server-curated icebreakers from [ChatTopics]. Tap inserts
///     the topic into the composer; the floating "↻ Change" pill shuffles
///     to a fresh batch.
class ChatPhrasesPanel extends ConsumerStatefulWidget {
  final AnimationController animationController;
  final void Function(String phrase) onSelectPhrase;

  const ChatPhrasesPanel({
    super.key,
    required this.animationController,
    required this.onSelectPhrase,
  });

  @override
  ConsumerState<ChatPhrasesPanel> createState() => _ChatPhrasesPanelState();
}

class _ChatPhrasesPanelState extends ConsumerState<ChatPhrasesPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<String> _savedPhrases = const [];
  List<String> _topics = ChatTopics.sample(seed: 1);
  bool _loadingSaved = true;
  int _shuffleCounter = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadSaved();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final userId = ref.read(userProvider).valueOrNull?.id ?? '';
    final list = await SavedPhrasesService.load(userId);
    if (!mounted) return;
    setState(() {
      _savedPhrases = list;
      _loadingSaved = false;
    });
  }

  Future<void> _addPhraseFlow() async {
    final userId = ref.read(userProvider).valueOrNull?.id ?? '';
    if (userId.isEmpty) return;
    final added = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPhraseSheet(),
    );
    if (added == null || added.trim().isEmpty) return;
    await SavedPhrasesService.add(userId, added);
    await _loadSaved();
  }

  Future<void> _deletePhrase(String phrase) async {
    final userId = ref.read(userProvider).valueOrNull?.id ?? '';
    if (userId.isEmpty) return;
    await SavedPhrasesService.remove(userId, phrase);
    await _loadSaved();
  }

  void _shuffleTopics() {
    _shuffleCounter++;
    setState(() {
      _topics = ChatTopics.sample(seed: _shuffleCounter * 2654435761);
    });
    HapticUtils.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeOutCubic,
      ),
      axisAlignment: -1,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          border: Border(
            top: BorderSide(color: context.dividerColor, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            _buildTabs(context, isDark),
            _buildHandle(isDark),
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildMostUsedList(context),
                      _buildTopicsList(context),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Center(child: _buildFloatingAction(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: context.textPrimary,
        unselectedLabelColor: context.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: l10n.chatPhrasesMostUsed),
          Tab(text: l10n.chatPhrasesTopics),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      width: 32,
      height: 3,
      margin: const EdgeInsets.only(top: 2, bottom: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMostUsedList(BuildContext context) {
    if (_loadingSaved) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_savedPhrases.isEmpty) {
      return _buildEmptyState(
        context,
        AppLocalizations.of(context)!.chatPhrasesEmptyMostUsed,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 72),
      itemCount: _savedPhrases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PhraseBubble(
        text: _savedPhrases[i],
        onTap: () => widget.onSelectPhrase(_savedPhrases[i]),
        onLongPress: () => _confirmDelete(_savedPhrases[i]),
      ),
    );
  }

  Widget _buildTopicsList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 72),
      itemCount: _topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PhraseBubble(
        text: _topics[i],
        onTap: () => widget.onSelectPhrase(_topics[i]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.bodyMedium.copyWith(color: context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildFloatingAction(BuildContext context) {
    final isMostUsed = _tabController.index == 0;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: isMostUsed ? _addPhraseFlow : _shuffleTopics,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMostUsed ? Icons.add_rounded : Icons.refresh_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isMostUsed ? l10n.chatPhrasesAddPhrase : l10n.chatPhrasesChange,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String phrase) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatPhrasesDeleteTitle),
        content: Text(phrase),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _deletePhrase(phrase);
    }
  }
}

/// Receiver-style bubble matching the incoming-message look in the
/// conversation list. Tap → insert into composer; long-press → host action.
class _PhraseBubble extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PhraseBubble({
    required this.text,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: context.bodyLarge.copyWith(fontSize: 14.5),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that captures a new phrase. Returns the entered text or null.
class _AddPhraseSheet extends StatefulWidget {
  const _AddPhraseSheet();

  @override
  State<_AddPhraseSheet> createState() => _AddPhraseSheetState();
}

class _AddPhraseSheetState extends State<_AddPhraseSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chatPhrasesAddTitle,
              style: context.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focus,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.chatPhrasesAddHint,
                hintStyle: TextStyle(color: context.textHint),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final value = _controller.text.trim();
                      if (value.isEmpty) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pop(value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
