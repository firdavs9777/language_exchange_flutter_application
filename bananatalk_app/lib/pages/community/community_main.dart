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
  }; // To store selected filters

  @override
  void initState() {
    super.initState();
    _initializeUserId(); // Initialize userId from SharedPreferences
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
                _filters = filters; // Store selected filters
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
        title: const Text('Community'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () {
                    _filterSearch();
                  },
                  icon: const Icon(Icons.filter_list))
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: communityAsyncValue.when(
          data: (communities) {
            // Filter out the community with the logged-in user's ID
            final filteredCommunities = communities.where((community) {
              if (community.id == userId) return false;

              // Apply age filter
              // if (_filters['minAge'] != null &&
              //     community.birth_year < _filters['minAge']) return false;
              // if (_filters['maxAge'] != null &&
              //     community.age > _filters['maxAge']) return false;

              // Apply gender filter
              if (_filters['gender'] != null &&
                  _filters['gender'] != community.gender) return false;

              // Apply language filter
              if (_filters['language'] != null &&
                  _filters['language'] != community.native_language)
                return false;

              return true;
            }).toList();

            return ListView.builder(
              itemCount: filteredCommunities.length,
              itemBuilder: (context, index) {
                final community = filteredCommunities[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: community.imageUrls.isNotEmpty
                          ? NetworkImage(community.imageUrls[0])
                          : const AssetImage(
                                  'assets/images/logo_no_background.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      community.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            community.bio,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Native in ${community.native_language}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Learning ${community.language_to_learn}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      redirect(community.id);
                    },
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
