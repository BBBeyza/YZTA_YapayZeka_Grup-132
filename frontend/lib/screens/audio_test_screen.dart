import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';

class ReadingTestScreen extends StatefulWidget {
  const ReadingTestScreen({super.key});

  @override
  State<ReadingTestScreen> createState() => _ReadingTestScreenState();
}

class _ReadingTestScreenState extends State<ReadingTestScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  Map<String, dynamic>? _analysisResult;
  DateTime? _recordingStartTime;

  late AnimationController _recordingController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  int _currentReadingIndex = 0;
  final List<Map<String, String>> _readingTexts = [
    {
      'title': 'Test 1',
      'text':
          'Küçük bir sincap, ormanda bir fındık sakladı. Kış geldiğinde onu bulmayı umuyordu.',
      'audioPrompt': 'assets/audios/squirrel_prompt.mp3',
      'icon': '🐿️',
      'color': 'orange',
    },
    {
      'title': 'Test 2',
      'text':
          'Güneşin ilk ışıkları, çiy damlalarıyla parlayan orman zeminine vurduğunda, kuşlar melodik şarkılarıyla günü karşıladı.',
      'audioPrompt': 'assets/audios/sunrise_prompt.mp3',
      'icon': '🌅',
      'color': 'blue',
    },
    {
      'title': 'Test 3',
      'text':
          'Bir zamanlar, deniz kenarında yaşayan yaşlı bir balıkçı, her sabah denize açılır ve oltasını atardı. Günlerden bir gün, oltasına dev bir balık takıldı.',
      'audioPrompt': 'assets/audios/fisherman_prompt.mp3',
      'icon': '🎣',
      'color': 'green',
    },
    {
      'title': 'Test 4',
      'text':
          'Küçük bir çocuk, annesiyle birlikte parka gitti. Salıncağa bindiğinde gökyüzüne doğru yükseldiğini hissetti.',
      'audioPrompt': 'assets/audios/child_park_prompt.mp3',
      'icon': '👶',
      'color': 'purple',
    },
  ];

  bool _isRecording = false;
  bool _isPlaybackPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaybackPlaying = false;
      });
    });
  }

  void _initializeAnimations() {
    _recordingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _recordingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Color _getTestColor() {
    final colorType = _readingTexts[_currentReadingIndex]['color'];
    switch (colorType) {
      case 'orange':
        return const Color.fromARGB(255, 255, 154, 38);
      case 'blue':
        return const Color.fromARGB(255, 100, 97, 253);
      case 'green':
        return const Color.fromARGB(255, 80, 207, 84);
      case 'purple':
        return const Color.fromARGB(255, 190, 65, 212);
      default:
        return Colors.grey.shade400; // Fallback color
    }
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    if (micStatus != PermissionStatus.granted ||
        storageStatus != PermissionStatus.granted) {
      _showCustomSnackBar('Mikrofon ve depolama izinleri gerekli.', false);
    }
  }

  void _showCustomSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? Colors.green.shade600
            : Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 64000,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
          _analysisResult = null;
          _recordingStartTime = DateTime.now();
        });

        _recordingController.repeat(reverse: true);
        _pulseController.repeat();

        _showCustomSnackBar('Kayıt başladı, lütfen konuşun...', true);
      }
    } catch (e) {
      print('Kayıt başlatma hatası: $e');
      _showCustomSnackBar('Kayıt başlatılamadı: $e', false);
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        final recordingDuration = _recordingStartTime != null
            ? DateTime.now().difference(_recordingStartTime!).inSeconds
            : 0;

        _recordingController.stop();
        _pulseController.stop();

        if (recordingDuration < 2) {
          print('Kayıt çok kısa: $recordingDuration saniye');
          _showCustomSnackBar('Kayıt en az 2 saniye olmalı!', false);
          setState(() {
            _isRecording = false;
            _recordedFilePath = null;
          });
          return;
        }

        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });

        if (_recordedFilePath != null && _recordedFilePath!.isNotEmpty) {
          final file = File(_recordedFilePath!);
          final fileSize = await file.length();
          print('Kaydedilen dosya: $_recordedFilePath, Boyut: $fileSize bytes');
          await _sendAudioToBackend();
          _showCustomSnackBar('Ses kaydı analiz için gönderildi', true);
        } else {
          _showCustomSnackBar('Ses kaydı alınamadı', false);
        }
      }
    } catch (e) {
      print('Kayıt durdurma hatası: $e');
      _showCustomSnackBar('Kayıt durdurulamadı: $e', false);
    }
  }

  Future<void> _sendAudioToBackend() async {
    try {
      final file = File(_recordedFilePath!);
      final fileSize = await file.length();
      print('Dosya yolu: $_recordedFilePath, Boyut: $fileSize bytes');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.160:8000/text/record_and_analyze'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          _recordedFilePath!,
          contentType: MediaType('audio', 'wav'),
          filename: 'recording.wav',
        ),
      );

      request.fields['reference_text'] =
          _readingTexts[_currentReadingIndex]['text']!;
      print('İstek gönderiliyor: ${request.fields}');

      final response = await request.send().timeout(
        const Duration(seconds: 90),
      );
      print('Yanıt kodu: ${response.statusCode}');
      final responseData = await response.stream.bytesToString();
      print('Yanıt içeriği: $responseData');

      if (response.statusCode == 200) {
        final result = jsonDecode(responseData);
        print('Analiz sonucu: $result');
        setState(() {
          _analysisResult = result;
        });
      } else {
        throw Exception(
          'Sunucu hatası: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      print('Hata: $e');
      _showCustomSnackBar('Hata: $e', false);
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath == null) return;

    try {
      if (_isPlaybackPlaying) {
        await _stopPlayback();
      } else {
        print('Oynatılıyor: $_recordedFilePath');
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
        setState(() {
          _isPlaybackPlaying = true;
        });
      }
    } catch (e) {
      print('Oynatma hatası: $e');
      _showCustomSnackBar('Oynatma hatası: $e', false);
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaybackPlaying = false;
      });
    } catch (e) {
      print('Oynatma durdurma hatası: $e');
      _showCustomSnackBar('Oynatma durdurulamadı: $e', false);
    }
  }

  void _nextTest() {
    _stopPlayback();
    if (_isRecording) {
      _stopRecording();
    }

    setState(() {
      if (_currentReadingIndex < _readingTexts.length - 1) {
        _currentReadingIndex++;
        _recordedFilePath = null;
        _analysisResult = null;
        _isRecording = false;
        _isPlaybackPlaying = false;
      } else {
        _showCustomSnackBar('Tüm sesli okuma testleri tamamlandı!', true);
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _recordingController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTest = _readingTexts[_currentReadingIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final testColor = _getTestColor();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentTest['icon']!,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentTest['title']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: testColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            color: testColor,
          ),
        ),
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade50),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.02),

                // Main Text Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: testColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: testColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: testColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                color: testColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Okuyacağınız Metin',
                                style: TextStyle(
                                  color: testColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        Container(
                          height: screenHeight * 0.22,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? testColor.withOpacity(0.05)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isRecording
                                  ? testColor.withOpacity(0.3)
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: _isRecording
                                    ? testColor
                                    : Colors.black87,
                                fontWeight: _isRecording
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                height: 1.6,
                              ),
                              child: Text(
                                currentTest['text']!,
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Recording Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Record Button
                            AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isRecording
                                      ? _scaleAnimation.value
                                      : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isRecording
                                              ? Colors.red.withOpacity(0.3)
                                              : testColor.withOpacity(0.3),
                                          blurRadius: _isRecording ? 15 : 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _isRecording
                                          ? _stopRecording
                                          : _startRecording,
                                      icon: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _isRecording
                                                ? _pulseAnimation.value
                                                : 1.0,
                                            child: Icon(
                                              _isRecording
                                                  ? Icons.stop_rounded
                                                  : Icons.mic_rounded,
                                              size: screenWidth * 0.06,
                                            ),
                                          );
                                        },
                                      ),
                                      label: Text(
                                        _isRecording ? 'Durdur' : 'Kaydet',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isRecording
                                            ? Colors.red.shade600
                                            : testColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.06,
                                          vertical: screenHeight * 0.018,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Play Button
                            if (_recordedFilePath != null && !_isRecording)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isPlaybackPlaying
                                      ? _stopPlayback
                                      : _playRecordedAudio,
                                  icon: Icon(
                                    _isPlaybackPlaying
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                    size: screenWidth * 0.06,
                                  ),
                                  label: Text(
                                    _isPlaybackPlaying ? 'Durdur' : 'Dinle',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.06,
                                      vertical: screenHeight * 0.018,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Results Card
                if (_recordedFilePath != null && !_isRecording)
                  Container(
                    margin: EdgeInsets.only(top: screenHeight * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _analysisResult != null
                                    ? 'Analiz Sonucu'
                                    : 'Analiz Ediliyor...',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),

                          if (_analysisResult != null) ...[
                            SizedBox(height: screenHeight * 0.02),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.percent_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Okuma Başarısı: %${_analysisResult!['benzerlik_orani']}',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.043,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: screenHeight * 0.015),

                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              _analysisResult!['basari'] ==
                                                  'Başarılı'
                                              ? Colors.green.shade600
                                              : Colors.orange.shade600,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Icon(
                                          _analysisResult!['basari'] ==
                                                  'Başarılı'
                                              ? Icons.check_circle_rounded
                                              : Icons.warning_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Durum: ${_analysisResult!['basari']}',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.043,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _analysisResult!['basari'] ==
                                                  'Başarılı'
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            SizedBox(height: screenHeight * 0.02),
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Lütfen bekleyin...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.04),

                // Next Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: testColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _nextTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: testColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentReadingIndex < _readingTexts.length - 1
                              ? 'Sonraki Test'
                              : 'Testi Bitir',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentReadingIndex < _readingTexts.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.check_rounded,
                          size: screenWidth * 0.05,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
