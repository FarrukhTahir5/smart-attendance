import 'package:json_annotation/json_annotation.dart';

part 'course_data.g.dart';

@JsonSerializable()
class CourseData {
  final Map<String, Department> departments;

  CourseData({required this.departments});

  // JSON Serialization boilerplate
  factory CourseData.fromJson(Map<String, dynamic> json) =>
      _$CourseDataFromJson(json);
  Map<String, dynamic> toJson() => _$CourseDataToJson(this);
}

@JsonSerializable()
class Department {
  final Programs programs;
  final Classes classes;

  Department({required this.programs, required this.classes});

  // JSON Serialization boilerplate
  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentToJson(this);
}

@JsonSerializable()
class Programs {
  final Map<String, List<String>> data;

  Programs({required this.data});

  // JSON Serialization boilerplate
  factory Programs.fromJson(Map<String, dynamic> json) =>
      _$ProgramsFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramsToJson(this);
}

@JsonSerializable()
class Classes {
  final Map<String, List<String>> data;

  Classes({required this.data});

  // JSON Serialization boilerplate
  factory Classes.fromJson(Map<String, dynamic> json) =>
      _$ClassesFromJson(json);
  Map<String, dynamic> toJson() => _$ClassesToJson(this);
}
