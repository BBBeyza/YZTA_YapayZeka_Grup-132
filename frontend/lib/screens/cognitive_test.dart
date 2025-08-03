import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuestionAnswer {
  final String question, answer, type;
  final int? score;
  final String? scoreComment;
  final String? correctAnswer;

  QuestionAnswer({
    required this.question,
    required this.answer,
    required this.type,
    this.score,
    this.scoreComment,
    this.correctAnswer,
  });

  QuestionAnswer copyWith({
    String? question,
    String? answer,
    String? type,
    int? score,
    String? scoreComment,
    String? correctAnswer,
  }) {
    return QuestionAnswer(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      type: type ?? this.type,
      score: score ?? this.score,
      scoreComment: scoreComment ?? this.scoreComment,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }

  @override
  String toString() {
    return 'QuestionAnswer(question: $question, answer: $answer, type: $type)';
  }
}

class CognitiveTestScreen extends StatefulWidget {
  const CognitiveTestScreen({super.key});

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  final TextEditingController _answerController = TextEditingController();
  static const int _maxQuestions = 10;
  static const List<String> _questionTypes = [
    'oryantasyon',
    'hafıza',
    'dikkat',
    'dil',
    'yürütücü işlev',
    'oryantasyon',
    'hafıza',
    'dikkat',
    'dil',
    'yürütücü işlev',
  ];

  int _currentQuestionIndex = 0;
  bool _isLoading = false, _testStarted = false, _testFinished = false;
  String? _currentQuestion, _statusMessage, _evaluationResult;
  List<QuestionAnswer> _history = [];
  List<Map<String, dynamic>> _questions = [];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      _showSnackBar('Lütfen bir cevap girin.');
      print('Hata: Cevap boş, soru index: $_currentQuestionIndex');
      return;
    }

    final type = _questionTypes[_currentQuestionIndex];
    final question = _currentQuestion ?? '';
    final qa = QuestionAnswer(question: question, answer: answer, type: type);

    setState(() {
      _history.add(qa);
      print('Cevap eklendi: $qa');
      print('Geçerli _history uzunluğu: ${_history.length}, içerik: $_history');
    });

    if (_currentQuestionIndex < _maxQuestions - 1) {
      setState(() {
        _answerController.clear();
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex]['Soru'];
        print(
          'Sonraki soru: $_currentQuestion (Index: $_currentQuestionIndex)',
        );
      });
    } else {
      // Son soruya cevap eklendi, testi bitirme işlemi burada
      setState(() {
        _answerController.clear();
      });
      print('Son soru cevaplandı, _history uzunluğu: ${_history.length}');
      if (_history.length == _maxQuestions) {
        print('Tüm sorular cevaplandı, değerlendirme başlıyor: $_history');
        await _evaluateTest();
      } else {
        _showSnackBar(
          'Hata: Tüm sorular cevaplanmadı. Lütfen son soruya cevap verin.',
        );
        print(
          'Hata: _history uzunluğu ${_history.length}, beklenen: $_maxQuestions',
        );
      }
    }
  }

  Future<void> _startTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Test başlatılıyor...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.160:8000/cognitive/run_cognitive_test'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Sorular API Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data);
          _currentQuestion = _questions[0]['Soru'];
          _testStarted = true;
          _isLoading = false;
          _history = [];
          _currentQuestionIndex = 0;
        });
      } else {
        throw Exception('Backend hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      _showSnackBar('Test başlatılamadı: $e');
    }
  }

  Future<void> _evaluateTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cevaplarınız değerlendiriliyor...';
    });

    try {
      // Yeni endpoint kullanarak cevapları gönder
      final qaList = _history
          .map((qa) => {'Soru': qa.question, 'Cevap': qa.answer})
          .toList();

      print('Gönderilen cevaplar: ${jsonEncode({'qa_list': qaList})}');

      final response = await http.post(
        Uri.parse('http://192.168.1.160:8000/cognitive/run_cognitive_test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(qaList), // Direkt liste gönderiyoruz
      );

      print(
        'Değerlendirme API Yanıtı: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _evaluationResult = data['analysis_report'];
          _testFinished = true;
          _isLoading = false;
        });
      } else {
        throw Exception('Değerlendirme hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _evaluationResult = 'Değerlendirme alınamadı: $e';
        _testFinished = true;
      });
      _showSnackBar('Değerlendirme hatası: $e');
    }
  }

  String _parseReport(String report) {
    if (report.isEmpty) {
      return 'Rapor boş döndü, lütfen tekrar deneyin.';
    }
    try {
      final lines = report.split('\n').map((line) => line.trim()).toList();
      final sections = <String, String>{};
      String currentSection = 'Genel Değerlendirme';
      StringBuffer currentText = StringBuffer();

      for (final line in lines) {
        if (line.startsWith('**') && line.endsWith('**')) {
          if (currentText.isNotEmpty) {
            sections[currentSection] = currentText.toString().trim();
            currentText.clear();
          }
          currentSection = line.substring(2, line.length - 2).trim();
        } else if (line.isNotEmpty) {
          currentText.write('$line\n');
        }
      }
      if (currentText.isNotEmpty) {
        sections[currentSection] = currentText.toString().trim();
      }

      if (sections.isEmpty) {
        return 'Rapor formatı beklenenden farklı, ham veri: $report';
      }

      return sections.entries.map((entry) {
        return '• **${entry.key}:**\n${entry.value}\n\n';
      }).join();
    } catch (e) {
      return 'Rapor işlenirken hata oluştu: $e\nHam veri: $report';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Bilişsel Test',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE1BEE7),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgroundN.png'),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
          color: Color(0xFFF4F7FA),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: !_testStarted
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Bilişsel Teste Hoş Geldiniz!\n\nBu testte size ardışık olarak 10 farklı soru sorulacak. Her soru farklı bir bilişsel alanı ölçer.\n\nHazırsanız başlamak için aşağıdaki butona tıklayın.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _startTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF72B0D3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Teste Başla',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _testFinished
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Test Tamamlandı!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Değerlendirme:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soru Detayları:',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: const Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ..._history.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final qa = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F7FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF72B0D3),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                'Soru ${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF1E3A8A,
                                                ).withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                qa.type.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Soru: ${qa.question}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Cevabınız: ${qa.answer}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey.shade700,
                                                fontSize: 14,
                                              ),
                                        ),
                                        if (qa.correctAnswer != null) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Doğru Cevap:',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            qa.correctAnswer!,
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: qa.score != null
                                                    ? (qa.score! >= 7
                                                          ? Colors
                                                                .green
                                                                .shade600
                                                          : qa.score! >= 4
                                                          ? Colors
                                                                .orange
                                                                .shade600
                                                          : Colors.red.shade600)
                                                    : Colors.grey.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'Puan: ${qa.score ?? 'N/A'}/10',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (qa.scoreComment != null) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Açıklama:',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          Text(
                                            qa.scoreComment!,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_evaluationResult != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Genel Değerlendirme:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: const Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _evaluationResult!,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(color: Colors.black87),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF72B0D3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Anasayfaya Dön',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_statusMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _statusMessage!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white54),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentQuestion ?? 'Soru Yükleniyor...',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              if (!_isLoading && _currentQuestion != null)
                                TextField(
                                  controller: _answerController,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: 'Cevabınızı yazın...',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: Colors.grey.shade500),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade200,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 15.0,
                                    ),
                                  ),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  onSubmitted: (_) => _submitAnswer(),
                                ),
                              const SizedBox(height: 20),
                              if (!_isLoading && _currentQuestion != null)
                                ElevatedButton(
                                  onPressed: _submitAnswer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF72B0D3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: const Text(
                                    'Gönder',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (_isLoading)
                                const CircularProgressIndicator(
                                  color: Color(0xFF72B0D3),
                                ),
                              const SizedBox(height: 20),
                              Text(
                                'Soru: ${_currentQuestionIndex + 1}/$_maxQuestions',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
