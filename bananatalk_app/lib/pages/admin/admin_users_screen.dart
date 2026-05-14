import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/admin_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/admin/admin_user_detail_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Step 15 F3 — admin user search screen.
///
/// - Debounced search TextField (300ms) at the top
/// - Mutually-exclusive facet chips: All / Banned / Admins
/// - Paginated user list with infinite scroll
/// - Each row → AdminUserDetailScreen
/// - List refreshes when returning from detail (in case ban / role changed)
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

enum _Facet { all, banned, admins }

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  _Facet _facet = _Facet.all;
  final List<dynamic> _users = [];
  bool _isLoading = false;
  bool _hasMore = false;
  int _page = 1;
  int _total = 0;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
        );
        return;
      }
      _load(reset: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _load(reset: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _load();
    }
  }

  void _setFacet(_Facet facet) {
    if (_facet == facet) return;
    setState(() => _facet = facet);
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _users.clear();
        _page = 1;
        _error = null;
      });
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _adminService.searchUsers(
      q: _query.isEmpty ? null : _query,
      bannedOnly: _facet == _Facet.banned,
      adminsOnly: _facet == _Facet.admins,
      page: _page,
      limit: 20,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final newUsers = (result['data'] as List?) ?? [];
        _users.addAll(newUsers);
        final pagination =
            (result['pagination'] as Map<String, dynamic>?) ?? const {};
        _hasMore = pagination['hasMore'] == true;
        _total = (pagination['total'] as num?)?.toInt() ?? _total;
        _page += 1;
        _error = null;
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        _facet != _Facet.all || _query.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hasFilter
                    ? '${_formatNum(_total)} matching · search filtered'
                    : '${_formatNum(_total)} total users',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: Spacing.paddingMD,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or username',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _FacetChip(
                    label: 'All',
                    selected: _facet == _Facet.all,
                    onSelected: () => _setFacet(_Facet.all),
                  ),
                  const SizedBox(width: 8),
                  _FacetChip(
                    label: 'Banned',
                    selected: _facet == _Facet.banned,
                    color: AppColors.error,
                    onSelected: () => _setFacet(_Facet.banned),
                  ),
                  const SizedBox(width: 8),
                  _FacetChip(
                    label: 'Admins',
                    selected: _facet == _Facet.admins,
                    color: const Color(0xFF9C27B0),
                    onSelected: () => _setFacet(_Facet.admins),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_error != null && _users.isEmpty) {
      return _ErrorState(error: _error!, onRetry: () => _load(reset: true));
    }
    if (_users.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No users found.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _users.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final user = _users[index] as Map<String, dynamic>;
          return _UserRow(
            user: user,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminUserDetailScreen(
                    userId: user['_id']?.toString() ?? '',
                  ),
                ),
              );
              if (mounted) _load(reset: true);
            },
          );
        },
      ),
    );
  }
}

String _formatNum(int n) {
  if (n < 1000) return n.toString();
  final s = n.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

class _FacetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;
  const _FacetChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: c.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? c : Colors.black87,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  const _UserRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? '(unknown)';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'user';
    final isBanned = user['isBanned'] == true;
    final List<String> imgList = [
      ...((user['imageUrls'] is List)
          ? List<String>.from(user['imageUrls']).whereType<String>()
          : const <String>[]),
      ...((user['images'] is List)
          ? List<String>.from(user['images']).whereType<String>()
          : const <String>[]),
    ];
    final avatarUrl = imgList.firstWhere(
      (u) => u.isNotEmpty && u.startsWith('http'),
      orElse: () => '',
    );

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage:
            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (isBanned) _Pill(text: 'BANNED', color: AppColors.error),
          if (role == 'admin')
            const _Pill(text: 'ADMIN', color: Color(0xFF9C27B0)),
        ],
      ),
      subtitle: Text(
        email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text("This page isn't available.")),
    );
  }
}
