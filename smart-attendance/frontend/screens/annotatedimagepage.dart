import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';

class AnnotatedImagePage extends StatelessWidget {
  final String imagePath;
  final List<dynamic> recognizedStudents; // List of recognized student names
  final String meta;

  const AnnotatedImagePage({
    Key? key,
    required this.imagePath,
    required this.recognizedStudents,
    required this.meta,
  }) : super(key: key);

  // Function to download and save image in the selected directory
  Future<void> _downloadAndSaveImage(BuildContext context) async {
    try {
      // Ask the user to select a directory using the File Picker
      String? result = await FilePicker.platform.getDirectoryPath();

      if (result == null) {
        // If the user cancels the file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No directory selected')),
        );
        return;
      }

      // Get the selected directory path
      String directoryPath = result;

      // Get the image file name from the URL
      final fileName = imagePath.split('/').last;

      // Full path where the image will be saved
      final filePath = '$directoryPath/$fileName';

      // Download the image using Dio
      Dio dio = Dio();
      await dio.download(imagePath, filePath);

      // Show a success message once the download is complete
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image downloaded to $filePath')),
      );
    } catch (e) {
      // Handle any errors that occur during download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download image: $e')),
      );
    }
  }

  // Function to copy the recognized students' names to clipboard
  void _copyToClipboard(BuildContext context, String meta) {
    final studentsList = recognizedStudents.join('\n');
    Clipboard.setData(ClipboardData(text: meta + "\n" + studentsList));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recognized students copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotated Image'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display the image
            if (imagePath.isNotEmpty)
              Image.network(
                imagePath,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child; // If image is loaded, return the image
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ); // Show loading indicator while loading
                  }
                },
              )
            else
              const Text('No image available'),

            // Display recognized students
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ("B" +
                            provider.selectedBatch! +
                            "-" +
                            provider.selectedProgram!.toUpperCase() +
                            " " +
                            provider.selectedClass! +
                            ": " +
                            meta +
                            '_')
                        .replaceAll('_', '\n'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Recognized Students:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...recognizedStudents
                      .map((student) => Text(student))
                      .toList(),
                ],
              ),
            ),

            // Copy to clipboard button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _copyToClipboard(
                    context,
                    (provider.selectedClass! + meta + '_')
                        .replaceAll('_', '\n')),
                child: const Text('Copy Students List'),
              ),
            ),

            // Download Button
            if (imagePath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _downloadAndSaveImage(context),
                  child: const Text('Download Image'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
