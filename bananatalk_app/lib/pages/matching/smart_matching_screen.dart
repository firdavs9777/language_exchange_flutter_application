import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/matching_provider.dart';
import 'package:bananatalk_app/models/matching/matching_model.dart';
import 'package:bananatalk_app/pages/matching/match_card_widget.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Smart Matching Screen for finding language partners
class SmartMatchingScreen extends ConsumerStatefulWidget {
  const SmartMatchingScreen({super.key});

  @override
  ConsumerState<SmartMatchingScreen> createState() =>
      _SmartMatchingScreenState();
}

class _SmartMatchingScreenState extends ConsumerState<SmartMatchingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(matchingTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              elevation: 0,
              backgroundColor: context.surfaceColor,
              floating: true,
              pinned: true,
              expandedHeight: 180,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        Spacing.gapSM,
                        Text(
                          l10n.findPartners,
                          style: context.displayMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Spacing.gapXS,
                        Text(
                          l10n.discoverLanguagePartners,
                          style: context.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: context.surfaceColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: l10n.recommended),
                      Tab(text: l10n.onlineNow),
                      Tab(text: l10n.byLanguage),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _RecommendationsTab(),
            _QuickMatchesTab(),
            _ByLanguageTab(),
          ],
        ),
      ),
    );
  }
}

/// Recommendations tab
class _RecommendationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(matchingRecommendationsProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return _buildEmptyState(context, l10n);
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(matchingRecommendationsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return MatchCard(
                match: matches[index],
                onTap: () => _navigateToProfile(context, matches[index]),
                onMessage: () => _navigateToChat(context, matches[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => _buildErrorState(
        context,
        l10n,
        () => ref.invalidate(matchingRecommendationsProvider),
      ),
    );
  }
}

/// Quick matches tab (online users)
class _QuickMatchesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(quickMatchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return _buildNoOnlineUsersState(context, l10n);
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(quickMatchesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return MatchCard(
                match: matches[index],
                onTap: () => _navigateToProfile(context, matches[index]),
                onMessage: () => _navigateToChat(context, matches[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => _buildErrorState(
        context,
        l10n,
        () => ref.invalidate(quickMatchesProvider),
      ),
    );
  }
}

/// By language tab
class _ByLanguageTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedLanguage = ref.watch(matchingLanguageFilterProvider);
    final languages = ref.watch(matchingLanguagesProvider);

    return Column(
      children: [
        // Language selector
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: selectedLanguage,
            decoration: InputDecoration(
              labelText: l10n.selectLanguage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.language),
            ),
            items: languages.map((lang) {
              return DropdownMenuItem(value: lang, child: Text(lang));
            }).toList(),
            onChanged: (value) {
              ref.read(matchingLanguageFilterProvider.notifier).state = value;
            },
          ),
        ),
        // Results
        Expanded(
          child: selectedLanguage == null
              ? _buildSelectLanguageState(context, l10n)
              : _LanguageMatchesList(language: selectedLanguage),
        ),
      ],
    );
  }
}

/// Language matches list
class _LanguageMatchesList extends ConsumerWidget {
  final String language;

  const _LanguageMatchesList({required this.language});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(matchByLanguageProvider(language));

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return _buildNoMatchesForLanguageState(context, l10n, language);
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(matchByLanguageProvider(language));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return MatchCard(
                match: matches[index],
                onTap: () => _navigateToProfile(context, matches[index]),
                onMessage: () => _navigateToChat(context, matches[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => _buildErrorState(
        context,
        l10n,
        () => ref.invalidate(matchByLanguageProvider(language)),
      ),
    );
  }
}

// Navigation helpers
void _navigateToProfile(BuildContext context, MatchRecommendation match) {
  // Navigate to user profile
  context.push('/profile/${match.odId}');
}

void _navigateToChat(BuildContext context, MatchRecommendation match) {
  // Navigate to chat with user
  context.push('/chat/${match.odId}');
}

// State widgets
Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.noMatchesFound, style: context.titleLarge),
        Spacing.gapSM,
        Text(l10n.tryAgainLater, style: context.bodySmall),
      ],
    ),
  );
}

Widget _buildNoOnlineUsersState(BuildContext context, AppLocalizations l10n) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off_outlined, size: 64, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.noUsersOnline, style: context.titleLarge),
        Spacing.gapSM,
        Text(l10n.checkBackLater, style: context.bodySmall),
      ],
    ),
  );
}

Widget _buildSelectLanguageState(BuildContext context, AppLocalizations l10n) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.language, size: 64, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.selectLanguagePrompt, style: context.titleLarge),
        Spacing.gapSM,
        Text(l10n.findPartnersByLanguage, style: context.bodySmall),
      ],
    ),
  );
}

Widget _buildNoMatchesForLanguageState(
  BuildContext context,
  AppLocalizations l10n,
  String language,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: context.textMuted),
        Spacing.gapLG,
        Text(l10n.noPartnersForLanguage(language), style: context.titleLarge),
        Spacing.gapSM,
        Text(l10n.tryAnotherLanguage, style: context.bodySmall),
      ],
    ),
  );
}

Widget _buildErrorState(
  BuildContext context,
  AppLocalizations l10n,
  VoidCallback onRetry,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: context.textMuted),
        Spacing.gapLG,
        Text(
          l10n.failedToLoadMatches,
          style: context.bodyMedium.copyWith(color: context.textSecondary),
        ),
        Spacing.gapLG,
        ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    ),
  );
}
