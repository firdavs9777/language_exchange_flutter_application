import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/profile/profile_moments.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';

class ProfileMain extends ConsumerWidget {
  const ProfileMain({Key? key}) : super(key: key);

  int calculateAge(String birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - int.parse(birthYear);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);
    final moment = ref.watch(momentsServiceProvider).count;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Profile'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Login()), // Replace with your login page widget
              );
              // Example action; adjust as needed
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: userAsyncValue.when(
        data: (user) {
          return FutureBuilder<String?>(
            future: SharedPreferences.getInstance()
                .then((prefs) => prefs.getString('count')),
            builder: (context, countSnapshot) {
              if (countSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (countSnapshot.hasError) {
                return Center(child: Text('Error: ${countSnapshot.error}'));
              } else {
                final String? count = countSnapshot.data;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
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
                                  SnackBar(
                                    content: Text('No images available'),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 70,
                              backgroundImage: user.imageUrls.isNotEmpty
                                  ? NetworkImage(user.imageUrls[0])
                                  : AssetImage(
                                          'assets/images/logo_no_background.png')
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Divider(color: Colors.grey),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Column(
                                children: [
                                  Text('0'),
                                  SizedBox(height: 4),
                                  Text('Following',
                                      style: TextStyle(fontFamily: 'Roboto')),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('0'),
                                  SizedBox(height: 4),
                                  Text('Followers',
                                      style: TextStyle(fontFamily: 'Roboto')),
                                ],
                              ),
                              InkWell(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileMoments(id: user.id),
                                    ),
                                  );
                                  ref
                                      .refresh(momentsServiceProvider)
                                      .getMomentsUser(id: user.id);
                                },
                                child: Column(
                                  children: [
                                    Text('$moment'),
                                    SizedBox(height: 4),
                                    Text('Moments',
                                        style: TextStyle(fontFamily: 'Roboto')),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text('0'),
                                  SizedBox(height: 4),
                                  Text('Visitors',
                                      style: TextStyle(fontFamily: 'Roboto')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
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
                                    Icon(Icons.person, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Self-Introduction',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Text(
                                  user.bio,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
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
                                    Icon(Icons.language, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Languages',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Native: ${user.native_language}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                Text(
                                  'Learning: ${user.language_to_learn}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Failed to load user: $error')),
      ),
    );
  }
}
