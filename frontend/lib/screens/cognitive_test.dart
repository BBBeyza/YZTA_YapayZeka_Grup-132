import 'package:flutter/material.dart';
import 'package:neurograph/services/gemini_service.dart';

// Eğer uuid paketi gerçekten kullanılmıyorsa bu import'u kaldırabilirsiniz.
// import 'package:uuid/uuid.dart';

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

  // copyWith metodu, QuestionAnswer nesnesinin bazı alanlarını değiştirmek için kullanılır.
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
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _answerController = TextEditingController();
  static const int _maxQuestions = 5;
  static const List<String> _questionTypes = [
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

    // _history'ye cevabı eklemeden önce puanlama için bekliyoruz.
    // Puanlama sonucuyla birlikte copyWith kullanılarak _history'ye eklenecek.
    await _scoreAnswer(qa, _currentQuestionIndex); // _history'ye ekleme burada yapılacak

    setState(() {
      _answerController.clear();
    });

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
        _history.add(
          qa.copyWith(
            score: score,
            scoreComment: comment,
            correctAnswer: correctAnswer,
          ),
        );
        _isLoading = false;
        _statusMessage = null;
      });
    } catch (e) {
      // Hata durumunda da cevabı kaydet, ama puanlama bilgisi olmadan
      setState(() {
        _history.add(
          qa.copyWith(
            score: null,
            scoreComment: 'Puanlama alınamadı.',
            correctAnswer: null,
          ),
        );
        _isLoading = false;
        _statusMessage = null;
        print('Puanlama hatası: $e'); // Hata mesajını konsola yazdır
      });
    }
  }

  Future<List<String>> _getRandomMemoryWords() async {
    try {
      final prompt =
          'Kullanıcıya hafıza testi için, kolay hatırlanabilir 3 farklı Türkçe kelime ver. Sadece kelimeleri virgülle ayırarak sırala.';
      final response = await _geminiService.askGemini(prompt);
      return response.split(',').map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    } catch (e) {
      print('Hafıza kelimeleri yüklenirken hata: $e');
      return ['elma', 'masa', 'araba']; // Hata durumunda varsayılan kelimeler
    }
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _currentQuestion = null;
      _statusMessage = 'Soru yükleniyor...';
    });

    if (_currentQuestionIndex == 1) { // Hafıza kelimeleri giriş
      _memoryWords = await _getRandomMemoryWords();
      _currentQuestion =
      'Şimdi hafızanızı test edeceğim. Lütfen bu 3 kelimeyi aklınızda tutun ve hemen tekrar edin: ${_memoryWords.join(', ')}';
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      return;
    }

    if (_currentQuestionIndex == 4 && _memoryWords.isNotEmpty) { // Hafıza kelimeleri hatırlama
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
      case 0: // Oryantasyon
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya oryantasyon (zaman/yer) ile ilgili kısa, açık uçlu bir soru sor. Sadece soruyu ver.';
        break;
      case 2: // Dikkat
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya dikkat veya konsantrasyon becerisini ölçen kısa bir soru sor. Sadece soruyu ver.';
        break;
      case 3: // Dil
        prompt = 'Sen bir nöropsikolojik test uzmanısın. Kullanıcıya dil becerisini ölçen kısa bir soru sor. Sadece soruyu ver.';
        break;
    // case 4: // Yürütücü İşlev (Zaten yukarıdaki if bloğunda ele alındıysa buraya düşmeyecektir)
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
    } catch (e) {
      setState(() {
        _currentQuestion = 'Soru yüklenemedi. Lütfen tekrar deneyin.';
        _isLoading = false;
        _statusMessage = null;
        print('Soru yükleme hatası: $e'); // Hata mesajını konsola yazdır
      });
    }
  }

  Future<void> _evaluateTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Değerlendirme alınıyor...';
    });

    String summary = '';
    // Puanlama geçmişini tersine değil, eklendiği sıraya göre işleyelim
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
    } catch (e) {
      setState(() {
        _evaluationResult = 'Değerlendirme alınamadı.';
        _isLoading = false;
        _statusMessage = null;
        print('Test değerlendirme hatası: $e'); // Hata mesajını konsola yazdır
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
      backgroundColor: const Color(0xFFF4F7FA), // Ana sayfa arka plan rengi
      appBar: AppBar(
        title: const Text('Bilişsel Test',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF72B0D3), // Çizim testlerindeki açık mavi
        centerTitle: true,
        elevation: 0, // Gölge yok
      ),
      body: Container(
        decoration: BoxDecoration( // 'const' kelimesini kaldırdık
          image: const DecorationImage(
            image: AssetImage('assets/images/backgroundN.png'),
            fit: BoxFit.cover,
            opacity: 0.6
          ),
          color: const Color(0xFFF4F7FA), // Eğer görsel yoksa fallback renk
        ),
        child: SafeArea( // İçeriği sistem UI'dan korumak için
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: !_testStarted
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container( // Giriş mesajı arka planı
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8), // Hafif opak beyaz arka plan
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [ // Hafif gölge
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Text(
                      'Bilişsel Teste Hoş Geldiniz!\n\nBu testte size ardışık olarak 5 farklı soru sorulacak. Her soru farklı bir bilişsel alanı ölçer.\n\nHazırsanız başlamak için aşağıdaki butona tıklayın.',
                      style: TextStyle(color: Colors.black87, fontSize: 16), // Metin rengi koyulaştırıldı
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _startTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF72B0D3), // Çizim testlerindeki açık mavi
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Yuvarlak köşeler
                      elevation: 5, // Gölge
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
                      'Test Tamamlandı!',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), // Daha büyük başlık
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Değerlendirme:',
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Soru ve cevap detayları kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95), // Beyaz kart, hafif opaklık
                        borderRadius: BorderRadius.circular(16), // Anasayfa kart yuvarlama
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soru Detayları:',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF1E3A8A), // Ana renk
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
                                color: const Color(0xFFF4F7FA), // Hafif gri arkaplan
                                borderRadius: BorderRadius.circular(12), // Yuvarlak köşeler
                                border: Border.all(color: Colors.grey.withOpacity(0.2)), // Hafif çerçeve
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF72B0D3), // Açık mavi secondary renk
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          'Soru ${index + 1}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A).withOpacity(0.7), // Primary rengin daha koyu tonu
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          qa.type.toUpperCase(),
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Soru: ${qa.question}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cevabınız: ${qa.answer}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (qa.correctAnswer != null) ...[ // 'const' kaldırıldı
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Doğru Cevap:',
                                      style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Text( // 'const' kaldırıldı
                                      qa.correctAnswer!, // null check yapıldıysa ! kullanılabilir
                                      style: const TextStyle(color: Colors.green, fontSize: 13),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: qa.score != null
                                              ? (qa.score! >= 7
                                              ? Colors.green.shade600
                                              : qa.score! >= 4
                                              ? Colors.orange.shade600
                                              : Colors.red.shade600)
                                              : Colors.grey.shade600,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Puan: ${qa.score ?? 'N/A'}/10',
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (qa.scoreComment != null) ...[ // 'const' kaldırıldı
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Açıklama:',
                                      style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                    Text( // 'const' kaldırıldı
                                      qa.scoreComment!, // null check yapıldıysa ! kullanılabilir
                                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
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
                      // 'const' kaldırıldı
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
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Genel Değerlendirme:',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _evaluationResult!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF72B0D3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: const Text('Anasayfaya Dön', style: TextStyle(fontSize: 16)),
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
                      child: Text(_statusMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
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
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentQuestion ?? 'Soru Yükleniyor...',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Cevabınızı yazın...',
                              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
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
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: const Text('Gönder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        if (_isLoading) const CircularProgressIndicator(
                          color: Color(0xFF72B0D3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Soru: ${_currentQuestionIndex + 1}/$_maxQuestions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
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