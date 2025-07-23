import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  html.MediaRecorder? _mediaRecorder;
  html.Blob? _audioBlob;

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
    if (kIsWeb) {
      if (html.window.navigator.mediaDevices != null) {
        final stream = await html.window.navigator.mediaDevices!.getUserMedia({
          'audio': true,
        });
        if (stream != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni alındı.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli.')),
          );
        }
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mikrofon izni gerekli.')));
      }
    }
  }

  Future<void> _startRecording() async {
    if (html.window.navigator.mediaDevices != null) {
      try {
        final stream = await html.window.navigator.mediaDevices!.getUserMedia({
          'audio': true,
        });

        final chunks = <html.Blob>[];

        final mediaRecorder = html.MediaRecorder(stream, {
          'mimeType': 'audio/webm',
        });

        mediaRecorder.addEventListener('dataavailable', (html.Event event) {
          final blobEvent = event as html.BlobEvent;
          if (blobEvent.data != null) {
            chunks.add(blobEvent.data!);
          }
        });

        mediaRecorder.addEventListener('stop', (html.Event event) {
          final audioBlob = html.Blob(chunks, 'audio/webm');
          setState(() {
            _audioBlob = audioBlob;
          });
        });

        mediaRecorder.start(100);

        setState(() {
          _mediaRecorder = mediaRecorder;
          _isRecording = true;
          _isReadingPhase = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ses kaydı başlatılamadı: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarayıcı medya aygıtlarını desteklemiyor.'),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (kIsWeb && _mediaRecorder != null && _isRecording) {
      _mediaRecorder!.stop();
      setState(() {
        _isRecording = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (_audioBlob != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(_audioBlob!);
        await reader.onLoad.first;

        Uint8List uint8List;
        if (reader.result is Uint8List) {
          uint8List = reader.result as Uint8List;
        } else if (reader.result is ByteBuffer) {
          uint8List = Uint8List.view(reader.result as ByteBuffer);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hata: Ses verisi okunamadı, beklenmedik veri türü',
              ),
            ),
          );
          return;
        }

        try {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('http://127.0.0.1:8000/record_and_analyze'),
          );
          request.files.add(
            http.MultipartFile.fromBytes(
              'audio',
              uint8List,
              contentType: MediaType('audio', 'webm'),
              filename: 'audio.webm',
            ),
          );
          request.fields['reference_text'] =
              _readingTexts[_currentReadingIndex]['text']!;

          request.headers['Content-Type'] = 'multipart/form-data';

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
          const SnackBar(
            content: Text('Hata: Ses kaydı alınamadı, _audioBlob null'),
          ),
        );
      }
    }
  }

  Future<void> _playRecordedAudio() async {
    if (kIsWeb && _audioBlob != null && !_isPlaybackPlaying) {
      final url = html.Url.createObjectUrl(_audioBlob!);
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaybackPlaying = true;
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaybackPlaying = false;
        });
        html.Url.revokeObjectUrl(url);
      });
    } else if (!kIsWeb && _recordedFilePath != null && !_isPlaybackPlaying) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
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
        _audioBlob = null;
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
    _mediaRecorder?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTest = _readingTexts[_currentReadingIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTest['title']!),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        'Okuyacağınız Metin:',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 120,
                        child: SingleChildScrollView(
                          child: Text(
                            currentTest['text']!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 24,
                                  color: _isRecording
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isRecording
                                ? _stopRecording
                                : _startRecording,
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 20,
                            ),
                            label: Text(_isRecording ? 'Durdur' : 'Kaydet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording
                                  ? Colors.red.shade700
                                  : Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),

                          if (_audioBlob != null ||
                              (_recordedFilePath != null && !_isRecording))
                            ElevatedButton.icon(
                              onPressed: _isPlaybackPlaying
                                  ? _stopPlayback
                                  : _playRecordedAudio,
                              icon: Icon(
                                _isPlaybackPlaying
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                size: 20,
                              ),
                              label: Text(
                                _isPlaybackPlaying ? 'Durdur' : 'Dinle',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (_audioBlob != null ||
                          (_recordedFilePath != null && !_isRecording))
                        Padding(
                          // Yeni eklenen Padding
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 8,
                          ), // Üst 12, alt 8 piksel
                          child: Card(
                            elevation: 2,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (_analysisResult != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Okuma Başarısı: %${_analysisResult!['benzerlik_orani']}',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Durum: ${_analysisResult!['basari']}',
                                      style: TextStyle(
                                        fontSize: 18,
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

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _nextTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
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
