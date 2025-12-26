import 'package:bananatalk_app/pages/chat/chat_main.dart';
import 'package:bananatalk_app/pages/moments/moments_main.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/community/community_main.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key, this.initialIndex = 0});
  
  final int initialIndex;

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  late int _selectedPageIndex;

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.initialIndex;
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch badgeCountProvider directly to ensure it updates globally, even on other tabs
    // The badgeCountProvider.messages is automatically updated by chatPartnersProvider
    final badgeCount = ref.watch(badgeCountProvider);
    final messageCount = badgeCount.messages;
    
    var activePageTitle = 'ChatList';
    Widget activePage = ChatMain();

    if (_selectedPageIndex == 1) {
      activePageTitle = 'Community';
      activePage = const CommunityMain();
    } else if (_selectedPageIndex == 2) {
      activePageTitle = 'Moments';
      activePage = MomentsMain();
    } else if (_selectedPageIndex == 3) {
      activePageTitle = 'Profile';
      activePage = const ProfileMain();
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: activePage,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey, // Set your desired border color
                width: 1.0, // Set the width of the border
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: 3,
            onTap: _selectPage,
            currentIndex: _selectedPageIndex,
            selectedItemColor: Colors.blue,
            items: [
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('$messageCount'),
                  isLabelVisible: messageCount > 0,
                  backgroundColor: const Color(0xFF00BFA5),
                  child: const Icon(Icons.chat),
                ),
                label: AppLocalizations.of(context)!.banaTalk,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_search),
                label: AppLocalizations.of(context)!.community,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.public_outlined),
                label: AppLocalizations.of(context)!.moments,
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('${badgeCount.notifications}'),
                  isLabelVisible: badgeCount.notifications > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.person_outline),
                ),
                label: AppLocalizations.of(context)!.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
