import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gikattend/navigation/attendance_Navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import './mark_attendance.dart';
import './add_course_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            SizedBox(
              height: 10,
            ),
            Text('My Courses', style: GoogleFonts.lato()),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Watermark Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.1, // Adjust the opacity to make the watermark subtle
              child: Image.asset(
                'assets/images/watermark.jpg', // Path to your watermark image
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          // Main content (your ListView or other widgets)
          Consumer<CourseProvider>(
            builder: (context, provider, child) {
              if (provider.myCourses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No courses added yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCoursePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Course'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: provider.myCourses.length,
                itemBuilder: (context, index) {
                  final course = provider.myCourses[index];
                  return Card(
                    child: ListTile(
                      title: Text(course.className),
                      subtitle:
                          Text('${course.department} - ${course.program}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        provider.setSelectedDepartment(course.department);
                        provider.setSelectedProgram(course.program);
                        provider.setSelectedSemester(course.semester);
                        provider.setSelectedClass(course.className);
                        provider.setSelectedBatch(course.batch);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AttendanceAndRegistrationNavigation(),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
