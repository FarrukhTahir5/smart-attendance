import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './login.dart'; // Import the LoginPage

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 130,
        title: Column(
          children: [
            Image.asset(
              'assets/images/logo.png',
              scale: 2.3,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Smart Attendance System',
              style: GoogleFonts.lato(
                color: Colors.white, // Set the color to white
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // App description
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Welcome!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(
                            'assets/images/rector.jpg'), // Rector's image
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This AI-Powered Smart Attendance System was developed with the support and encouragement of the Rector of GIKI, Dr. Fazal Ahmed Khalid (S.I.), whose vision for integrating technology into academia inspired this initiative.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Team Section
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Meet the Team',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TeamMemberCard(
                    name: 'Dr. Ali Imran',
                    role: 'Project & Technical Lead\nAssistant Professor, FCSE',
                    imagePath: 'assets/images/aliimran.jpg',
                  ),
                  TeamMemberCard(
                    name: 'Abdullah Noor',
                    role: 'Core Developer\n UnderGrad Student FCSE',
                    imagePath: 'assets/images/abdullah.jpg',
                  ),
                  TeamMemberCard(
                    name: 'Engr. Farrukh Tahir',
                    role: 'Core Developer,\n Lab Engineer FCSE',
                    imagePath: 'assets/images/farrukh.jpg',
                  ),
                  const SizedBox(height: 20),

                  // Special Thanks Section
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Special Thanks',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TeamMemberCard(
                    name: 'Dr Khurram Jadoon',
                    role: 'Technical Consultant, Assistant Professor FCSE',
                    imagePath: 'assets/images/khurram.jpg',
                  ),
                  TeamMemberCard(
                    name: 'Mr Sajid Ali',
                    role: 'Technical Consultant, Lecturer, FCSE',
                    imagePath: 'assets/images/sajid.jpeg',
                  ),
                ],
              ),
            ),
          ),
          // Align the Faculty Login button at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity, // Makes the button take up full width
                child: MaterialButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(
                    "Faculty Login",
                    style: GoogleFonts.lato(
                      color: Colors.white, // Set the color to white
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TeamMemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String imagePath;

  const TeamMemberCard({
    required this.name,
    required this.role,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(imagePath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
