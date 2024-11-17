import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Импортируйте flutter_tts
import 'package:airun_flutter/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts(); // Создаем экземпляр FlutterTts

  @override
  void initState() {
    super.initState();

    // Проигрывание звука
    _audioPlayer.play(AssetSource('start.mp3')); // Укажите ваш аудиофайл

    // Вибрация, если доступна
    Vibration.hasVibrator().then((bool? hasVibrator) {
      if (hasVibrator ?? false) {
        Vibration.vibrate(duration: 500); // Вибрация длительностью 500мс
      }
    });

    // Текстовое сообщение на русском языке
    _flutterTts.speak('Eye See'); // Произнесем текст

    // Запуск анимации
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _opacity = 1.0;
      });

      // Переход на следующий экран после завершения анимации
      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Освобождение ресурсов
    _flutterTts.stop(); // Останавливаем TTS, если оно было запущено
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF1F1F1), // Цвет фона
        child: Stack(
          children: [
            // Верхний левый круг с размытием
            Positioned(
              top: -60,
              left: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.5),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Нижний правый круг с размытием
            Positioned(
              bottom: -50,
              right: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.5),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Центр с анимацией прозрачности
            Center(
              child: AnimatedOpacity(
                opacity: _opacity, // Значение прозрачности для анимации
                duration: const Duration(seconds: 2), // Длительность анимации
                curve: Curves.easeInOut, // Кривая анимации
                child: Container(
                  padding: const EdgeInsets.all(16.0), // Внутренние отступы
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20.0), // Скругленные углы
                  ),
                  child: Image.asset(
                    'assets/logo.png', // Путь к изображению
                    width: 100, // Ширина изображения
                    height: 100, // Высота изображения
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
