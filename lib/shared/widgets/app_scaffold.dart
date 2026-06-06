import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/board/screens/board_screen.dart';
import '../../features/planner/screens/planner_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/team/screens/team_screen.dart';
import '../../state/team_state.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    //load the user teams when the app first opens after login
    Future.microtask(() {
      if (mounted) context.read<TeamState>().loadTeams();
    });
  }

  static const List<Widget> _pages = [
    BoardScreen(),
    PlannerScreen(),
    TeamScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.view_kanban_outlined),
      selectedIcon: Icon(Icons.view_kanban),
      label: 'Board',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Planner',
    ),
    NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: 'Team',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _destinations,
      ),
    );
  }
}
