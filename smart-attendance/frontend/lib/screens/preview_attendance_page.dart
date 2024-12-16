import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import 'package:dio/dio.dart';
import './annotatedimagepage.dart';

class PreviewAttendancePage extends StatefulWidget {
  final String imagePath;

  const PreviewAttendancePage({
    super.key,
    required this.imagePath,
  });

  @override
  _PreviewAttendancePageState createState() => _PreviewAttendancePageState();
}

class _PreviewAttendancePageState extends State<PreviewAttendancePage> {
  bool _isLoading = false; // To track the loading state
  List<dynamic> recognizedStudents =
      []; // List to hold recognized students' names

  String meta = "";

  Future<void> _sendAttendance(BuildContext context) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final provider = Provider.of<CourseProvider>(context, listen: false);

    try {
      final formData = FormData.fromMap({
        'dept': provider.selectedDepartment,
        'program': provider.selectedProgram,
        'sem': provider.selectedSemester,
        'class_': provider.selectedClass,
        'batch_number': provider.selectedBatch,
        'file': await MultipartFile.fromFile(widget.imagePath),
        'token': provider.jwt
      });

      final dio = Dio();
      dio.options.headers = {
        'Authorization':
            'Bearer ${provider.jwt}', // Add token in Authorization header
      };

      final response = await dio.post(
        provider.ipAddress + '/mark-attendance',
        data: formData,
      );

      if (response.statusCode == 200) {
        if (response.data['message'] == "800") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('No Faces Found Take A Proper Image & Try Again!')),
          );
          Navigator.pop(context);
        }
        print(response.data);
        final annotatedImagePath =
            provider.ipAddress + response.data['annotated_image_url'];

        // Extract recognized students' names from the response
        recognizedStudents = List<String>.from(response
                .data['recognized_students']
                ?.map((item) => item.toString()) ??
            []);

        meta = response.data['attendance_meta'];

        print(recognizedStudents);
        print(meta);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance marked successfully')),
          );

          // Navigate to the page to display the annotated image and recognized students
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnotatedImagePage(
                imagePath: annotatedImagePath,
                recognizedStudents: recognizedStudents,
                meta: meta,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking attendance: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Hide the loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Attendance'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _sendAttendance(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Mark Attendance'),
            ),
          ),
        ],
      ),
    );
  }
}
