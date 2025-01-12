import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/profile/profile_edit.dart';
import 'package:bananatalk_app/pages/profile/profile_followers.dart';
import 'package:bananatalk_app/pages/profile/profile_followings.dart';
import 'package:bananatalk_app/pages/profile/profile_left_drawer.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/profile/profile_moments.dart';

class ProfileMain extends ConsumerStatefulWidget {
  const ProfileMain({Key? key}) : super(key: key);

  @override
  _ProfileMainState createState() => _ProfileMainState();
}

class _ProfileMainState extends ConsumerState<ProfileMain> {
  Future<void> _refresh() async {
    ref.refresh(userProvider);
  }

  Future<void> _redirect() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const ProfileEdit()));
  }

  int _calculateAge(String birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - int.parse(birthYear);
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(authServiceProvider).getLoggedInUser();
    final moment = ref.watch(momentsServiceProvider);

    return Scaffold(
      endDrawer: Builder(
        builder: (context) {
          return FutureBuilder<Community>(
            future: userAsyncValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No user data available.'));
              }

              final user = snapshot.data!;
              return LeftDrawer(user: user);
            },
          );
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
      ),
      body: FutureBuilder<Community>(
        future: userAsyncValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No user data available.'));
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      _redirect();
                    },
                    child: Row(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              if (user.imageUrls.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageGallery(
                                      imageUrls: user.imageUrls,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No images available'),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: user.imageUrls.isNotEmpty
                                  ? NetworkImage(user.imageUrls[0])
                                  : const AssetImage(
                                          'assets/images/logo_no_background.png')
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Center(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios, // Arrow icon
                          size: 20,
                          color: Colors.grey, // Change color if necessary
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildStatCard(
                          context: context,
                          label: 'Following',
                          value: user.followings.length,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileFollowings(id: user.id),
                              ),
                            ).then((_) => _refresh());
                          },
                        ),
                        _buildStatCard(
                          context: context,
                          label: 'Followers',
                          value: user.followers.length,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileFollowers(id: user.id),
                              ),
                            ).then((_) => _refresh());
                          },
                        ),
                        _buildMomentsStat(context, user),
                        _buildStatCard(
                          context: context,
                          label: 'Visitors',
                          value: 0,
                          onTap: null,
                        ),
                      ],
                    ),
                  ),
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Self-Introduction',
                    content: user.bio,
                  ),
                  _buildInfoCard(
                    icon: Icons.language,
                    title: 'Languages',
                    content:
                        'Native: ${user.native_language}\nLearning: ${user.language_to_learn}',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required int value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value.toString()),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMomentsStat(BuildContext context, Community user) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileMoments(id: user.id),
          ),
        ).then((_) =>
            ref.refresh(momentsServiceProvider).getMomentsUser(id: user.id));
      },
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final momentsAsyncValue =
                  ref.watch(momentsServiceProvider).getMomentsUser(id: user.id);

              return FutureBuilder(
                future: momentsAsyncValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('0');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('0');
                  } else {
                    return Text(snapshot.data!.length.toString());
                  }
                },
              );
            },
          ),
          const SizedBox(height: 4),
          const Text('Moments', style: TextStyle(fontFamily: 'Roboto')),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }
}
