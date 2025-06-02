import 'package:bananatalk_app/pages/chat/chat_main.dart';
import 'package:bananatalk_app/pages/moments/moments_main.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/community/community_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key});

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      activePage = ProfileMain();
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
                  icon: Icon(Icons.chat), label: 'BanaTalk'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_search), label: 'Community'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.public_outlined), label: 'Moments'),

              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
              // BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Habarlar'),
              // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Shaxsiy'),
            ],
          ),
        ),
      ),
    );
  }
}
