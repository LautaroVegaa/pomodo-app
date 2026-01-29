import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import '../features/stats/stats_page.dart';
import '../features/shared/widgets/app_bottom_nav.dart';

class TabShell extends StatefulWidget {
  const TabShell({super.key});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    StatsPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  AppNavSection _indexToSection(int index) {
    return index == 0 ? AppNavSection.focus : AppNavSection.stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
        child: AppBottomNav(
          selected: _indexToSection(_selectedIndex),
          onFocusTap: () => _onTabTapped(0),
          onStatsTap: () => _onTabTapped(1),
        ),
      ),
    );
  }
}
