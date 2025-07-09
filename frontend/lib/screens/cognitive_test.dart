import 'package:flutter/material.dart';
import 'package:neurograph/services/gemini_service.dart';
import 'package:uuid/uuid.dart';

// Mesaj balonu için ayrı bir widget
class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;

  const MessageBubble({
    required this.text,
    required this.isUser,
    required this.isError,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF6A0DAD)
              : (isError ? Colors.red[700] : const Color(0xFF4A4A6A)),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white70,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}

// Giriş alanı için ayrı bir widget
class AnswerInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const AnswerInputArea({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A4A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cevabınızı buraya yazın',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                fillColor: const Color(0xFF3A3A5A),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onSubmitted: (value) => isLoading ? null : onSubmit(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: isLoading ? null : onSubmit,
          ),
        ],
      ),
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
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final String _sessionId = const Uuid().v4();

  bool _isLoading = false;
  int _questionCount = 0;
  static const int _maxQuestions = 5; // Toplam soru sayısı
  bool _testStarted = false; // Testin başlayıp başlamadığını takip eder

  List<String> _rememberedWords = []; // Hafıza için tutulacak kelimeler
  bool _askedInitialMemoryRecall =
      false; // İlk hafıza tekrar sorusunun sorulup sorulmadığı
  bool _askedDelayedMemoryRecall =
      false; // Gecikmiş hafıza tekrar sorusunun sorulup sorulmadığı

  @override
  void initState() {
    super.initState();
    _showInitialInformation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showInitialInformation() {
    _addMessage(
      'gemini',
      'Bilişsel Test Ekranına Hoş Geldiniz!\n\n'
          'Bu test, bilişsel fonksiyonlarınızın farklı alanlarını (oryantasyon, hafıza, dikkat, dil, görsel-mekansal beceriler ve yürütücü işlevler) değerlendirmek üzere tasarlanmıştır. Size ardışık olarak $_maxQuestions soru sorulacaktır.\n\n'
          'Lütfen her soruyu dikkatlice okuyun ve tam, net cevaplar vermeye çalışın. Cevaplarınız, yapay zeka destekli sistemimiz tarafından değerlendirilecek ve bilişsel durumunuz hakkında kısa bir ön değerlendirme raporu oluşturulacaktır.\n\n'
          'Önemli Not: Bu test, kesin bir tıbbi tanı aracı değildir. Sadece genel gözlemler ve potansiyel güçlü/zayıf alanlar hakkında bilgi sağlar. Tıbbi tanı için her zaman bir uzmana danışmalısınız.\n\n'
          'Hazır olduğunuzda, lütfen aşağıdaki "Teste Başla" butonuna dokunun.',
    );
    _scrollToBottom();
  }

  Future<void> _startTest() async {
    setState(() {
      _testStarted = true; // Testi başlattık
      _messages.clear(); // Bilgilendirme mesajlarını temizle
      _questionCount = 0; // Soru sayacını sıfırla
      _rememberedWords = []; // Her yeni test başlangıcında kelimeleri sıfırla
      _askedInitialMemoryRecall = false;
      _askedDelayedMemoryRecall = false;
    });
    _loadInitialQuestion();
  }

  Future<void> _loadInitialQuestion() async {
    _setLoadingState(true, 'İlk soru yükleniyor...');
    _addMessage('gemini', 'İlk soru yükleniyor...');

    final prompt = '''
Sen bir nöropsikolojik test uzmanısın ve bilişsel bir test uyguluyorsun. 
Testin başında kullanıcıya testin genel amacını ve nasıl ilerleyeceğini açıkladın. 
Şimdi bilişsel alanlardan "oryantasyon" kategorisinde ilk soruyu sor. 
Sadece soruyu ver, ek bir açıklama, puanlama bilgisi veya değerlendirme cümlesi ekleme. 
Örnek: "Şu an hangi yıldayız?" veya "Şu an hangi şehirdeyiz?" gibi bir soru sor.
''';
    try {
      final response = await _geminiService.askGemini(prompt);
      _addMessage('gemini', response);
      setState(() {
        _questionCount++;
      });
    } catch (e) {
      _addMessage(
        'gemini',
        'Hata: İlk soru yüklenemedi. Lütfen internet bağlantınızı kontrol edin.',
      );
      debugPrint('İlk soru yükleme hatası: $e');
    } finally {
      _setLoadingState(false);
      _scrollToBottom();
    }
  }

  Future<void> _submitAnswer() async {
    final userAnswer = _messageController.text.trim();
    if (userAnswer.isEmpty) {
      _showSnackBar('Lütfen bir cevap girin.');
      return;
    }

    _addMessage('user', userAnswer);
    _setLoadingState(true, 'Cevabınız değerlendiriliyor...');
    _messageController.clear();

    if (_questionCount >= _maxQuestions) {
      await _finalizeTest();
    } else {
      await _loadNextQuestion();
    }
    _scrollToBottom();
  }

  Future<void> _loadNextQuestion() async {
    final String lastQuestion = _messages[_messages.length - 2]['text']!;
    final String lastAnswer = _messages.last['text']!;

    String nextQuestionPrompt = '';

    // Test akışı mantığı:
    // 1. Soru: Oryantasyon (İlk başta soruldu)
    // 2. Soru: Hafıza - Kelime ezberleme ve anında tekrar
    // 3. Soru: Dikkat
    // 4. Soru: Dil - Cümle dönüştürme
    // 5. Soru: Gecikmiş Hafıza (Kelime hatırlama) VEYA Yürütücü İşlev/Yargılama

    if (_questionCount == 1) {
      // Oryantasyon sorusundan sonra ilk hafıza görevini ver
      // Hafıza kelimelerini doğrudan uygulamada tanımlıyoruz
      _rememberedWords = ['elma', 'masa', 'araba'];
      nextQuestionPrompt =
          'Şimdi hafıza becerilerinizi test etmek için size 3 kelime söyleyeceğim. Lütfen bunları aklınızda tutun ve söyledikten hemen sonra tekrarlayın: ${_rememberedWords[0]}, ${_rememberedWords[1]}, ${_rememberedWords[2]}. Lütfen şimdi bu kelimeleri tekrarlayın.';
      _askedInitialMemoryRecall = true;
    } else if (_questionCount == 2) {
      // İkinci soru dikkat olsun
      nextQuestionPrompt =
          'Şimdi dikkat becerilerinizi test edeceğim. Size bir dizi sayı söyleyeceğim ve sondan başa doğru tekrarlamanızı isteyeceğim. Örneğin: 2-8-6 dersem, siz 6-8-2 diyeceksiniz. Şimdi 5-9-1-7.';
    } else if (_questionCount == 3) {
      // Üçüncü soru dil olsun (cümlenin formatını değiştirme)
      // Dil görevini buraya ekliyoruz
      nextQuestionPrompt =
          'Şimdi dil becerilerinizi test edeceğim. Lütfen "Bugün hava hiç de güzel değil." cümlesini olumlu bir hale getirerek yeniden ifade edin.';
      // Alternatif: 'Lütfen "Yarın güneşli bir gün olacak." cümlesini soru cümlesi haline getirin.'
    } else if (_questionCount == 4) {
      // Dördüncü soru gecikmiş hafıza VEYA yürütücü işlevler
      if (_rememberedWords.isNotEmpty && !_askedDelayedMemoryRecall) {
        nextQuestionPrompt =
            'Biraz önce size bazı kelimeleri aklınızda tutmanızı istemiştim. Lütfen o kelimeleri şimdi hatırlayıp söyleyebilir misiniz?';
        _askedDelayedMemoryRecall = true;
      } else {
        // Eğer hafıza kelimeleri sorulmadıysa veya zaten sorulduysa başka bir soru sor
        nextQuestionPrompt =
            'Şimdi yürütücü işlevlerinizi test edeceğim. Elma ve muz arasındaki ortak yön nedir?';
      }
    } else {
      // _questionCount == 5 ise (yani son soruya gelindi ve hala gecikmiş hafıza sorulmadıysa)
      if (_rememberedWords.isNotEmpty && !_askedDelayedMemoryRecall) {
        nextQuestionPrompt =
            'Biraz önce size bazı kelimeleri aklınızda tutmanızı istemiştim. Lütfen o kelimeleri şimdi hatırlayıp söyleyebilir misiniz?';
        _askedDelayedMemoryRecall = true;
      } else {
        // Son soru olarak hala hafıza sorulmadıysa veya zaten sorulduysa başka bir soru sor
        nextQuestionPrompt =
            'Şimdi yargılama becerilerinizi test edeceğim. Ormanda kaybolursanız ne yaparsınız?';
      }
    }

    final String prompt =
        '''
Kullanıcı önceki soruya ("$lastQuestion") "$lastAnswer" cevabını verdi. 
Sen bir nöropsikolojik test uzmanısın ve bilişsel test uygulamasına devam ediyorsun. 
Şimdi kullanıcıya aşağıdaki soruyu sor: "$nextQuestionPrompt"
Sadece soruyu ver, ek bir açıklama, puanlama bilgisi veya değerlendirme cümlesi ekleme. Kullanıcıya sanki sen bir uzmansın ve testin devam ettiğini belirtmek için soru kalıbını değiştirme, doğrudan soruyu sor.
''';

    try {
      final response = await _geminiService.askGemini(prompt);
      _addMessage('gemini', response);
      setState(() {
        _questionCount++;
      });
    } catch (e) {
      _addMessage(
        'gemini',
        'Hata: Yeni soru yüklenemedi. Lütfen internet bağlantınızı kontrol edin.',
      );
      debugPrint('Sonraki soru yükleme hatası: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _finalizeTest() async {
    _setLoadingState(true, 'Test sonuçları değerlendiriliyor...');
    _addMessage('gemini', 'Test sonuçları değerlendiriliyor...');
    _scrollToBottom();

    String testSummary = 'Bilişsel Test Verileri:\n';
    String memoryWordsInfo = '';

    // Hafıza kelimeleri varsa özete ekle
    if (_rememberedWords.isNotEmpty) {
      memoryWordsInfo =
          'Kullanıcıdan ezberlemesi istenen kelimeler: ${_rememberedWords.join(', ')}\n';
    }

    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i]['sender'] == 'gemini' &&
          (i + 1 < _messages.length) &&
          _messages[i + 1]['sender'] == 'user') {
        final question = _messages[i]['text'];
        final answer = _messages[i + 1]['text'];

        testSummary +=
            'Soru ${(_messages.indexOf(_messages[i]) ~/ 2) + 1}: $question\n';
        testSummary +=
            'Cevap ${(_messages.indexOf(_messages[i]) ~/ 2) + 1}: $answer\n\n';
      }
    }

    final prompt =
        '''
Kullanıcının cevapladığı bilişsel testin sorularını ve cevaplarını aşağıda bulacaksınız. 
${memoryWordsInfo.isNotEmpty ? '$memoryWordsInfo' : ''}
Bu verilere dayanarak, kullanıcının genel bilişsel durumu hakkında kısa ve öz bir ön değerlendirme yapın. 
Kesin tanı koymadan, sadece gözlemlerinizi ve potansiyel güçlü veya zayıf alanları belirtin. 
Test edilen bilişsel alanları (örn. oryantasyon, hafıza, dikkat, dil, yargılama, yürütücü işlevler, gecikmiş hatırlama) vurgulayın ve her bir alan için 1-2 cümlelik kısa bir yorumda bulunun. 
Değerlendirmeyi, kullanıcıya doğrudan hitap eden, anlaşılır ve profesyonel bir rapor şeklinde sunun.

Test Verileri:
$testSummary
''';
    try {
      final evaluation = await _geminiService.askGemini(prompt);
      _addMessage('gemini', 'Değerlendirme tamamlandı:\n$evaluation');
    } catch (e) {
      _addMessage(
        'gemini',
        'Hata: Değerlendirme alınamadı. Lütfen internet bağlantınızı kontrol edin.',
      );
      debugPrint('Değerlendirme hatası: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  void _addMessage(String sender, String text) {
    setState(() {
      _messages.add({'sender': sender, 'text': text});
    });
  }

  void _setLoadingState(bool loading, [String? statusMessage]) {
    setState(() {
      _isLoading = loading;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bilişsel Test',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            Expanded(
              child: _testStarted
                  ? ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final messageData = _messages[index];
                        final isUser = messageData['sender'] == 'user';
                        final isError = messageData['sender'] == 'error';
                        return MessageBubble(
                          text: messageData['text']!,
                          isUser: isUser,
                          isError: isError,
                        );
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _messages.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 30.0,
                                    ),
                                    child: Text(
                                      _messages.first['text']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : const SizedBox(),
                            ElevatedButton(
                              onPressed: _startTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A0DAD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
                        ),
                      ),
                    ),
            ),
            // Sohbet giriş alanı ve gönder butonu
            // Test başladıysa VE soru sayısı _maxQuestions'a ulaşmadıysa göster.
            // _maxQuestions'a ulaşıldığında (yani son soruyu cevapladığında) _finalizeTest çalışır ve bu kısım gizlenir.
            if (_testStarted &&
                _questionCount < _maxQuestions + 1 &&
                !_isLoading) // _maxQuestions + 1, son cevabın girilmesine izin verir
              AnswerInputArea(
                controller: _messageController,
                isLoading: _isLoading,
                onSubmit: _submitAnswer,
              ),
            // Soru sayacı
            // _questionCount <= _maxQuestions, son sorunun sayısını da göstermek için
            if (_testStarted && _questionCount <= _maxQuestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                child: Text(
                  'Tamamlanan Soru Sayısı: $_questionCount/$_maxQuestions',
                  style: const TextStyle(fontSize: 14, color: Colors.white54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
