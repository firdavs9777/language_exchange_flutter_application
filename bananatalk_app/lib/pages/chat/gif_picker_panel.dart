import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/services/giphy_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

// ============================================================================
// INTERNAL STATE
// ============================================================================

/// Tracks what the GIF picker is currently showing.
enum _PickerState { loading, loaded, error }

class _GifPickerStateModel {
  final List<GiphyGif> gifs;
  final _PickerState state;
  final String? errorMessage;
  final bool isSearching;

  const _GifPickerStateModel({
    this.gifs = const [],
    this.state = _PickerState.loading,
    this.errorMessage,
    this.isSearching = false,
  });

  _GifPickerStateModel copyWith({
    List<GiphyGif>? gifs,
    _PickerState? state,
    String? errorMessage,
    bool? isSearching,
  }) {
    return _GifPickerStateModel(
      gifs: gifs ?? this.gifs,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

// ============================================================================
// WIDGET
// ============================================================================

/// A modal bottom sheet GIF picker backed by the GIPHY API.
///
/// Shows trending GIFs by default; debounced search triggers on input.
/// Call [GifPickerPanel.show] to open it and await the selected [GiphyGif].
class GifPickerPanel extends ConsumerStatefulWidget {
  final void Function(GiphyGif gif) onGifSelected;

  const GifPickerPanel({
    super.key,
    required this.onGifSelected,
  });

  /// Opens the GIF picker as a modal bottom sheet.
  ///
  /// Returns the selected [GiphyGif] or `null` if the user dismissed without
  /// selecting.
  static Future<GiphyGif?> show(BuildContext context) {
    return showModalBottomSheet<GiphyGif>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GifPickerPanel(
        onGifSelected: (gif) => Navigator.pop(context, gif),
      ),
    );
  }

  @override
  ConsumerState<GifPickerPanel> createState() => _GifPickerPanelState();
}

class _GifPickerPanelState extends ConsumerState<GifPickerPanel> {
  // Search
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // State
  _GifPickerStateModel _model = const _GifPickerStateModel();

  @override
  void initState() {
    super.initState();
    _loadTrending();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Data fetching
  // --------------------------------------------------------------------------

  Future<void> _loadTrending() async {
    setState(() {
      _model = _model.copyWith(
        state: _PickerState.loading,
        isSearching: false,
      );
    });

    try {
      final service = ref.read(giphyServiceProvider);
      final gifs = await service.getTrendingGifs();
      if (mounted) {
        setState(() {
          _model = _model.copyWith(
            gifs: gifs,
            state: _PickerState.loaded,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _model = _model.copyWith(
            state: _PickerState.error,
            errorMessage: 'Could not load trending GIFs.',
          );
        });
      }
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrending();
      return;
    }

    setState(() {
      _model = _model.copyWith(
        state: _PickerState.loading,
        isSearching: true,
      );
    });

    try {
      final service = ref.read(giphyServiceProvider);
      final gifs = await service.searchGifs(query);
      if (mounted) {
        setState(() {
          _model = _model.copyWith(
            gifs: gifs,
            state: _PickerState.loaded,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _model = _model.copyWith(
            state: _PickerState.error,
            errorMessage: 'Search failed. Please try again.',
          );
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // Listeners
  // --------------------------------------------------------------------------

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGifs(_searchController.text);
    });
  }

  void _onGifTapped(GiphyGif gif) {
    widget.onGifSelected(gif);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.70,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: AppShadows.xl,
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildSearchBar(),
          _buildSectionLabel(),
          Expanded(child: _buildBody()),
          _buildGiphyAttribution(),
        ],
      ),
    );
  }

  // --- Sub-widgets ---

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          _debounce?.cancel();
          _searchGifs(value);
        },
        decoration: InputDecoration(
          hintText: 'Search GIFs...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: context.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _loadTrending();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          filled: true,
          fillColor: context.containerColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.round),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.round),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.round),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          hintStyle: TextStyle(
            color: context.textHint,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    final label = _model.isSearching && _searchController.text.isNotEmpty
        ? 'Results for "${_searchController.text}"'
        : 'Trending';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_model.state) {
      case _PickerState.loading:
        return _buildLoadingGrid();
      case _PickerState.error:
        return _buildError();
      case _PickerState.loaded:
        if (_model.gifs.isEmpty) return _buildEmptyState();
        return _buildGrid();
    }
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => _GifShimmerCell(key: ValueKey(index)),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: _model.gifs.length,
      itemBuilder: (context, index) {
        final gif = _model.gifs[index];
        return _GifGridItem(
          gif: gif,
          onTap: () => _onGifTapped(gif),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gif_box_outlined,
            size: 48,
            color: context.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No GIFs found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 13,
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: context.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _model.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _searchController.text.isNotEmpty
                  ? () => _searchGifs(_searchController.text)
                  : _loadTrending,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiphyAttribution() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by ',
            style: TextStyle(
              fontSize: 11,
              color: context.textMuted,
            ),
          ),
          Text(
            'GIPHY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GIF GRID ITEM
// ============================================================================

class _GifGridItem extends StatelessWidget {
  final GiphyGif gif;
  final VoidCallback onTap;

  const _GifGridItem({
    required this.gif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: context.containerColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: AppColors.primary.withValues(alpha: 0.08),
          child: CachedNetworkImage(
            imageUrl: gif.previewUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const _GifShimmerCell(),
            errorWidget: (context, url, error) => _GifErrorCell(),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHIMMER LOADING PLACEHOLDER
// ============================================================================

class _GifShimmerCell extends StatefulWidget {
  const _GifShimmerCell({super.key});

  @override
  State<_GifShimmerCell> createState() => _GifShimmerCellState();
}

class _GifShimmerCellState extends State<_GifShimmerCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.isDarkMode
                  ? AppColors.gray700.withValues(alpha: _animation.value)
                  : AppColors.gray300.withValues(alpha: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// ERROR PLACEHOLDER
// ============================================================================

class _GifErrorCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: context.containerColor,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: context.textMuted,
            size: 28,
          ),
        ),
      ),
    );
  }
}
