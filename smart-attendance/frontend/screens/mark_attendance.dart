import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gikattend/providers/course_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Add image_picker package
import 'package:provider/provider.dart';
import './preview_attendance_page.dart';

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

  // Demo data for past attendance
  List<AttendanceRecord> pastAttendances = [
    AttendanceRecord(
        date: '2024-11-01', fileUrl: 'assets/sample_attendance_1.pdf'),
    AttendanceRecord(
        date: '2024-11-10', fileUrl: 'assets/sample_attendance_2.pdf'),
    AttendanceRecord(
        date: '2024-11-15', fileUrl: 'assets/sample_attendance_3.pdf'),
    AttendanceRecord(
        date: '2024-11-20', fileUrl: 'assets/sample_attendance_4.pdf'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreviewAttendancePage(
                                    imagePath: image.path,
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
                _downloadAttendance(attendance);
              },
            ),
          ),
        );
      },
    );
  }

  void _downloadAttendance(AttendanceRecord attendance) {
    // In a real scenario, this is where you'd initiate a file download.
    // For now, we just show a placeholder message.
    debugPrint('Downloading attendance for ${attendance.date}...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Downloading attendance for ${attendance.date}...')),
    );
  }
}

class AttendanceRecord {
  final String date;
  final String
      fileUrl; // The file URL or local path to the PDF, for demo purposes

  AttendanceRecord({required this.date, required this.fileUrl});
}
