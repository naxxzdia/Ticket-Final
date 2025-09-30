import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'home_tab.dart';
import 'tickets_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        const HomeTab(),
        const TicketsTab(),
        ProfileScreen(onSwitchTab: (i) => setState(() => _currentIndex = i)),
      ];

  // Removed old inactivity timer logic

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.greenAccent.shade400,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}