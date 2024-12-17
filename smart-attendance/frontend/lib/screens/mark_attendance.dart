import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Add the http package
import 'package:gikattend/providers/course_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Add image_picker package
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import './preview_attendance_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'package:image/image.dart' as img;

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0; // Track the selected camera index
  bool _isCameraMode =
      false; // Flag to toggle between camera and past attendance view
  bool _isGalleryMode = false; // Flag to toggle between gallery and camera mode

  // To store past attendance fetched from the API
  List<AttendanceRecord> pastAttendances = [];

  DeviceOrientation _currentOrientation = DeviceOrientation.portraitUp;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchExcelFiles(); // Fetch attendance data when page is initialized
    // Listen to accelerometer data
    accelerometerEvents.listen((AccelerometerEvent event) {
      _checkOrientation(event);
    });
  }

  // Function to fetch Excel files from the FastAPI endpoint
  Future<void> _fetchExcelFiles() async {
    var provider = Provider.of<CourseProvider>(context, listen: false);
    final String jwt = provider.jwt;

    try {
      // Define the URL for the FastAPI endpoint, passing the course folder
      final String courseFolder = provider.selectedClass! +
          "_" +
          provider.selectedBatch! +
          "-" +
          provider.selectedProgram!; // Set the appropriate course folder
      print(courseFolder);
      final String url = provider.ipAddress +
          '/files/$courseFolder'; // Change the URL accordingly

      // Make the GET request with the JWT token in the headers
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization':
              'Bearer $jwt', // Include JWT token for authentication
        },
      );

      if (response.statusCode == 200) {
        // Parse the response data
        List<dynamic> data = json.decode(response.body);

        setState(() {
          // Map the response data to the appropriate data model (e.g., file name and path)
          pastAttendances = data.map((file) {
            return AttendanceRecord(
              date: file['file_name'], // Use 'file_name' from the API response
              fileUrl:
                  file['file_path'], // Use 'file_path' from the API response
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load Excel files');
      }
    } catch (e) {
      print('Error fetching files: $e');
      // Handle error (e.g., show a message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching files data.')),
      );
    }
  }

  Future<void> _initializeCamera() async {
    // Get available cameras
    _cameras = await availableCameras();
    // Initialize the controller for the selected camera
    _initializeCameraController();
  }

  void _initializeCameraController() {
    final selectedCamera = _cameras[_selectedCameraIndex];

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _toggleCamera() {
    // Switch to the next camera
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    _initializeCameraController();
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PreviewAttendancePage(imagePath: pickedFile.path),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.selectedClass!, style: GoogleFonts.lato()),
        elevation: 0,
        actions: [
          // Gallery option button when in Camera Mode
          if (_isCameraMode)
            IconButton(
              onPressed: () {
                setState(() {
                  _isGalleryMode = !_isGalleryMode; // Toggle gallery mode
                });
                if (_isGalleryMode) {
                  _pickImageFromGallery(); // Open gallery when in gallery mode
                }
              },
              icon:
                  Icon(_isGalleryMode ? Icons.camera_alt : Icons.photo_library),
            ),
        ],
      ),
      body: _isCameraMode ? _buildCameraMode() : _buildPastAttendanceMode(),
      floatingActionButton: FloatingActionButton(
        heroTag: "324231",
        onPressed: () {
          setState(() {
            _isCameraMode = !_isCameraMode; // Toggle mode
            _isGalleryMode =
                false; // Ensure gallery mode is off when in camera mode
          });
        },
        child: Icon(_isCameraMode ? Icons.list : Icons.camera_alt),
      ),
    );
  }

  void _checkOrientation(AccelerometerEvent event) {
    double x = event.x;
    double y = event.y;

    // Check if device is in landscape mode (either left or right)
    if (x.abs() > y.abs()) {
      if (x > 0) {
        setState(() {
          _currentOrientation = DeviceOrientation.landscapeRight;
          print('Landscape Right');
        });
      } else {
        setState(() {
          _currentOrientation = DeviceOrientation.landscapeLeft;
          print('Landscape Left');
        });
      }
    } else {
      setState(() {
        _currentOrientation = DeviceOrientation.portraitUp;
      });
    }
  }

  Future<File> _rotateImage(String imagePath) async {
    // Read the image file
    File imageFile = File(imagePath);
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      return imageFile; // Return original if decoding fails
    }

    // Rotate the image based on current orientation
    img.Image rotatedImage;
    switch (_currentOrientation) {
      case DeviceOrientation.landscapeLeft:
        rotatedImage = img.copyRotate(image, 90);
        break;
      case DeviceOrientation.landscapeRight:
        rotatedImage = img.copyRotate(image, -90);
        break;
      default:
        return imageFile; // No rotation for portrait
    }

    // Save the rotated image
    File rotatedFile = File(imagePath)
      ..writeAsBytesSync(img.encodeJpg(rotatedImage));

    return rotatedFile;
  }

  Widget _buildCameraMode() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_isCameraMode && !_isGalleryMode)
                CameraPreview(_controller!)
              else
                Container(),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Reverse camera button (only visible in camera mode)
                    if (_isCameraMode && !_isGalleryMode)
                      IconButton(
                        onPressed: _toggleCamera,
                        icon: const Icon(
                          Icons.switch_camera,
                          size: 32,
                        ),
                        color: Colors.white,
                      ),
                    // Capture photo button (only visible in camera mode)
                    if (_isCameraMode && !_isGalleryMode)
                      FloatingActionButton(
                        onPressed: () async {
                          try {
                            await _initializeControllerFuture;
                            final image = await _controller!.takePicture();
                            // Rotate the image if necessary
                            final rotatedImage = await _rotateImage(image.path);

                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreviewAttendancePage(
                                    imagePath: rotatedImage.path,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error taking picture: $e');
                          }
                        },
                        child: const Icon(Icons.camera),
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildPastAttendanceMode() {
    if (pastAttendances.isEmpty) {
      return Center(child: Text("No past attendance records found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pastAttendances.length,
      itemBuilder: (context, index) {
        final attendance = pastAttendances[index];

        return Card(
          child: ListTile(
            title: Text('Attendance for ${attendance.date}'),
            trailing: IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                // Handle download logic (for demo, we will show a message)
                _downloadAttendance(context, attendance);
              },
            ),
          ),
        );
      },
    );
  }
}

// Function to fetch file download link from the FastAPI endpoint
Future<String> getFileDownloadLink(String filePath, BuildContext ctx) async {
  var provider = Provider.of<CourseProvider>(ctx, listen: false);

  final response = await http.post(
    Uri.parse(provider.ipAddress + '/get_file_download_link'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'file_path': filePath}),
  );

  if (response.statusCode == 200) {
    // Parse the file download link from the response
    final data = json.decode(response.body);
    return data['file_url'];
  } else {
    throw Exception('Failed to get file download link');
  }
}

