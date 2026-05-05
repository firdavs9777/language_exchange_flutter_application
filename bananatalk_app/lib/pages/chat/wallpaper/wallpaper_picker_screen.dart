import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

class WallpaperPickerScreen extends StatefulWidget {
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
  State<WallpaperPickerScreen> createState() => _WallpaperPickerScreenState();
}

class _WallpaperPickerScreenState extends State<WallpaperPickerScreen> {
  final ConversationService _conversationService = ConversationService();
  String? _selectedPreset;
  String? _customImagePath;
  bool _isLoading = false;

  // Preset color themes - adapts to light/dark mode
  List<Map<String, dynamic>> _getPresets(bool isDark) => isDark
      ? [
          // Dark mode: all dark-friendly wallpapers
          {'name': 'default', 'label': 'Default', 'backgroundColor': AppColors.backgroundDark, 'icon': Icons.brightness_auto},
          {'name': 'dark', 'label': 'Dark', 'backgroundColor': const Color(0xFF0D0D0D), 'icon': Icons.dark_mode},
          {'name': 'midnight', 'label': 'Midnight', 'backgroundColor': const Color(0xFF1A1A2E), 'icon': Icons.nights_stay},
          {'name': 'charcoal', 'label': 'Charcoal', 'backgroundColor': const Color(0xFF2D2D2D), 'icon': Icons.circle},
          {'name': 'navy', 'label': 'Navy', 'backgroundColor': const Color(0xFF0A1628), 'icon': Icons.anchor},
          {'name': 'ocean', 'label': 'Ocean', 'backgroundColor': const Color(0xFF1E3A5F), 'icon': Icons.water},
          {'name': 'teal', 'label': 'Teal', 'backgroundColor': const Color(0xFF115E59), 'icon': Icons.spa},
          {'name': 'forest', 'label': 'Forest', 'backgroundColor': const Color(0xFF1B4332), 'icon': Icons.park},
          {'name': 'sage', 'label': 'Sage', 'backgroundColor': const Color(0xFF4A5D4A), 'icon': Icons.eco},
          {'name': 'wine', 'label': 'Wine', 'backgroundColor': const Color(0xFF4A1942), 'icon': Icons.wine_bar},
          {'name': 'plum', 'label': 'Plum', 'backgroundColor': const Color(0xFF5B2C6F), 'icon': Icons.auto_awesome},
          {'name': 'rose', 'label': 'Rose', 'backgroundColor': const Color(0xFF5C1A3A), 'icon': Icons.favorite},
          {'name': 'mocha', 'label': 'Mocha', 'backgroundColor': const Color(0xFF4A3728), 'icon': Icons.coffee},
          {'name': 'slate', 'label': 'Slate', 'backgroundColor': const Color(0xFF1E293B), 'icon': Icons.layers},
          {'name': 'ember', 'label': 'Ember', 'backgroundColor': const Color(0xFF3B1A1A), 'icon': Icons.local_fire_department},
          {'name': 'deep_sea', 'label': 'Deep Sea', 'backgroundColor': const Color(0xFF0B2545), 'icon': Icons.scuba_diving},
        ]
      : [
          // Light mode: mix of light and medium wallpapers
          {'name': 'default', 'label': 'Default', 'backgroundColor': const Color(0xFFF5F5F5), 'icon': Icons.brightness_auto},
          {'name': 'cream', 'label': 'Cream', 'backgroundColor': const Color(0xFFF5E6D3), 'icon': Icons.light_mode},
          {'name': 'blush', 'label': 'Blush', 'backgroundColor': const Color(0xFFE8B4BC), 'icon': Icons.favorite_border},
          {'name': 'peach', 'label': 'Peach', 'backgroundColor': const Color(0xFFE6A67C), 'icon': Icons.wb_sunny},
          {'name': 'sage', 'label': 'Sage', 'backgroundColor': const Color(0xFF4A5D4A), 'icon': Icons.eco},
          {'name': 'ocean', 'label': 'Ocean', 'backgroundColor': const Color(0xFF1E3A5F), 'icon': Icons.water},
          {'name': 'teal', 'label': 'Teal', 'backgroundColor': const Color(0xFF115E59), 'icon': Icons.spa},
          {'name': 'forest', 'label': 'Forest', 'backgroundColor': const Color(0xFF1B4332), 'icon': Icons.park},
          {'name': 'rose', 'label': 'Rose', 'backgroundColor': const Color(0xFF8B3A62), 'icon': Icons.favorite},
          {'name': 'wine', 'label': 'Wine', 'backgroundColor': const Color(0xFF4A1942), 'icon': Icons.wine_bar},
          {'name': 'plum', 'label': 'Plum', 'backgroundColor': const Color(0xFF5B2C6F), 'icon': Icons.auto_awesome},
          {'name': 'navy', 'label': 'Navy', 'backgroundColor': const Color(0xFF0A1628), 'icon': Icons.anchor},
          {'name': 'mocha', 'label': 'Mocha', 'backgroundColor': const Color(0xFF4A3728), 'icon': Icons.coffee},
          {'name': 'charcoal', 'label': 'Charcoal', 'backgroundColor': const Color(0xFF2D2D2D), 'icon': Icons.circle},
          {'name': 'midnight', 'label': 'Midnight', 'backgroundColor': const Color(0xFF1A1A2E), 'icon': Icons.nights_stay},
          {'name': 'dark', 'label': 'Dark', 'backgroundColor': const Color(0xFF0D0D0D), 'icon': Icons.dark_mode},
        ];

