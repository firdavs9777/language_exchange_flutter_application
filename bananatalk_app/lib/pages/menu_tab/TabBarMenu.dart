import 'package:bananatalk_app/pages/chat/chat_main.dart';
import 'package:bananatalk_app/pages/moments/moments_main.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/community/community_main.dart';
import 'package:bananatalk_app/pages/explore/explore_main.dart';
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

    Widget activePage;
    switch (_selectedPageIndex) {
      case 0:
        activePage = ChatMain();
        break;
      case 1:
        activePage = const CommunityMain();
        break;
      case 2:
        activePage = const ExploreMain(); // New explore/search tab in the middle
        break;
      case 3:
        activePage = MomentsMain();
        break;
      case 4:
        activePage = const ProfileMain();
        break;
      default:
        activePage = ChatMain();
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
                color: Colors.grey[300]!,
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: _selectPage,
            currentIndex: _selectedPageIndex,
            selectedItemColor: const Color(0xFF00BFA5),
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: [
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('$messageCount'),
                  isLabelVisible: messageCount > 0,
                  backgroundColor: const Color(0xFF00BFA5),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                activeIcon: Badge(
                  label: Text('$messageCount'),
                  isLabelVisible: messageCount > 0,
                  backgroundColor: const Color(0xFF00BFA5),
                  child: const Icon(Icons.chat_bubble),
                ),
                label: AppLocalizations.of(context)!.banaTalk,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline),
                activeIcon: const Icon(Icons.people),
                label: AppLocalizations.of(context)!.community,
              ),
              // New Explore/Search tab in the middle (like Instagram)
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search, size: 28),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.public_outlined),
                activeIcon: const Icon(Icons.public),
                label: AppLocalizations.of(context)!.moments,
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('${badgeCount.notifications}'),
                  isLabelVisible: badgeCount.notifications > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.person_outline),
                ),
                activeIcon: Badge(
                  label: Text('${badgeCount.notifications}'),
                  isLabelVisible: badgeCount.notifications > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.person),
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
