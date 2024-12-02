import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../models/course.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  String? selectedDepartment;
  String? selectedProgram;
  String? selectedSemester;
  String? selectedClass;
  static const String selectedBatch = "32";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseProvider>(context);
    final courseData = provider.courseData;

    if (courseData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDepartment,
                      items: courseData.departments.keys.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartment = value;
                          selectedProgram = null;
                          selectedSemester = null;
                          selectedClass = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedDepartment != null) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Program',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedProgram,
                        items: courseData
                            .departments[selectedDepartment]!.programs.data.keys
                            .map((program) {
                          return DropdownMenuItem(
                            value: program,
                            child: Text(program),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedProgram = value;
                            selectedSemester = null;
                            selectedClass = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedProgram != null) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedSemester,
                        items: courseData.departments[selectedDepartment]!
                            .programs.data[selectedProgram]!
                            .map((semester) {
                          return DropdownMenuItem(
                            value: semester,
                            child: Text(semester),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSemester = value;
                            selectedClass = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedSemester != null) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedClass,
                        items: courseData.departments[selectedDepartment]!
                            .classes.data[selectedSemester]!
                            .map((className) {
                          return DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedClass = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: selectedClass != null
                  ? () {
                      provider.addCourse(Course(
                        department: selectedDepartment!,
                        program: selectedProgram!,
                        semester: selectedSemester!,
                        className: selectedClass!,
                        batch: selectedBatch,
                      ));
                      Navigator.pop(context);
                    }
                  : null,
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
