import 'package:flutter/material.dart';
import 'package:stephenscalender2024/addevent/bookmarks.dart';
import 'package:stephenscalender2024/alerts/reminders_page.dart';
import 'package:stephenscalender2024/eventshome/events_home.dart';
import 'package:stephenscalender2024/explore/explore_page.dart';
import 'package:stephenscalender2024/noticeboard/noticeboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pageIndex,
        onDestinationSelected: (value) {
          setState(() {
            pageIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'For You',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _currentPage() {
    switch (pageIndex) {
      case 0:
        return const EventsHome();
      case 1:
        return const ExplorePage();
      case 2:
        return const Bookmarks();
      case 3:
        return const NoticeboardPage();
      case 4:
        return const RemindersPage();
      default:
        return const EventsHome();
    }
  }
}
