import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/friendly_error.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/pages/chat/wallpaper/premium_wallpapers.dart';
import 'package:bananatalk_app/pages/chat/wallpaper/wallpaper_names.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

class WallpaperPickerScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String userName;
  final VoidCallback? onThemeChanged;

  const WallpaperPickerScreen({
    Key? key,
    required this.conversationId,
    required this.userName,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  ConsumerState<WallpaperPickerScreen> createState() =>
      _WallpaperPickerScreenState();
}

class _WallpaperPickerScreenState extends ConsumerState<WallpaperPickerScreen> {
  final ConversationService _conversationService = ConversationService();
  String? _selectedPreset;
  String? _customImagePath;
  bool _isLoading = false;
  bool _unlockingPremium = false;

  // Preset color themes - adapts to light/dark mode
  List<Map<String, dynamic>> _getPresets(bool isDark) => isDark
      ? [
          // Dark mode: all dark-friendly wallpapers
          {
            'name': 'default',
            'backgroundColor': AppColors.backgroundDark,
            'icon': Icons.brightness_auto,
          },
          {
            'name': 'dark',
            'backgroundColor': const Color(0xFF0D0D0D),
            'icon': Icons.dark_mode,
          },
          {
            'name': 'midnight',
            'backgroundColor': const Color(0xFF1A1A2E),
            'icon': Icons.nights_stay,
          },
          {
            'name': 'charcoal',
            'backgroundColor': const Color(0xFF2D2D2D),
            'icon': Icons.circle,
          },
          {
            'name': 'navy',
            'backgroundColor': const Color(0xFF0A1628),
            'icon': Icons.anchor,
          },
          {
            'name': 'ocean',
            'backgroundColor': const Color(0xFF1E3A5F),
            'icon': Icons.water,
          },
          {
            'name': 'teal',
            'backgroundColor': const Color(0xFF115E59),
            'icon': Icons.spa,
          },
          {
            'name': 'forest',
            'backgroundColor': const Color(0xFF1B4332),
            'icon': Icons.park,
          },
          {
            'name': 'sage',
            'backgroundColor': const Color(0xFF4A5D4A),
            'icon': Icons.eco,
          },
          {
            'name': 'wine',
            'backgroundColor': const Color(0xFF4A1942),
            'icon': Icons.wine_bar,
          },
          {
            'name': 'plum',
            'backgroundColor': const Color(0xFF5B2C6F),
            'icon': Icons.auto_awesome,
          },
          {
            'name': 'rose',
            'backgroundColor': const Color(0xFF5C1A3A),
            'icon': Icons.favorite,
          },
          {
            'name': 'mocha',
            'backgroundColor': const Color(0xFF4A3728),
            'icon': Icons.coffee,
          },
          {
            'name': 'slate',
            'backgroundColor': const Color(0xFF1E293B),
            'icon': Icons.layers,
          },
          {
            'name': 'ember',
            'backgroundColor': const Color(0xFF3B1A1A),
            'icon': Icons.local_fire_department,
          },
          {
            'name': 'deep_sea',
            'backgroundColor': const Color(0xFF0B2545),
            'icon': Icons.scuba_diving,
          },
        ]
      : [
          // Light mode: mix of light and medium wallpapers
          {
            'name': 'default',
            'backgroundColor': const Color(0xFFF5F5F5),
            'icon': Icons.brightness_auto,
          },
          {
            'name': 'cream',
            'backgroundColor': const Color(0xFFF5E6D3),
            'icon': Icons.light_mode,
          },
          {
            'name': 'blush',
            'backgroundColor': const Color(0xFFE8B4BC),
            'icon': Icons.favorite_border,
          },
          {
            'name': 'peach',
            'backgroundColor': const Color(0xFFE6A67C),
            'icon': Icons.wb_sunny,
          },
          {
            'name': 'sage',
            'backgroundColor': const Color(0xFF4A5D4A),
            'icon': Icons.eco,
          },
          {
            'name': 'ocean',
            'backgroundColor': const Color(0xFF1E3A5F),
            'icon': Icons.water,
          },
          {
            'name': 'teal',
            'backgroundColor': const Color(0xFF115E59),
            'icon': Icons.spa,
          },
          {
            'name': 'forest',
            'backgroundColor': const Color(0xFF1B4332),
            'icon': Icons.park,
          },
          {
            'name': 'rose',
            'backgroundColor': const Color(0xFF8B3A62),
            'icon': Icons.favorite,
          },
          {
            'name': 'wine',
            'backgroundColor': const Color(0xFF4A1942),
            'icon': Icons.wine_bar,
          },
          {
            'name': 'plum',
            'backgroundColor': const Color(0xFF5B2C6F),
            'icon': Icons.auto_awesome,
          },
          {
            'name': 'navy',
            'backgroundColor': const Color(0xFF0A1628),
            'icon': Icons.anchor,
          },
          {
            'name': 'mocha',
            'backgroundColor': const Color(0xFF4A3728),
            'icon': Icons.coffee,
          },
          {
            'name': 'charcoal',
            'backgroundColor': const Color(0xFF2D2D2D),
            'icon': Icons.circle,
          },
          {
            'name': 'midnight',
            'backgroundColor': const Color(0xFF1A1A2E),
            'icon': Icons.nights_stay,
          },
          {
            'name': 'dark',
            'backgroundColor': const Color(0xFF0D0D0D),
            'icon': Icons.dark_mode,
          },
        ];

  // Gradient backgrounds - Modern gradients
  final List<Map<String, dynamic>> _gradients = [
    {
      'name': 'gradient_sunset',
      'colors': [const Color(0xFFFF512F), const Color(0xFFDD2476)],
    },
    {
      'name': 'gradient_ocean',
      'colors': [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
    },
    {
      'name': 'gradient_aurora',
      'colors': [
        const Color(0xFF0F2027),
        const Color(0xFF203A43),
        const Color(0xFF2C5364),
      ],
    },
    {
      'name': 'gradient_purple',
      'colors': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    },
    {
      'name': 'gradient_midnight',
      'colors': [const Color(0xFF232526), const Color(0xFF414345)],
    },
    {
      'name': 'gradient_forest',
      'colors': [const Color(0xFF134E5E), const Color(0xFF71B280)],
    },
    {
      'name': 'gradient_rose',
      'colors': [const Color(0xFFB76E79), const Color(0xFFE8B4B8)],
    },
    {
      'name': 'gradient_candy',
      'colors': [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
    },
    {
      'name': 'gradient_neon',
      'colors': [const Color(0xFF00F260), const Color(0xFF0575E6)],
    },
    {
      'name': 'gradient_fire',
      'colors': [const Color(0xFFF12711), const Color(0xFFF5AF19)],
    },
    {
      'name': 'gradient_winter',
      'colors': [const Color(0xFFE6DADA), const Color(0xFF274046)],
    },
    {
      'name': 'gradient_lavender',
      'colors': [const Color(0xFFEE9CA7), const Color(0xFFFFDDE1)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    // First try to load from backend
    try {
      final result = await _conversationService.getConversationTheme(
        conversationId: widget.conversationId,
      );

      if (result['success'] == true && result['data'] != null) {
        final themeData = result['data'];
        final preset = themeData['preset'] as String?;
        if (preset != null && mounted) {
          setState(() => _selectedPreset = preset);
          return;
        }
      }
    } catch (e) {}

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('chat_theme_${widget.conversationId}');
    if (theme != null && mounted) {
      setState(() => _selectedPreset = theme);
    }
  }

  Future<void> _saveThemeLocally(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_theme_${widget.conversationId}', themeName);
  }

  Future<void> _pickCustomImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _customImagePath = pickedFile.path;
          _selectedPreset = 'custom';
        });
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(
          context,
          message: friendlyErrorMessage(AppLocalizations.of(context)!, e),
          type: ChatSnackBarType.error,
        );
      }
    }
  }

  Future<void> _applyTheme() async {
    if (_selectedPreset == null) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> theme = {'preset': _selectedPreset};

      // Find the preset data
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final preset = _getPresets(
        isDark,
      ).firstWhere((p) => p['name'] == _selectedPreset, orElse: () => {});

      if (preset.isNotEmpty) {
        theme['backgroundColor'] =
            '#${(preset['backgroundColor'] as Color).value.toRadixString(16).substring(2)}';
      }

      // Check if it's a gradient
      final gradient = _gradients.firstWhere(
        (g) => g['name'] == _selectedPreset,
        orElse: () => {},
      );

      if (gradient.isNotEmpty) {
        theme['gradientColors'] = (gradient['colors'] as List<Color>)
            .map((c) => '#${c.value.toRadixString(16).substring(2)}')
            .toList();
      }

      // Premium (coin-unlockable) gradients persist the same
      // `gradientColors` shape as free gradients for parity — the actual
      // render side resolves purely from `preset`'s `premium_` name via
      // the shared `premiumWallpapers` list, not from this field.
      if (_selectedPreset != null && isPremiumWallpaperName(_selectedPreset!)) {
        final premium = premiumWallpapers.firstWhere(
          (w) => w.name == _selectedPreset,
          orElse: () => premiumWallpapers.first,
        );
        theme['gradientColors'] = premium.colors
            .map((c) => '#${c.value.toRadixString(16).substring(2)}')
            .toList();
      }

      if (_customImagePath != null && _selectedPreset == 'custom') {
        // For custom images, we would upload to server
        // For now, just save locally
        theme['customImagePath'] = _customImagePath;
      }

      // Try to save to server
      final result = await _conversationService.setConversationTheme(
        conversationId: widget.conversationId,
        theme: theme,
      );

      // Also save locally for offline access
      await _saveThemeLocally(_selectedPreset!);

      if (mounted) {
        widget.onThemeChanged?.call();
        Navigator.of(context).pop(true);
        showChatSnackBar(
          context,
          message: result['success'] == true
              ? AppLocalizations.of(context)!.wallpaperUpdated
              : AppLocalizations.of(context)!.wallpaperSavedLocally,
          type: ChatSnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        // Save locally even if server fails
        await _saveThemeLocally(_selectedPreset!);
        if (!mounted) return;
        // Captured before the pop: reading the messenger from this screen's
        // own context afterwards would be reading a deactivated one.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.wallpaperSavedLocally),
          ),
        );
      }
    }
  }

  /// Renders the "Premium ✨" gradient section, or nothing at all.
  ///
  /// Hidden entirely (returns `[]`) when coins are off server-side or the
  /// `wallpaper` featureKey isn't in the live unlock catalog — matches the
  /// [UnlockCta] "render nothing rather than guess" convention so this
  /// screen never shows a coin surface the backend hasn't turned on.
  List<Widget> _buildPremiumSection() {
    final l10n = AppLocalizations.of(context)!;
    final coinsEnabled = ref
        .watch(appConfigProvider)
        .maybeWhen(
          data: (config) => config?.coinsEnabled ?? false,
          orElse: () => false,
        );
    if (!coinsEnabled) return const [];

    final catalogAsync = ref.watch(coinUnlockCatalogProvider);
    final entry = catalogAsync.maybeWhen(
      data: (catalog) => catalog[premiumWallpaperFeatureKey],
      orElse: () => null,
    );
    if (entry == null || entry.cost <= 0) return const [];

    final unlockedAsync = ref.watch(coinUnlockedFeaturesProvider);
    final isUnlocked = unlockedAsync.maybeWhen(
      data: (unlocked) => unlocked.contains(premiumWallpaperFeatureKey),
      orElse: () => false,
    );
    // While the entitlement is still loading we don't yet know if this was
    // already purchased — treat taps as locked-but-not-actionable rather
    // than risk firing `unlock` a second time once it resolves to true.
    final entitlementLoading = unlockedAsync.isLoading;

    return [
      Text(
        l10n.chatPremium,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ),
      Spacing.gapMD,
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: premiumWallpapers.length,
        itemBuilder: (context, index) {
          final wallpaper = premiumWallpapers[index];
          final isSelected = _selectedPreset == wallpaper.name;

          return GestureDetector(
            onTap: () => _handlePremiumTap(
              wallpaper,
              cost: entry.cost,
              isUnlocked: isUnlocked,
              entitlementLoading: entitlementLoading,
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: wallpaper.gradient,
                        borderRadius: AppRadius.borderMD,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : context.dividerColor,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isUnlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: AppRadius.borderMD,
                          ),
                          child: Center(
                            child: entitlementLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      Text(
                                        '💎${entry.cost}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
                Spacing.gapXS,
                Text(
                  wallpaperDisplayName(l10n, wallpaper.name),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
      Spacing.gapLG,
    ];
  }

  /// Tap handler for a premium preset tile.
  ///
  /// - Already unlocked -> selects it exactly like a free preset, no
  ///   network call (never re-charge an already-unlocked feature).
  /// - Entitlement still loading, or an unlock is already in flight ->
  ///   no-op, so a double-tap can't fire two spends.
  /// - Locked -> confirm dialog showing the live cost, then spends via
  ///   `CoinApiClient.unlock`; on success re-reads entitlements so the
  ///   whole pack becomes selectable immediately.
  Future<void> _handlePremiumTap(
    PremiumWallpaper wallpaper, {
    required int cost,
    required bool isUnlocked,
    required bool entitlementLoading,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (isUnlocked) {
      setState(() {
        _selectedPreset = wallpaper.name;
        _customImagePath = null;
      });
      return;
    }

    if (entitlementLoading || _unlockingPremium) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unlockPremiumWallpapers),
        content: Text(
          l10n.chatUnlockPremiumWallpapers(cost),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context)!.unlock),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _unlockingPremium = true);
    try {
      final client = ref.read(coinApiClientProvider);
      final response = await client.unlock(premiumWallpaperFeatureKey);
      if (!mounted) return;

      if (response.success) {
        refreshCoinBalance(ref);
        refreshCoinUnlockedFeatures(ref);
        setState(() {
          _selectedPreset = wallpaper.name;
          _customImagePath = null;
        });
        showChatSnackBar(
          context,
          message: AppLocalizations.of(context)!.chatWallpapersUnlocked,
          type: ChatSnackBarType.success,
        );
      } else if (response.statusCode == 402) {
        showChatSnackBar(
          context,
          message: AppLocalizations.of(context)!.notEnoughCoins,
          type: ChatSnackBarType.error,
        );
      } else {
        showChatSnackBar(
          context,
          message: AppLocalizations.of(context)!.unlockFailed,
          type: ChatSnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _unlockingPremium = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatWallpaper),
        actions: [
          if (_selectedPreset != null)
            TextButton(
              onPressed: _isLoading ? null : _applyTheme,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.apply),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final isDark = context.isDarkMode;
          final presets = _getPresets(isDark);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatWallpaperForName(widget.userName),
                  style: TextStyle(color: context.textSecondary),
                ),
                Spacing.gapLG,

                // Solid Colors Section
                Text(
                  l10n.solidColors,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Spacing.gapMD,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    final isSelected = _selectedPreset == preset['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPreset = preset['name'];
                          _customImagePath = null;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: preset['backgroundColor'],
                              borderRadius: AppRadius.borderMD,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.dividerColor,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Builder(
                              builder: (context) {
                                // Use light icon on dark backgrounds
                                final bg = preset['backgroundColor'] as Color;
                                final isLightBg = bg.computeLuminance() > 0.5;
                                return Icon(
                                  preset['icon'],
                                  color: isLightBg
                                      ? AppColors.gray600
                                      : AppColors.white,
                                );
                              },
                            ),
                          ),
                          Spacing.gapXS,
                          Text(
                            wallpaperDisplayName(l10n, preset['name']),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Spacing.gapLG,

                // Gradients Section
                Text(
                  l10n.gradients,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Spacing.gapMD,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _gradients.length,
                  itemBuilder: (context, index) {
                    final gradient = _gradients[index];
                    final isSelected = _selectedPreset == gradient['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPreset = gradient['name'];
                          _customImagePath = null;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient['colors'],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AppRadius.borderMD,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.dividerColor,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          Spacing.gapXS,
                          Text(
                            wallpaperDisplayName(l10n, gradient['name']),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Spacing.gapLG,

                // Premium Gradients Section (coin-unlockable, Task 12) — hidden
                // entirely when coins are off or the `wallpaper` catalog key
                // isn't present server-side.
                ..._buildPremiumSection(),

                // Custom Image Section
                Text(
                  l10n.customImage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Spacing.gapMD,
                GestureDetector(
                  onTap: _pickCustomImage,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: AppRadius.borderMD,
                      border: Border.all(
                        color: _selectedPreset == 'custom'
                            ? AppColors.primary
                            : context.dividerColor,
                        width: _selectedPreset == 'custom' ? 3 : 1,
                      ),
                      image: _customImagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_customImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _customImagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: context.textHint,
                              ),
                              Spacing.gapSM,
                              Text(
                                l10n.chatChooseGallery,
                                style: TextStyle(color: context.textSecondary),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),

                Spacing.gapXL,

                // Preview Section
                if (_selectedPreset != null) ...[
                  Text(
                    l10n.preview,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.gapMD,
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderMD,
                      border: Border.all(color: context.dividerColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: _buildPreview(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    Widget background;

    if (_customImagePath != null && _selectedPreset == 'custom') {
      background = Image.file(
        File(_customImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      final gradient = _gradients.firstWhere(
        (g) => g['name'] == _selectedPreset,
        orElse: () => {},
      );

      if (gradient.isNotEmpty) {
        background = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient['colors'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      } else {
        final premiumGradient = premiumWallpaperGradient(_selectedPreset ?? '');
        if (premiumGradient != null) {
          background = Container(
            decoration: BoxDecoration(gradient: premiumGradient),
          );
        } else {
          final presets = _getPresets(isDark);
          final preset = presets.firstWhere(
            (p) => p['name'] == _selectedPreset,
            orElse: () => {
              'backgroundColor': isDark
                  ? AppColors.backgroundDark
                  : AppColors.gray100,
            },
          );
          background = Container(color: preset['backgroundColor'] as Color);
        }
      }
    }

    // Preview bubble colors match actual chat bubble theme
    final otherBubbleColor = isDark ? AppColors.cardDark : AppColors.white;
    final otherTextColor = isDark ? AppColors.white : AppColors.gray900;

    return Stack(
      children: [
        background,
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: otherBubbleColor,
              borderRadius: AppRadius.borderMD,
            ),
            child: Text(
              AppLocalizations.of(context)!.chatWallpaperPreviewHello,
              style: TextStyle(color: otherTextColor),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.borderMD,
            ),
            child: Text(
              l10n.chatHiThere,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: otherBubbleColor,
              borderRadius: AppRadius.borderMD,
            ),
            child: Text(
              AppLocalizations.of(context)!.chatWallpaperPreviewHow,
              style: TextStyle(color: otherTextColor),
            ),
          ),
        ),
      ],
    );
  }
}
