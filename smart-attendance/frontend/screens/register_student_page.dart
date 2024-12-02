import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gikattend/providers/course_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RegisterStudentPage extends StatefulWidget {
  const RegisterStudentPage({super.key});

  @override
  State<RegisterStudentPage> createState() => _RegisterStudentPageState();
}

class _RegisterStudentPageState extends State<RegisterStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _programController = TextEditingController();
  final _semesterController = TextEditingController();
  List<File> _images = []; // List to hold selected images
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _programController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  // Method to pick multiple images
  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseProvider>(context);

    // Function to handle the registration request using Dio
    Future<void> _registerStudent() async {
      if (_formKey.currentState!.validate()) {
        try {
          List<MultipartFile> files = [];
          for (var image in _images) {
            files.add(await MultipartFile.fromFile(image.path,
                filename: image.path.split('/').last));
          }
          FormData formData = FormData.fromMap({
            'name': _nameController.text,
            'rollno': _rollNoController.text,
            'batch_number': "32",
            'program': "ai",
            'files': files, // Send a list of files
          });

          print(formData.fields);
          // Instantiate Dio
          final dio = Dio();

          // Send the POST request
          final response = await dio.post(
            provider.ipAddress + '/register', // Update with your API endpoint
            data: formData,
          );

          // Check the response status code
          if (response.statusCode == 200) {
            final responseData = response.data;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message']),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to register student: ${response.data}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error occurred while registering student'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rollNoController,
                        decoration: const InputDecoration(
                          labelText: 'Roll Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter roll number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // TextFormField(
                      //   controller: _programController,
                      //   decoration: const InputDecoration(
                      //     labelText: 'Program',
                      //     border: OutlineInputBorder(),
                      //     prefixIcon: Icon(Icons.school),
                      //   ),
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return 'Please enter program';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(height: 16),
                      // TextFormField(
                      //   controller: _semesterController,
                      //   decoration: const InputDecoration(
                      //     labelText: 'Batch',
                      //     border: OutlineInputBorder(),
                      //     prefixIcon: Icon(Icons.calendar_today),
                      //   ),
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return 'Please enter Batch';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(height: 16),
                      // Button to pick multiple images
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Pick Images'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_images.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: _images.map((image) {
                            return Image.file(
                              image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _registerStudent,
                icon: const Icon(Icons.person_add),
                label: const Text('Register Student'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
