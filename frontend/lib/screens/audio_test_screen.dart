import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart'; // Bu, ses kaydı paketi Record'udur.
import 'package:path_provider/path_provider.dart'; // Dosya yolu için
import 'package:permission_handler/permission_handler.dart'; // İzinler için

class ReadingTestScreen extends StatefulWidget {
  const ReadingTestScreen({super.key});

  @override
  State<ReadingTestScreen> createState() => _ReadingTestScreenState();
}

class _ReadingTestScreenState extends State<ReadingTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Record sınıfı abstract, bu yüzden AudioRecorder() kullanılır.
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath; // Kaydedilen ses dosyasının yolu

  int _currentReadingIndex = 0;
  final List<Map<String, String>> _readingTexts = [
    {
      'title': 'Test 1: Kısa Metin Anlatımı',
      'text':
          'Küçük bir sincap, ormanda gizli bir fındık sakladı. Kış geldiğinde onu bulmayı umuyordu.',
      'audioPrompt':
          'assets/audios/squirrel_prompt.mp3', // Bu dosya mevcut olmalı
    },
    {
      'title': 'Test 2: Detaylı Paragraf Okuma',
      'text':
          'Güneşin ilk ışıkları, çiy damlalarıyla parlayan orman zeminine vurduğunda, kuşlar melodik şarkılarıyla günü karşıladı. Her yer taze ve yeni bir umutla doluydu.',
      'audioPrompt':
          'assets/audios/sunrise_prompt.mp3', // Bu dosya mevcut olmalı
    },
    // Daha fazla test eklenebilir.
  ];

  bool _isReadingPhase =
      true; // true: metin gösteriliyor, false: metin gizli, kayıt bekleniyor
  bool _isRecording = false;
  bool _isPlaybackPlaying = false; // Kaydedilen sesi oynatma durumu

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
    try {
      // AudioRecorder sınıfı üzerinden izin kontrolü
      // hasPermission metodu AudioRecorder sınıfında mevcut.
      if (await _audioRecorder.hasPermission()) {
        // Önce uygulama dizinini dene, başarısız olursa geçici dizini kullan
        Directory directory;
        try {
          directory = await getApplicationDocumentsDirectory();
        } catch (e) {
          print('Application directory erişim hatası: $e');
          directory = Directory.systemTemp;
        }

        final filePath =
            '${directory.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
          _isReadingPhase = false; // Metni gizle
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni reddedildi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt başlatılamadı: $e')));
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      setState(() {
        _isRecording = false;
        _recordedFilePath = path; // Kaydedilen dosyanın nihai yolu
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ses kaydedildi: $path')));
    } else {
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt durdurulamadı veya dosya oluşturulamadı.'),
        ),
      );
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath != null && !_isPlaybackPlaying) {
      try {
        Source audioSource = DeviceFileSource(_recordedFilePath!);
        await _audioPlayer.play(audioSource);
        setState(() {
          _isPlaybackPlaying = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kayıt oynatılamadı: $e')));
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaybackPlaying = false;
    });
  }

  void _nextTest() {
    _stopPlayback();
    // Kayıt hala devam ediyorsa durdur
    if (_isRecording) {
      _stopRecording();
    }

    // Kaydedilen _recordedFilePath'i burada bir yere kaydedebilirsiniz (veritabanı, bulut vb.)
    // veya analiz için kullanabilirsiniz.

    setState(() {
      if (_currentReadingIndex < _readingTexts.length - 1) {
        _currentReadingIndex++;
        _isReadingPhase = true; // Yeni test için metni tekrar göster
        _recordedFilePath = null; // Eski kaydı temizle
        _isRecording = false;
        _isPlaybackPlaying = false;
      } else {
        // Tüm testler bitti
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
    _audioRecorder.dispose(); // AudioRecorder objesini dispose etmeyi unutmayın
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _isReadingPhase
                            ? 'Metni Okuyun:'
                            : 'Hatırladığınızı Seslendirin:',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Metin sadece okuma aşamasında gösterilir
                      if (_isReadingPhase)
                        Text(
                          currentTest['text']!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontSize: 18),
                          textAlign: TextAlign.justify,
                        )
                      else
                        Text(
                          _isRecording
                              ? 'Kaydediliyor...'
                              : 'Seslendirme için hazır.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: _isRecording ? Colors.red : Colors.grey,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isRecording
                            ? _stopRecording
                            : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          _isRecording ? 'Kaydı Durdur' : 'Kaydı Başlat',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording
                              ? Colors.red.shade700
                              : Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (_recordedFilePath != null && !_isRecording) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isPlaybackPlaying
                              ? _stopPlayback
                              : _playRecordedAudio,
                          icon: Icon(
                            _isPlaybackPlaying ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(
                            _isPlaybackPlaying
                                ? 'Kaydı Dinlemeyi Durdur'
                                : 'Kaydı Dinle',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _nextTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(
                  _currentReadingIndex < _readingTexts.length - 1
                      ? 'Sonraki Test'
                      : 'Testi Bitir',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
