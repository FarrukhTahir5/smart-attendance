class Course {
  final String department;
  final String program;
  final String semester;
  final String className;
  final String batch;
  Course(
      {required this.department,
      required this.program,
      required this.semester,
      required this.className,
      required this.batch});

  // Add the fromJson method
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      className: json['className'],
      department: json['department'],
      program: json['program'],
      batch: json['batch'],
      semester: json['semester'],
    );
  }
}
