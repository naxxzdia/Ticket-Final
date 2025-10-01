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
    const bg = Color(0xFF1A1A1A);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: _buildBottomNav(bg),
    );
  }

  Widget _buildBottomNav(Color bg) {
    const inactiveColor = Color(0xFF9E9E9E); // Gray 500
    const grad2 = Color(0xFFFF4081); // vivid pink
    const grad3 = Color(0xFF673AB7); // purple

    Shader _gradientShader(Rect bounds) => const LinearGradient(
          colors: [grad2, grad3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);

    Widget _gradIcon(IconData icon) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: _gradientShader,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // subtle glow
              Positioned(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(.18),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(icon),
            ],
          ),
        );

    BottomNavigationBarItem _item({
      required IconData icon,
      required String label,
      int? index,
    }) {
      return BottomNavigationBarItem(
        icon: Icon(icon, color: inactiveColor),
        activeIcon: _gradIcon(icon),
        label: label,
        tooltip: label,
      );
    }

    return BottomNavigationBar(
      backgroundColor: bg,
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      selectedItemColor: Colors.white, // overridden by ShaderMask visually
      unselectedItemColor: inactiveColor,
      onTap: (i) => setState(() => _currentIndex = i),
      items: [
        _item(icon: Icons.home_outlined, label: 'Home', index: 0),
        _item(icon: Icons.confirmation_number_outlined, label: 'Tickets', index: 1),
        _item(icon: Icons.person_outline, label: 'Profile', index: 2),
      ],
    );
  }
}