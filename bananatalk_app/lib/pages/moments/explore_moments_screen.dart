import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/moments_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

class ExploreMomentsScreen extends StatefulWidget {
  const ExploreMomentsScreen({Key? key}) : super(key: key);

  @override
  State<ExploreMomentsScreen> createState() => _ExploreMomentsScreenState();
}

class _ExploreMomentsScreenState extends State<ExploreMomentsScreen> {
  List<Moments> _moments = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Filter state
  MomentsExploreFilter _filter = MomentsExploreFilter();
  String? _selectedCategory;
  String? _selectedLanguage;
  String? _selectedMood;
  List<String> _selectedTags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMoments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreMoments();
    }
  }

  void _updateFilter() {
    _filter = MomentsExploreFilter(
      category: _selectedCategory,
      language: _selectedLanguage,
      mood: _selectedMood,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      page: 1,
    );
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await MomentsService.exploreMoments(filter: _filter);

      if (mounted) {
        if (response.success) {
          setState(() {
            _moments = response.data;
            _totalPages = (response.totalMoments / 10).ceil();
            _currentPage = 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.error;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load moments';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMoments() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextFilter = _filter.copyWith(page: _currentPage + 1);
      final response = await MomentsService.exploreMoments(filter: nextFilter);

      if (mounted) {
        if (response.success) {
          setState(() {
            _moments.addAll(response.data);
            _currentPage++;
            _isLoadingMore = false;
          });
        } else {
          setState(() => _isLoadingMore = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedLanguage = null;
      _selectedMood = null;
      _selectedTags = [];
      _filter = MomentsExploreFilter();
    });
    _loadMoments();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedLanguage != null ||
      _selectedMood != null ||
      _selectedTags.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          
          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Category chips
          ...MomentCategory.all.take(6).map((cat) {
            final isSelected = _selectedCategory == cat['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['icon']!),
                    const SizedBox(width: 4),
                    Text(cat['label']!),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? cat['value'] : null;
                  });
                  _updateFilter();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMoments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_moments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No moments found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMoments,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _moments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _moments.length) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final moment = _moments[index];
          return _ExploreMomentCard(moment: moment);
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedCategory = null;
                          _selectedLanguage = null;
                          _selectedMood = null;
                          _selectedTags = [];
                        });
                      },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateFilter();
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),

              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MomentCategory.all.map((cat) {
                        final isSelected = _selectedCategory == cat['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat['icon']!),
                              const SizedBox(width: 4),
                              Text(cat['label']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              _selectedCategory = selected ? cat['value'] : null;
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Mood
                    const Text(
                      'Mood',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MomentMood.all.map((mood) {
                        final isSelected = _selectedMood == mood['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(mood['emoji']!, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(mood['label']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              _selectedMood = selected ? mood['value'] : null;
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Language
                    const Text(
                      'Language',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonLanguages.map((lang) {
                        final isSelected = _selectedLanguage == lang['code'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(lang['flag']!),
                              const SizedBox(width: 4),
                              Text(lang['name']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              _selectedLanguage = selected ? lang['code'] : null;
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Tags
                    const Text(
                      'Tags',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add tag and press enter',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final tag = _tagController.text.trim();
                            if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                              setSheetState(() {
                                _selectedTags.add(tag);
                              });
                              setState(() {});
                              _tagController.clear();
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        final tag = value.trim();
                        if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                          setSheetState(() {
                            _selectedTags.add(tag);
                          });
                          setState(() {});
                          _tagController.clear();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_selectedTags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text('#$tag'),
                            onDeleted: () {
                              setSheetState(() {
                                _selectedTags.remove(tag);
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> get _commonLanguages => [
        {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
        {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷'},
        {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
        {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
        {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
        {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
        {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
        {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹'},
        {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺'},
        {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
      ];
}

class _ExploreMomentCard extends StatelessWidget {
  final Moments moment;

  const _ExploreMomentCard({required this.moment});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to moment detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (moment.imageUrls.isNotEmpty)
                    CachedImageWidget(
                      imageUrl: moment.imageUrls.first,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: Icon(
                          Icons.image,
                          size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.3),
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          moment.title.isNotEmpty
                              ? moment.title[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Category badge
                  if (moment.category.isNotEmpty && moment.category != 'general')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCategoryIcon(moment.category),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),

                  // Mood
                  if (moment.mood.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _getMoodEmoji(moment.mood),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User
                    Row(
                      children: [
                        CachedCircleAvatar(
                          imageUrl: moment.user.images.isNotEmpty
                              ? moment.user.images.first
                              : null,
                          radius: 12,
                          errorWidget: Text(
                            moment.user.name?.isNotEmpty == true
                                ? moment.user.name![0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            moment.user.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Title
                    if (moment.title.isNotEmpty)
                      Text(
                        moment.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Stats
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text(
                          '${moment.likeCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.comment, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text(
                          '${moment.commentCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    final cat = MomentCategory.all.firstWhere(
      (c) => c['value'] == category,
      orElse: () => {'icon': '🌐'},
    );
    return cat['icon']!;
  }

  String _getMoodEmoji(String mood) {
    final m = MomentMood.all.firstWhere(
      (mo) => mo['value'] == mood,
      orElse: () => {'emoji': ''},
    );
    return m['emoji'] ?? '';
  }
}

