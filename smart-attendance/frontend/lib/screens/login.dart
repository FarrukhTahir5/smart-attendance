import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gikattend/navigation/app_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Default values for email and password
  final TextEditingController _emailController =
      TextEditingController(text: 'faculty@giki.edu.pk');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password123');

  bool _saveLoginDetails = false;
  String? _jwtToken;

  @override
  Widget build(BuildContext context) {
    // Function to handle login
    Future<void> _login() async {
      final provider = Provider.of<CourseProvider>(context, listen: false);

      // API URL for login
      var loginUrl = '${provider.ipAddress}/login'; // Change to your server URL

      // Send POST request to the FastAPI login endpoint
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _emailController.text, // username here is the email
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // If the login is successful, parse the JWT token
        final data = jsonDecode(response.body);
        setState(() {
          _jwtToken = data['access_token']; // Store the JWT token
        });

        // You can now save the token in secure storage or shared preferences if required.
        print('Login successful, JWT Token: $_jwtToken');

        // Navigate to the next page (protected area)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const AppNavigation()), // Adjust to your next screen
        );
      } else {
        // If the login fails, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    }

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
            Text('Login', style: GoogleFonts.lato()),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Login Form
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Save Login Details Checkbox
                  CheckboxListTile(
                    title: Text('Save Login Details'),
                    value: _saveLoginDetails,
                    onChanged: (bool? value) {
                      setState(() {
                        _saveLoginDetails = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Full-width Login Button at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Make the button full width
              child: ElevatedButton(
                onPressed: _login, // Trigger the login function
                child: const Text('Login'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
