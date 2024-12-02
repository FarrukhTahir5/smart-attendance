import 'package:flutter/material.dart';
import 'package:gikattend/screens/mark_attendance.dart';
import 'package:gikattend/screens/register_student_page.dart';

class AttendanceAndRegistrationNavigation extends StatefulWidget {
  const AttendanceAndRegistrationNavigation({super.key});

  @override
  State<AttendanceAndRegistrationNavigation> createState() =>
      _AttendanceAndRegistrationNavigationState();
}

class _AttendanceAndRegistrationNavigationState
    extends State<AttendanceAndRegistrationNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MarkAttendancePage(),
    RegisterStudentPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Mark Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1_outlined),
            selectedIcon: Icon(Icons.person_add_alt_1),
            label: 'Register Student',
          ),
        ],
      ),
    );
  }
}
