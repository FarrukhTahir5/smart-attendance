import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../models/course_data.dart';
import '../models/course.dart';

class CourseProvider with ChangeNotifier {
  CourseData? _courseData;
  final List<Course> _myCourses = [];
  String? _selectedDepartment;
  String? _selectedProgram;
  String? _selectedSemester;
  String? _selectedClass;
  String? _selectedBatch;

  String ipAddress = "http://192.168.215.136:8000";
  String jwt = "";

  CourseData? get courseData => _courseData;
  List<Course> get myCourses => List.unmodifiable(_myCourses);
  String? get selectedDepartment => _selectedDepartment;
  String? get selectedProgram => _selectedProgram;
  String? get selectedSemester => _selectedSemester;
  String? get selectedClass => _selectedClass;
  String? get selectedBatch => _selectedBatch;

  CourseProvider() {
    // Initialize with dummy data
    _courseData = CourseData(
      departments: {
        "FCSE": Department(
          programs: Programs(
            data: {
              "Computer Science": [
                "Semester 1",
                "Semester 2",
                "Semester 3",
                "Semester 4",
                "Semester 5",
                "Semester 6",
                "Semester 7",
                "Semester 8"
              ],
              "Artificial Intelligence": [
                "Semester 1",
                "Semester 2",
                "Semester 3",
                "Semester 4",
                "Semester 5",
                "Semester 6",
                "Semester 7",
                "Semester 8"
              ],
            },
          ),
          classes: Classes(
            data: {
              "Semester 1": ["CS101 A", "MT 101", "AI302", "IF101", "CS101 B"],
              "Semester 2": ["Class C", "Class D"],
              "Semester 3": ["Class E"],
            },
          ),
        ),
        "MGS": Department(
          programs: Programs(
            data: {
              "Physics": ["Semester 1", "Semester 2"],
              "Chemistry": ["Semester 1"],
            },
          ),
          classes: Classes(
            data: {
              "Semester 1": ["Class F", "Class G"],
              "Semester 2": ["Class H"],
            },
          ),
        ),
      },
    );

    // Initialize the user's courses with some dummy data
    _myCourses.addAll([
      Course(
        department: "FCSE",
        program: "ai",
        semester: "Semester 1",
        className: "CS 101",
        batch: "32",
      ),
      Course(
        department: "FCSE",
        program: "ce",
        semester: "Semester 2",
        className: "MT 102",
        batch: "32",
      ),
    ]);
  }

  void setCourseData(CourseData data) {
    _courseData = data;
    notifyListeners();
  }

  void addCourse(Course course) {
    if (!_myCourses.any((c) =>
        c.department == course.department &&
        c.program == course.program &&
        c.semester == course.semester &&
        c.className == course.className)) {
      _myCourses.add(course);
      notifyListeners();
    }
  }

  void removeCourse(Course course) {
    _myCourses.removeWhere((c) =>
        c.department == course.department &&
        c.program == course.program &&
        c.semester == course.semester &&
        c.className == course.className);
    notifyListeners();
  }

  void setSelectedDepartment(String department) {
    _selectedDepartment = department;
    _selectedProgram = null;
    _selectedSemester = null;
    _selectedClass = null;
    notifyListeners();
  }

  void setSelectedProgram(String program) {
    _selectedProgram = program;
    _selectedSemester = null;
    _selectedClass = null;
    notifyListeners();
  }

  void setSelectedSemester(String semester) {
    _selectedSemester = semester;
    _selectedClass = null;
    notifyListeners();
  }

  void setSelectedClass(String className) {
    _selectedClass = className;
    notifyListeners();
  }

  void setSelectedBatch(String batch) {
    _selectedBatch = batch;
  }
}
