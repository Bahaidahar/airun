import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http_parser/http_parser.dart';

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
  File? _photoFile;
  bool _isUploading = false;
  String _activeModal = ''; // 'photo' or 'voice'
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

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

  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || _activeModal.isNotEmpty) return;
    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _photoFile = File(image.path);
        _photoTaken = true;
        _activeModal = 'photo';
      });
      // Call the upload method after taking the photo
      await _uploadPhotoToServer(_photoFile!);
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  Future<void> _uploadPhotoToServer(File photoFile) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://172.20.10.4:8000/api/v1/ai/gpt-photo'),
      );

      request.headers.addAll({
        'accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        photoFile.path,
        contentType: MediaType('image', 'png'), // Set the MIME type if needed
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var responseData = json.decode(responseBody);
        String responseText = responseData['response'];

        print('Server response: $responseText');
        _speakResponse(responseText);
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading photo: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _activeModal = '';
      });
    }
  }

  void _startVoiceRecording() async {
    if (_activeModal.isNotEmpty) return;
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _isRecording = true;
        _activeModal = 'voice';
      });
      _speechToText.listen(
        localeId: 'ru_RU',
        onResult: (result) {
          setState(() {
            _recordedText = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopVoiceRecording() {
    _speechToText.stop();
    setState(() {
      _isRecording = false;
      _activeModal = '';
    });
    _sendTextToServer();
  }

  Future<void> _sendTextToServer() async {
    if (_recordedText.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.4:8000/api/v1/ai/gpt-text'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': _recordedText}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(
            utf8.decode(response.bodyBytes)); // Decode the bytes to UTF-8
        String responseText = responseData['response'];

        print(responseText);
        _speakResponse(responseText);
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending request: $e');
    }
  }

  void _speakResponse(String responseText) async {
    FlutterTts flutterTts = FlutterTts();
    await flutterTts.setLanguage('ru-RU'); // Set language to Russian
    await flutterTts.speak(responseText); // Speak the response text
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
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController),
            )
          else
            const Center(child: Text('Initializing Camera...')),
          if (_photoTaken && _photoFile != null && _activeModal == 'photo')
            Center(
              child: AlertDialog(
                backgroundColor: Color.fromRGBO(255, 255, 255, 0.6),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.file(_photoFile!),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue)),
                      onPressed: () {
                        setState(() {
                          _photoTaken = false;
                          _activeModal = '';
                        });
                        print('Photo sent to server (simulated)');
                      },
                      child: const Text(
                        'Отправить',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isRecording && _activeModal == 'voice')
            Center(
              child: AlertDialog(
                backgroundColor: Color.fromRGBO(255, 255, 255, 0.6),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedText(
                      text: _recordedText,
                      duration: const Duration(milliseconds: 100),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue)),
                      onPressed: () {
                        _stopVoiceRecording();
                        print('Text sent to server (simulated)');
                        setState(() {
                          _recordedText = '';
                        });
                      },
                      child: const Text(
                        'Отправить',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap:
                      _isRecording ? _stopVoiceRecording : _startVoiceRecording,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 50,
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

class AnimatedText extends StatelessWidget {
  final String text;
  final Duration duration;

  const AnimatedText(
      {Key? key,
      required this.text,
      this.duration = const Duration(milliseconds: 100)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      child: Text(
        text,
        key: ValueKey<String>(text),
        style:
            const TextStyle(fontSize: 18, color: Color.fromRGBO(54, 54, 54, 1)),
      ),
    );
  }
}
