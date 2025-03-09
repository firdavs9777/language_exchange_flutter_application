import 'package:bananatalk_app/pages/community/community_filter.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CommunityMain extends ConsumerStatefulWidget {
  const CommunityMain({Key? key}) : super(key: key);

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain> {
  late String userId = '';
  Map<String, dynamic> _filters = {
    'minAge': 18,
    'maxAge': 100,
    'gender': null,
    'nativeLanguage': null,
  };

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _refresh() async {
    ref.refresh(communityProvider);
  }

  Future<void> _filterSearch() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityFilter(
            onApplyFilters: (filters) {
              setState(() {
                _filters = filters;
              });
            },
            initialFilters: _filters),
      ),
    );
  }

  Future<void> redirect(String id) async {
    Community community =
        await ref.read(communityServiceProvider).getSingleCommunity(id: id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleCommunity(community: community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityAsyncValue = ref.watch(communityProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Community',
            style: TextStyle(fontWeight: FontWeight.w600)), // Bold title
        actions: [
          IconButton(
            onPressed: _filterSearch,
            icon: const Icon(Icons.filter_list),
          ),
        ],
        elevation: 1, // Subtle shadow
        // White background
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: communityAsyncValue.when(
          data: (communities) {
            final filteredCommunities = communities.where((community) {
              if (community.id == userId) return false;
              if (_filters['gender'] != null &&
                  _filters['gender'] != community.gender) return false;
              if (_filters['language'] != null &&
                  _filters['language'] != community.native_language)
                return false;
              return true;
            }).toList();

            return ListView.separated(
              // Use ListView.separated for dividers
              itemCount: filteredCommunities.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1), // Add dividers
              itemBuilder: (context, index) {
                final community = filteredCommunities[index];
                return InkWell(
                  // Add InkWell for tap effect
                  onTap: () {
                    redirect(community.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0), // Increase padding
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30, // Increase avatar size
                          backgroundImage: community.imageUrls.isNotEmpty
                              ? NetworkImage(community.imageUrls[0])
                              : const AssetImage(
                                      'assets/images/logo_no_background.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18), // Bold name
                              ),
                              const SizedBox(height: 4),
                              Text(
                                community.bio,
                                style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey[600]), // Soft bio text
                                maxLines: 2, // Limit bio lines
                                overflow: TextOverflow
                                    .ellipsis, // Ellipsis for long bio
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.translate,
                                      size: 16,
                                      color: Colors.blueGrey), // Language icon
                                  const SizedBox(width: 4),
                                  Text(
                                    'Native: ${community.native_language}, Learning: ${community.language_to_learn}',
                                    style: const TextStyle(fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey), // Arrow icon
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Failed to load users $error')),
        ),
      ),
    );
  }
}
