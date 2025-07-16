import 'package:flutter/material.dart';
import 'package:neurograph/services/gemini_service.dart';
import 'package:uuid/uuid.dart';

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
}

class CognitiveTestScreen extends StatefulWidget {
  const CognitiveTestScreen({super.key});
  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _answerController = TextEditingController();
  static const int _maxQuestions = 5;
  static const List<String> _questionTypes = [
    'oryantasyon', 'hafıza', 'dikkat', 'dil', 'yürütücü işlev',
  ];
  int _currentQuestionIndex = 0;
  bool _isLoading = false, _testStarted = false, _testFinished = false;
  String? _currentQuestion, _statusMessage, _evaluationResult;
  List<QuestionAnswer> _history = [];
  List<String> _memoryWords = [];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _testStarted = true;
      _testFinished = false;
      _currentQuestionIndex = 0;
      _history = [];
      _memoryWords = [];
      _evaluationResult = null;
      _statusMessage = null;
    });
    await _loadNextQuestion();
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
    await _scoreAnswer(qa, _currentQuestionIndex);
    if (_currentQuestionIndex < _maxQuestions - 1) {
      setState(() => _currentQuestionIndex++);
      await _loadNextQuestion();
    } else {
      setState(() {
        _testFinished = true;
        _isLoading = false;
      });
      await _evaluateTest();
    }
  }

  Future<void> _scoreAnswer(QuestionAnswer qa, int index) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cevabınız puanlanıyor...';
    });
    final prompt =
        'Aşağıda bir nöropsikolojik testte verilen soru ve cevap var. Soru tipi: ${qa.type}. Kullanıcının verdiği cevabı, ${qa.type} kriterine göre 10 üzerinden puanla ve çok kısa bir gerekçe yaz. Ayrıca bu soru için doğru/ideal cevabı da ver. Sadece şu formatta dön: PUAN: <0-10 arası sayı>\nAÇIKLAMA: <gerekçe>\nDOĞRU CEVAP: <ideal cevap>\n\nSoru: ${qa.question}\nCevap: ${qa.answer}';
    try {
      final result = await _geminiService.askGemini(prompt);
      final scoreReg = RegExp(r'PUAN:\s*(\d{1,2})');
      final commentReg = RegExp(r'AÇIKLAMA:\s*(.*?)(?=\nDOĞRU CEVAP:|$)', dotAll: true);
      final correctAnswerReg = RegExp(r'DOĞRU CEVAP:\s*(.*)', dotAll: true);
      
      int? score;
      String? comment;
      String? correctAnswer;
      
      final scoreMatch = scoreReg.firstMatch(result);
      if (scoreMatch != null) score = int.tryParse(scoreMatch.group(1)!);
      
      final commentMatch = commentReg.firstMatch(result);
      if (commentMatch != null) comment = commentMatch.group(1)?.trim();
      
      final correctAnswerMatch = correctAnswerReg.firstMatch(result);
      if (correctAnswerMatch != null) correctAnswer = correctAnswerMatch.group(1)?.trim();
      
      setState(() {
        _history[index] = QuestionAnswer(
          question: qa.question,
          answer: qa.answer,
          type: qa.type,
          score: score,
          scoreComment: comment,
          correctAnswer: correctAnswer,
        );
        _isLoading = false;
        _statusMessage = null;
      });
    } catch (_) {
      setState(() {
        _history[index] = QuestionAnswer(
          question: qa.question,
          answer: qa.answer,
          type: qa.type,
          score: null,
          scoreComment: 'Puanlama alınamadı.',
          correctAnswer: null,
        );
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  Future<List<String>> _getRandomMemoryWords() async {
    try {
      final prompt =
          'Kullanıcıya hafıza testi için, kolay hatırlanabilir 3 farklı Türkçe kelime ver. Sadece kelimeleri virgülle ayırarak sırala.';
      final response = await _geminiService.askGemini(prompt);
      return response.split(',').map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    } catch (_) {
      return ['elma', 'masa', 'araba'];
    }
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _currentQuestion = null;
      _statusMessage = 'Soru yükleniyor...';
    });
    if (_currentQuestionIndex == 1) {
      _memoryWords = await _getRandomMemoryWords();
      _currentQuestion =
          'Şimdi hafızanızı test edeceğim. Lütfen bu 3 kelimeyi aklınızda tutun ve hemen tekrar edin: ${_memoryWords.join(', ')}';
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      return;
    }
    if (_currentQuestionIndex == 4 && _memoryWords.isNotEmpty) {
      _currentQuestion =
          'Biraz önce size bazı kelimeler söylemiştim. Lütfen şimdi hatırladığınız kadarını tekrar edin.';
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      return;
    }
    String prompt = '';
    switch (_currentQuestionIndex) {
      case 0:
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya oryantasyon (zaman/yer) ile ilgili kısa, açık uçlu bir soru sor. Sadece soruyu ver.';
        break;
      case 2:
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya dikkat veya konsantrasyon becerisini ölçen kısa bir soru sor. Sadece soruyu ver.';
        break;
      case 3:
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya dil becerisini ölçen kısa bir soru sor. Sadece soruyu ver.';
        break;
      default:
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya yürütücü işlev/yargılama becerisini ölçen kısa bir soru sor. Sadece soruyu ver.';
    }
    try {
      final question = await _geminiService.askGemini(prompt);
      if (question == null || question.trim().isEmpty) {
        setState(() {
          _currentQuestion = 'Soru alınamadı, lütfen tekrar deneyin.';
          _isLoading = false;
          _statusMessage = null;
        });
        return;
      }
      setState(() {
        _currentQuestion = question;
        _isLoading = false;
        _statusMessage = null;
      });
    } catch (_) {
      setState(() {
        _currentQuestion = 'Soru yüklenemedi. Lütfen tekrar deneyin.';
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  Future<void> _evaluateTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Değerlendirme alınıyor...';
    });
    String summary = '';
    for (int i = 0; i < _history.length; i++) {
      final qa = _history[i];
      summary += 'Soru ${i + 1} [${qa.type}]: ${qa.question}\nCevap: ${qa.answer}\nDoğru Cevap: ${qa.correctAnswer ?? 'Belirtilmedi'}\nPuan: ${qa.score ?? '-'}\nAçıklama: ${qa.scoreComment ?? '-'}\n\n';
    }
    if (_memoryWords.isNotEmpty) {
      summary = 'Hafıza kelimeleri: ${_memoryWords.join(', ')}\n$summary';
    }
    final prompt =
        'Aşağıda bir kullanıcının nöropsikolojik testte verdiği sorular, cevaplar ve her biri için verilen puanlar var. Her alan için kısa bir genel yorum yap ve toplam performansı özetle.\n\n$summary';
    try {
      final result = await _geminiService.askGemini(prompt);
      if (result == null || result.trim().isEmpty) {
        setState(() {
          _evaluationResult = 'Değerlendirme alınamadı, lütfen tekrar deneyin.';
          _isLoading = false;
          _statusMessage = null;
        });
        return;
      }
      setState(() {
        _evaluationResult = result;
        _isLoading = false;
        _statusMessage = null;
      });
    } catch (_) {
      setState(() {
        _evaluationResult = 'Değerlendirme alınamadı.';
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilişsel Test', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A0DAD),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
          color: Color(0xFF1A1A2E),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: !_testStarted
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Bilişsel Teste Hoş Geldiniz!\n\nBu testte size ardışık olarak 5 farklı soru sorulacak. Her soru farklı bir bilişsel alanı ölçer.\n\nHazırsanız başlamak için aşağıdaki butona tıklayın.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _startTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A0DAD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Teste Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                : _testFinished
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Test Tamamlandı!\n\nDeğerlendirme:',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            
                            // Soru ve cevap detayları
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A5A).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Soru Detayları:',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._history.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final qa = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A4A).withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF6A0DAD).withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6A0DAD),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Soru ${index + 1}',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4A4A6A),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  qa.type.toUpperCase(),
                                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Soru: ${qa.question}',
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Cevabınız: ${qa.answer}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                          if (qa.correctAnswer != null) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Doğru Cevap: ${qa.correctAnswer}',
                                              style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: qa.score != null 
                                                      ? (qa.score! >= 7 ? Colors.green : qa.score! >= 4 ? Colors.orange : Colors.red)
                                                      : Colors.grey,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Puan: ${qa.score ?? 'N/A'}/10',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (qa.scoreComment != null) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Açıklama: ${qa.scoreComment}',
                                              style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
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
                            
                            // Genel değerlendirme
                            if (_evaluationResult != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A3A5A).withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Genel Değerlendirme:',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _evaluationResult!,
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => setState(() => _testStarted = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A0DAD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Başa Dön', style: TextStyle(fontSize: 16)),
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
                              child: Text(_statusMessage!, style: const TextStyle(color: Colors.white54)),
                            ),
                          if (_currentQuestion != null)
                            Text(
                              _currentQuestion!,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 30),
                          if (!_isLoading && _currentQuestion != null)
                            TextField(
                              controller: _answerController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Cevabınızı yazın',
                                hintStyle: const TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide.none,
                                ),
                                fillColor: const Color(0xFF3A3A5A),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              ),
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              onSubmitted: (_) => _submitAnswer(),
                            ),
                          const SizedBox(height: 10),
                          if (!_isLoading && _currentQuestion != null)
                            ElevatedButton(
                              onPressed: _submitAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A0DAD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Gönder', style: TextStyle(fontSize: 16)),
                            ),
                          if (_isLoading) const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            'Soru: ${_currentQuestionIndex + 1}/$_maxQuestions',
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
