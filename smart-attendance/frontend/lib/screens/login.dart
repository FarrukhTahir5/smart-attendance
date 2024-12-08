import 'package:flutter/material.dart';
import 'package:gikattend/navigation/app_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

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
                onPressed: () {
                  // Implement your login logic here
                  if (_saveLoginDetails) {
                    // Save email and password for next time (this can be done via shared preferences or secure storage)
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AppNavigation()),
                  );
                },
                child: const Text('Login'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
