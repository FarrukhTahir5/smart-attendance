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
  bool isRegistering = false; // Flag to track if registration is in progress

  // Callback function to handle when registration is complete
  void _onRegistrationComplete() {
    setState(() {
      isRegistering = false; // Reset the flag after registration is complete
      _selectedIndex = 0; // Switch to the 'Mark Attendance' page
    });
  }

  // Callback function to handle when registration is complete
  void _onRegistration() {
    setState(() {
      isRegistering = true; // Reset the flag after registration is complete
    });
  }

  void _onItemTapped(int index) {
    if (isRegistering) {
      return; // Don't allow navigation to the 'Register Student' page while registering
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Now passing the callback function when initializing RegisterStudentPage
    final List<Widget> _pages = [
      const MarkAttendancePage(),
      RegisterStudentPage(
        onRegisterComplete: _onRegistrationComplete,
        onRegistering: _onRegistration,
      ),
    ];

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
