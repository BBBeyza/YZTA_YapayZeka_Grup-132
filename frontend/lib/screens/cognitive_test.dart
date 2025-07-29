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
}

class CognitiveTestScreen extends StatefulWidget {
  const CognitiveTestScreen({super.key});

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  final TextEditingController _answerController = TextEditingController();
  static const int _maxQuestions = 10; // Backend 10 soru döndürüyor
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
  ]; // 10 soru için türler

  int _currentQuestionIndex = 0;
  bool _isLoading = false, _testStarted = false, _testFinished = false;
  String? _currentQuestion, _statusMessage, _evaluationResult;
  List<QuestionAnswer> _history = [];
  List<Map<String, dynamic>> _questions = []; // Backend'den gelen sorular

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Test başlatılıyor...';
    });

    try {
      // Backend'den soruları al
      final response = await http.post(
        Uri.parse('http://your-backend-url/run_cognitive_test'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _questions = List<Map<String, dynamic>>.from(data['test_results']);
        setState(() {
          _testStarted = true;
          _testFinished = false;
          _currentQuestionIndex = 0;
          _history = [];
          _evaluationResult = null;
          _currentQuestion = _questions[0]['Soru'];
          _isLoading = false;
          _statusMessage = null;
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

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      _showSnackBar('Lütfen bir cevap girin.');
      return;
    }

    final type = _questionTypes[_currentQuestionIndex];
    final question = _currentQuestion ?? '';
    final qa = QuestionAnswer(question: question, answer: answer, type: type);

    setState(() {
      _history.add(qa);
      _answerController.clear();
    });

    if (_currentQuestionIndex < _maxQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex]['Soru'];
      });
    } else {
      await _evaluateTest();
    }
  }

  Future<void> _evaluateTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cevaplarınız değerlendiriliyor...';
    });

    try {
      // Cevapları backend'e gönder
      final qaList = _history
          .asMap()
          .entries
          .map(
            (entry) => {
              'Soru': _questions[entry.key]['Soru'],
              'Cevap': entry.value.answer,
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse('http://your-backend-url/run_cognitive_test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qa_list': qaList}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final testResults = List<Map<String, dynamic>>.from(
          data['test_results'],
        );
        setState(() {
          _history = testResults.asMap().entries.map((entry) {
            final idx = entry.key;
            final result = entry.value;
            return QuestionAnswer(
              question: result['Soru'],
              answer: result['Cevap'],
              type: _questionTypes[idx],
              score:
                  null, // Backend puanlama döndürmüyor, gerekirse eklenebilir
              scoreComment: null,
              correctAnswer: null,
            );
          }).toList();
          _evaluationResult = data['analysis_report'];
          _testFinished = true;
          _isLoading = false;
          _statusMessage = null;
        });
      } else {
        throw Exception('Backend hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
        _evaluationResult = 'Değerlendirme alınamadı: $e';
        _testFinished = true;
      });
      _showSnackBar('Değerlendirme alınamadı: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Bilişsel Test',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF72B0D3),
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
