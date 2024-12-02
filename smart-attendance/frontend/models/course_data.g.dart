// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseData _$CourseDataFromJson(Map<String, dynamic> json) => CourseData(
      departments: (json['departments'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Department.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$CourseDataToJson(CourseData instance) =>
    <String, dynamic>{
      'departments': instance.departments,
    };

Department _$DepartmentFromJson(Map<String, dynamic> json) => Department(
      programs: Programs.fromJson(json['programs'] as Map<String, dynamic>),
      classes: Classes.fromJson(json['classes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DepartmentToJson(Department instance) =>
    <String, dynamic>{
      'programs': instance.programs,
      'classes': instance.classes,
    };

Programs _$ProgramsFromJson(Map<String, dynamic> json) => Programs(
      data: (json['data'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$ProgramsToJson(Programs instance) => <String, dynamic>{
      'data': instance.data,
    };

Classes _$ClassesFromJson(Map<String, dynamic> json) => Classes(
      data: (json['data'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$ClassesToJson(Classes instance) => <String, dynamic>{
      'data': instance.data,
    };
