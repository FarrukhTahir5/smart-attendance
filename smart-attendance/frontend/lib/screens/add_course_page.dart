import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/course_provider.dart';
import 'package:provider/provider.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final TextEditingController courseNameController = TextEditingController();
  String? selectedBatch;
  String? selectedProgram;
  List<String> batches = [];
  List<String> programs = [];

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  // Fetch list of batches from the server
  Future<void> fetchBatches() async {
    final provider = Provider.of<CourseProvider>(context, listen: false);
    final String apiUrl =
        provider.ipAddress + '/get-batches'; // Adjust the endpoint

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          batches = List<String>.from(data['batches']);
        });
      } else {
        throw Exception('Failed to load batches');
      }
    } catch (e) {
      print('Error fetching batches: $e');
    }
  }

  // Fetch programs based on the selected batch
  Future<void> fetchPrograms(String batch) async {
    final provider = Provider.of<CourseProvider>(context, listen: false);
    final String apiUrl =
        provider.ipAddress + '/get-programs/$batch'; // Adjust the endpoint

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          programs = List<String>.from(data['programs']);
          selectedProgram = null; // Reset program selection
        });
      } else {
        throw Exception('Failed to load programs');
      }
    } catch (e) {
      print('Error fetching programs: $e');
    }
  }

  // Add course to API
  Future<void> addCourseToAPI(
      String courseName, String batchNumber, String program) async {
    final provider = Provider.of<CourseProvider>(context, listen: false);
    final String apiUrl = provider.ipAddress +
        '/add-course/'; // Replace with your actual API endpoint

    final String token = provider.jwt;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course_name': courseName,
          'batch_number':
              batchNumber + '-' + program, // Combine batch and program
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(responseBody['message']),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to previous page
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final errorBody = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(errorBody['detail'] ?? 'Something went wrong'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to add course. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Course'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: courseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: selectedBatch,
                      hint: const Text('Select Batch'),
                      onChanged: (value) {
                        setState(() {
                          selectedBatch = value;
                          selectedProgram =
                              null; // Reset program when batch changes
                          fetchPrograms(value!);
                        });
                      },
                      items: batches.map((batch) {
                        return DropdownMenuItem<String>(
                          value: batch,
                          child: Text(batch),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: selectedProgram,
                      hint: const Text('Select Program'),
                      onChanged: (value) {
                        setState(() {
                          selectedProgram = value;
                        });
                      },
                      items: programs.map((program) {
                        return DropdownMenuItem<String>(
                          value: program,
                          child: Text(program),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final courseName = courseNameController.text.trim();
                final batchNumber = selectedBatch ?? '';
                final program = selectedProgram ?? '';

                if (courseName.isNotEmpty &&
                    batchNumber.isNotEmpty &&
                    program.isNotEmpty) {
                  // Send the course data to the backend
                  await addCourseToAPI(courseName, batchNumber, program);
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: const Text('Please fill in all fields.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }
}
