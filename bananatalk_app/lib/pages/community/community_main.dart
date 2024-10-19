import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityMain extends ConsumerWidget {
  const CommunityMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsyncValue = ref.watch(communityProvider);
    final userId = ref
        .watch(authServiceProvider)
        .userId; // Assuming you have a userProvider that provides the current user's ID

    Future<void> _refresh() async {
      ref.refresh(communityProvider);
    }

    Future<void> redirect(id) async {
      Community community =
          await ref.watch(communityServiceProvider).getSingleCommunity(id: id);

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SingleCommunity(community: community)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Community'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.filter_list))
            ],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: communityAsyncValue.when(
          data: (communities) {
            // Filter out the community with the logged-in user's ID
            final filteredCommunities = communities
                .where((community) => community.id != userId)
                .toList();

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
                          : AssetImage('assets/images/logo_no_background.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      community.name,
                      style: TextStyle(
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
                      // Handle user tap
                      redirect(community.id);
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Failed to load users ${error}')),
        ),
      ),
    );
  }
}
