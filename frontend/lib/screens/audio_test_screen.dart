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

class _ReadingTestScreenState extends State<ReadingTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  Map<String, dynamic>? _analysisResult;
  DateTime? _recordingStartTime;

  int _currentReadingIndex = 0;
  final List<Map<String, String>> _readingTexts = [
    {
      'title': 'Test 1: Kısa Metin Anlatımı',
      'text':
          'Küçük bir sincap, ormanda bir fındık sakladı. Kış geldiğinde onu bulmayı umuyordu.',
      'audioPrompt': 'assets/audios/squirrel_prompt.mp3',
    },
    {
      'title': 'Test 2: Detaylı Paragraf Okuma',
      'text':
          'Güneşin ilk ışıkları, çiy damlalarıyla parlayan orman zeminine vurduğunda, kuşlar melodik şarkılarıyla günü karşıladı. Her yer yeni bir umutla doluydu.',
      'audioPrompt': 'assets/audios/sunrise_prompt.mp3',
    },
  ];

  bool _isRecording = false;
  bool _isPlaybackPlaying = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaybackPlaying = false;
      });
    });
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    if (micStatus != PermissionStatus.granted ||
        storageStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mikrofon ve depolama izinleri gerekli.')),
      );
    }
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başladı, lütfen konuşun...')),
        );
      }
    } catch (e) {
      print('Kayıt başlatma hatası: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt başlatılamadı: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        final recordingDuration = _recordingStartTime != null
            ? DateTime.now().difference(_recordingStartTime!).inSeconds
            : 0;

        if (recordingDuration < 3) {
          print('Kayıt çok kısa: $recordingDuration saniye');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt en az 3 saniye olmalı!')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ses kaydı analiz için gönderildi')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ses kaydı alınamadı')));
        }
      }
    } catch (e) {
      print('Kayıt durdurma hatası: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt durdurulamadı: $e')));
    }
  }

  Future<void> _sendAudioToBackend() async {
    try {
      final file = File(_recordedFilePath!);
      final fileSize = await file.length();
      print('Dosya yolu: $_recordedFilePath, Boyut: $fileSize bytes');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/text/record_and_analyze'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oynatma hatası: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oynatma durdurulamadı: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm sesli okuma testleri tamamlandı!')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTest = _readingTexts[_currentReadingIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTest['title']!),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Text(
                        'Okuyacağınız Metin:',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: SingleChildScrollView(
                          child: Text(
                            currentTest['text']!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: screenWidth * 0.05,
                                  color: _isRecording
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isRecording
                                ? _stopRecording
                                : _startRecording,
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: screenWidth * 0.06,
                            ),
                            label: Text(
                              _isRecording ? 'Durdur' : 'Kaydet',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording
                                  ? Colors.red.shade700
                                  : Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenHeight * 0.02,
                              ),
                            ),
                          ),
                          if (_recordedFilePath != null && !_isRecording)
                            ElevatedButton.icon(
                              onPressed: _isPlaybackPlaying
                                  ? _stopPlayback
                                  : _playRecordedAudio,
                              icon: Icon(
                                _isPlaybackPlaying
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                size: screenWidth * 0.06,
                              ),
                              label: Text(
                                _isPlaybackPlaying ? 'Durdur' : 'Dinle',
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05,
                                  vertical: screenHeight * 0.02,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_recordedFilePath != null && !_isRecording)
                        Padding(
                          padding: EdgeInsets.only(
                            top: screenHeight * 0.02,
                            bottom: screenHeight * 0.01,
                          ),
                          child: Card(
                            elevation: 2,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _analysisResult != null
                                        ? 'Sonuç:'
                                        : 'Analiz ediliyor...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.045,
                                        ),
                                  ),
                                  if (_analysisResult != null) ...[
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'Okuma Başarısı: %${_analysisResult!['benzerlik_orani']}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'Durum: ${_analysisResult!['basari']}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        color:
                                            _analysisResult!['basari'] ==
                                                'Başarılı'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: _nextTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  textStyle: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(
                  _currentReadingIndex < _readingTexts.length - 1
                      ? 'Sonraki'
                      : 'Bitir',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
