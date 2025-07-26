import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ReadingTestScreen extends StatefulWidget {
  const ReadingTestScreen({super.key});

  @override
  State<ReadingTestScreen> createState() => _ReadingTestScreenState();
}

class _ReadingTestScreenState extends State<ReadingTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  Map<String, dynamic>? _analysisResult;

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

  bool _isReadingPhase = true;
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
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mikrofon izni gerekli.')));
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _isReadingPhase = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kayıt başladı, lütfen sesinizi kaydedin.')),
    );
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final directory = await getTemporaryDirectory();
      _recordedFilePath = '${directory.path}/recorded_audio.mp3';
      if (_recordedFilePath != null) {
        try {
          final file = await http.MultipartFile.fromPath(
            'audio',
            _recordedFilePath!,
            contentType: MediaType('audio', 'mp3'),
          );
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('http://127.0.0.1:8000/record_and_analyze'),
          );
          request.files.add(file);
          request.fields['reference_text'] =
          _readingTexts[_currentReadingIndex]['text']!;

          final response = await request.send();
          final responseData = await http.Response.fromStream(response);

          if (response.statusCode == 200) {
            final result = jsonDecode(responseData.body);
            if (result.containsKey('error')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Backend hatası: ${result['error']}')),
              );
            } else {
              setState(() {
                _analysisResult = result;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ses kaydedildi ve analiz edildi: ${result['basari']}',
                  ),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Analiz hatası: HTTP ${response.statusCode} - ${responseData.body}',
                ),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backend bağlantısı başarısız: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hata: Ses kaydı alınamadı')),
        );
      }
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath != null && !_isPlaybackPlaying) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      setState(() {
        _isPlaybackPlaying = true;
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaybackPlaying = false;
        });
      });
    } else if (!_isPlaybackPlaying) {
      await _audioPlayer.play(
        AssetSource(_readingTexts[_currentReadingIndex]['audioPrompt']!),
      );
      setState(() {
        _isPlaybackPlaying = true;
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaybackPlaying = false;
        });
      });
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
        _isReadingPhase = true;
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

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaybackPlaying = false;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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