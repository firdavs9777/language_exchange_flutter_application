import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Preset color themes
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'default',
      'label': 'Default',
      'backgroundColor': const Color(0xFFF5F5F5),
      'icon': Icons.brightness_auto,
    },
    {
      'name': 'dark',
      'label': 'Dark',
      'backgroundColor': const Color(0xFF1A1A2E),
      'icon': Icons.dark_mode,
    },
    {
      'name': 'light',
      'label': 'Light',
      'backgroundColor': const Color(0xFFFFFFFF),
      'icon': Icons.light_mode,
    },
    {
      'name': 'blue',
      'label': 'Ocean Blue',
      'backgroundColor': const Color(0xFF1E3A5F),
      'icon': Icons.water,
    },
    {
      'name': 'pink',
      'label': 'Rose Pink',
      'backgroundColor': const Color(0xFFE8B4BC),
      'icon': Icons.favorite,
    },
    {
      'name': 'green',
      'label': 'Forest Green',
      'backgroundColor': const Color(0xFF2D5A27),
      'icon': Icons.park,
    },
    {
      'name': 'purple',
      'label': 'Lavender',
      'backgroundColor': const Color(0xFF6B5B95),
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'sunset',
      'label': 'Sunset',
      'backgroundColor': const Color(0xFFFF6B6B),
      'icon': Icons.wb_twilight,
    },
  ];

  // Gradient backgrounds
  final List<Map<String, dynamic>> _gradients = [
    {
      'name': 'gradient_blue',
      'label': 'Blue Sky',
      'colors': [const Color(0xFF4158D0), const Color(0xFFC850C0), const Color(0xFFFFCC70)],
    },
    {
      'name': 'gradient_green',
      'label': 'Aurora',
      'colors': [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
    },
    {
      'name': 'gradient_pink',
      'label': 'Candy',
      'colors': [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
    },
    {
      'name': 'gradient_purple',
      'label': 'Galaxy',
      'colors': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('chat_theme_${widget.conversationId}');
    if (theme != null) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      final preset = _presets.firstWhere(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? 'Wallpaper updated'
                  : 'Wallpaper saved locally',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Save locally even if server fails
        await _saveThemeLocally(_selectedPreset!);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper saved locally'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Wallpaper'),
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
                  : const Text('Apply'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat wallpaper for ${widget.userName}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // Solid Colors Section
            const Text(
              'Solid Colors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          preset['icon'],
                          color: preset['name'] == 'dark' ||
                                  preset['name'] == 'blue' ||
                                  preset['name'] == 'green' ||
                                  preset['name'] == 'purple'
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset['label'],
                        style: TextStyle(
                          fontSize: 11,
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
            
            const SizedBox(height: 24),
            
            // Gradients Section
            const Text(
              'Gradients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gradient['label'],
                        style: TextStyle(
                          fontSize: 11,
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
            
            const SizedBox(height: 24),
            
            // Custom Image Section
            const Text(
              'Custom Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickCustomImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPreset == 'custom'
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose from gallery',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Preview Section
            if (_selectedPreset != null) ...[
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _buildPreview(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
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
        final preset = _presets.firstWhere(
          (p) => p['name'] == _selectedPreset,
          orElse: () => {'backgroundColor': Colors.grey[100]},
        );
        background = Container(
          color: preset['backgroundColor'] as Color,
        );
      }
    }

    return Stack(
      children: [
        background,
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Hello! 👋'),
          ),
        ),
        Positioned(
          right: 16,
          top: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Hi there! 😊',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('How are you?'),
          ),
        ),
      ],
    );
  }
}

