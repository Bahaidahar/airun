import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  late stt.SpeechToText _speechToText;
  bool _isRecording = false;
  String _recordedText = '';
  bool _photoTaken = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _speechToText = stt.SpeechToText();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.high);

    await _cameraController.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // Take a photo using the camera and send it to the server
  Future<void> _takePhoto() async {
    if (!_isCameraInitialized) return;
    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _photoTaken = true;
      });

      // Send the photo to the server
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://your-server-endpoint.com/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        print('Photo uploaded successfully');
      } else {
        print('Failed to upload photo');
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  // Start recording voice and convert speech to text
  void _startVoiceRecording() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _isRecording = true;
      });
      _speechToText.listen(
        localeId: 'ru_RU', // Set the locale to Russian
        onResult: (result) {
          setState(() {
            _recordedText = result.recognizedWords;
          });
        },
      );
    }
  }

  // Stop recording voice and clear the text
  void _stopVoiceRecording() {
    _speechToText.stop();
    setState(() {
      _isRecording = false;
      _recordedText = ''; // Clear the recorded text
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen camera preview
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController),
            )
          else
            const Center(child: Text('Initializing Camera...')),

          // Buttons overlay
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Icon Button
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                // Voice Icon Button
                GestureDetector(
                  onTap:
                      _isRecording ? _stopVoiceRecording : _startVoiceRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