Future<void> _downloadAttendance(
    BuildContext context, AttendanceRecord attendance) async {
  // Request storage permissions
  var storagePermission = await Permission.storage.request();
  var manageStoragePermission =
      await Permission.manageExternalStorage.request();

  if (!storagePermission.isGranted && !manageStoragePermission.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Storage permissions are required to download files')),
    );
    return;
  }

  String filePath = attendance.fileUrl;
  String fileName = filePath.split('/').last;

  try {
    // Get the full file URL from the FastAPI endpoint
    var provider = Provider.of<CourseProvider>(context, listen: false);
    String fullUrl =
        provider.ipAddress + await getFileDownloadLink(filePath, context);

    // Try to get a safe download directory
    Directory? downloadsDir = await getExternalStorageDirectory();
    if (downloadsDir == null) {
      throw Exception('Could not access external storage directory');
    }

    // Ensure the directory exists and is writable
    String userDirectoryPath = '${downloadsDir.path}/Documents/Downloads';
    Directory userDirectory = Directory(userDirectoryPath);

    // Create the directory if it doesn't exist
    if (!await userDirectory.exists()) {
      await userDirectory.create(recursive: true);
    }

    // Prompt user to choose download folder
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
      initialDirectory: userDirectoryPath,
    );

    if (selectedDirectory == null) {
      // User canceled the folder selection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download canceled')),
      );
      return;
    }

    // Sanitize the filename to remove any potentially problematic characters
    String sanitizedFileName = _sanitizeFileName(fileName);

    // Create the full path for the file
    String savePath = '$selectedDirectory/$sanitizedFileName';

    // Download the file using Dio
    Dio dio = Dio();
    await dio.download(
      fullUrl,
      savePath,
      options: Options(
        headers: {
          HttpHeaders.acceptEncodingHeader: '*', // Handle different encodings
        },
      ),
    );

    // Show success message with file path
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File downloaded to: $savePath')),
    );
  } catch (e) {
    print('Download error details: $e'); // Log full error details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: ${e.toString()}')),
    );
  }
}

// Helper function to sanitize filename
String _sanitizeFileName(String fileName) {
  // Remove any characters that might cause issues in file paths
  return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
}

class AttendanceRecord {
  final String date;
  final String fileUrl; // The file URL or local path to the PDF

  AttendanceRecord({required this.date, required this.fileUrl});
}
