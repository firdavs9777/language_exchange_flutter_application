import 'package:bananatalk_app/pages/profile/about/profile_single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMoments extends ConsumerWidget {
  const ProfileMoments({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<List<Moments>> moments =
        ref.watch(momentsServiceProvider).getMomentsUser(id: id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Moments'),
      ),
      body: FutureBuilder<List<Moments>>(
        future: moments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No moments found.'));
          } else {
            List<Moments> moments = snapshot.data!;
            return ListView.builder(
              itemCount: moments.length,
              itemBuilder: (context, index) {
                return ProfileSingleMoment(moment: moments[index]);
              },
            );
          }
        },
      ),
    );
  }
}