  // Gradient backgrounds - Modern gradients
  final List<Map<String, dynamic>> _gradients = [
    {
      'name': 'gradient_sunset',
      'label': 'Sunset',
      'colors': [const Color(0xFFFF512F), const Color(0xFFDD2476)],
    },
    {
      'name': 'gradient_ocean',
      'label': 'Ocean',
      'colors': [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
    },
    {
      'name': 'gradient_aurora',
      'label': 'Aurora',
      'colors': [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
    },
    {
      'name': 'gradient_purple',
      'label': 'Cosmic',
      'colors': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    },
    {
      'name': 'gradient_midnight',
      'label': 'Midnight',
      'colors': [const Color(0xFF232526), const Color(0xFF414345)],
    },
    {
      'name': 'gradient_forest',
      'label': 'Forest',
      'colors': [const Color(0xFF134E5E), const Color(0xFF71B280)],
    },
    {
      'name': 'gradient_rose',
      'label': 'Rose Gold',
      'colors': [const Color(0xFFB76E79), const Color(0xFFE8B4B8)],
    },
    {
      'name': 'gradient_candy',
      'label': 'Candy',
      'colors': [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
    },
    {
      'name': 'gradient_neon',
      'label': 'Neon',
      'colors': [const Color(0xFF00F260), const Color(0xFF0575E6)],
    },
    {
      'name': 'gradient_fire',
      'label': 'Fire',
      'colors': [const Color(0xFFF12711), const Color(0xFFF5AF19)],
    },
    {
      'name': 'gradient_winter',
      'label': 'Winter',
      'colors': [const Color(0xFFE6DADA), const Color(0xFF274046)],
    },
    {
      'name': 'gradient_lavender',
      'label': 'Lavender',
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
    } catch (e) {
    }

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
        showChatSnackBar(context, message: 'Failed to pick image: ${e.toString()}', type: ChatSnackBarType.error);
      }
    }
  }

  Future<void> _applyTheme() async {
    if (_selectedPreset == null) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> theme = {
        'preset': _selectedPreset,
      };

      // Find the preset data
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final preset = _getPresets(isDark).firstWhere(
        (p) => p['name'] == _selectedPreset,
        orElse: () => {},
      );

      if (preset.isNotEmpty) {
        theme['backgroundColor'] = '#${(preset['backgroundColor'] as Color).value.toRadixString(16).substring(2)}';
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
          message: result['success'] == true ? 'Wallpaper updated' : 'Wallpaper saved locally',
          type: ChatSnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        // Save locally even if server fails
        await _saveThemeLocally(_selectedPreset!);
        Navigator.of(context).pop(true);
        showChatSnackBar(context, message: 'Wallpaper saved locally', type: ChatSnackBarType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Chat wallpaper for ${widget.userName}',
              style: TextStyle(color: context.textSecondary),
            ),
            Spacing.gapLG,

            // Solid Colors Section
            Text(
              'Solid Colors',
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
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Builder(builder: (context) {
                          // Use light icon on dark backgrounds
                          final bg = preset['backgroundColor'] as Color;
                          final isLightBg = bg.computeLuminance() > 0.5;
                          return Icon(
                            preset['icon'],
                            color: isLightBg ? AppColors.gray600 : AppColors.white,
                          );
                        }),
                      ),
                      Spacing.gapXS,
                      Text(
                        preset['label'],
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
              'Gradients',
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
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      Spacing.gapXS,
                      Text(
                        gradient['label'],
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),

            Spacing.gapLG,

            // Custom Image Section
            Text(
              'Custom Image',
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
                            'Choose from gallery',
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
                'Preview',
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
        final presets = _getPresets(isDark);
        final preset = presets.firstWhere(
          (p) => p['name'] == _selectedPreset,
          orElse: () => {'backgroundColor': isDark ? AppColors.backgroundDark : AppColors.gray100},
        );
        background = Container(
          color: preset['backgroundColor'] as Color,
        );
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
            child: Text('Hello! 👋', style: TextStyle(color: otherTextColor)),
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
            child: const Text(
              'Hi there! 😊',
              style: TextStyle(color: AppColors.white),
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
            child: Text('How are you?', style: TextStyle(color: otherTextColor)),
          ),
        ),
      ],
    );
  }
}

