import 'package:flutter/material.dart';
import 'package:neurograph/services/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Sohbet mesajını temsil eden sınıf.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({
    required this.text, 
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> 
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final GeminiService _geminiService;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _messages.add(ChatMessage(
      text: "🌟 Merhaba! Ben NeuroGraph'ın beyin sağlığı asistanıyım. Uygulama veya genel beyin sağlığı hakkında sorularını yanıtlayabilirim. 🧠✨",
      isUser: false,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Mesaj gönderme işlemini yönetir
  void _sendMessage() async {
    if (_textController.text.isEmpty || _isLoading) return;

    final userMessage = _textController.text;
    _textController.clear();

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    final systemPrompt = """
    Sen, NeuroGraph adlı mobil uygulama için bir AI asistanısın. 
    Uygulamanın amacı ve vizyonu, kullanıcıların bilişsel sağlıklarını kapsamlı testlerle değerlendirmek ve onları bilinçli kararlar alabilmeleri için bilgilendirmektir.
    
    Uygulamadaki testler şunlardır:
    1.  **Bilişsel Test:** Kullanıcının hafıza, dikkat ve problem çözme becerilerini ölçen etkileşimli bir testtir.
    2.  **Çizim Testi:** Görsel-motor koordinasyonunu ve mekansal farkındalığı değerlendiren bir testtir.
    3.  **Sesli Okuma Testi:** Okuma akıcılığı, telaffuz ve anlama becerilerini analiz eden bir testtir.
    
    Ayrıca uygulama, kullanıcılara bu testlerin sonuçlarına dayalı kişiselleştirilmiş raporlar sunar ve beyin sağlıkları hakkında genel bilgiler sağlar.
    
    Kullanıcının sorularını bu bilgiler ışığında, yardımsever ve bilgilendirici bir şekilde cevaplamalısın. Yanıtlarında uygun emoji'ler kullanabilirsin.
    """;

    final combinedPrompt = "$systemPrompt\n\nKullanıcı: $userMessage";

    // Typing indicator ekle
    final botMessageIndex = _messages.length;
    _messages.add(ChatMessage(text: "...", isUser: false));
    setState(() {});

    // Gemini'den yanıt almak için servis üzerinden API çağrısı yapılır.
    final responseText = await _geminiService.askGemini(combinedPrompt);

    // Yanıtı kelime kelime göstermek için bir döngü
    final words = responseText.split(' ');
    String currentText = "";
    for (var word in words) {
      currentText += "$word ";
      if (mounted) {
        setState(() {
          _messages[botMessageIndex] = ChatMessage(text: currentText, isUser: false);
        });
      }
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 50)); // Gecikme
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  // Ekranı her zaman en alttaki mesaja kaydırır
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8E6FF), // Açık pembe
              Color(0xFFE6F3FF), // Açık mavi
              Color(0xFFF0F8FF), // Çok açık mavi
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.white, // Arka plan beyazlığını kaldırmak için
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20.0),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return _ChatMessageWidget(message: message);
                                },
                              ),
                            ),
                          ),
                          if (_isLoading) _buildTypingIndicator(),
                          Container(
                            color: Colors.white,
                            child: _buildMessageInput(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC8A2C8), Color(0xFFE6C9FF)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded, // Robot ikonu
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NeuroGraph Asistanı 🤖',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                Text(
                  '💬 Beyin sağlığı rehberiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
                const SizedBox(width: 8),
                Text(
                  'Yazıyor...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 200)),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _isLoading ? const Color(0xFFC8A2C8) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white, // Arka plan beyazlığını kaldırmak için
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '💭 Mesajınızı yazın...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12), // Mesaj alanı ile gönder butonu arasında boşluk
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC8A2C8), Color(0xFFE6C9FF)],
              ),
              borderRadius: BorderRadius.circular(27.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(27.5),
                onTap: _sendMessage,
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  const _ChatMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    String displayText = message.text.replaceAll('**', '');
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: 
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // end yerine start
        children: [
          if (!message.isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7, // 0.75'ten 0.7'ye düşürdük
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFFC8A2C8)
                    : const Color(0xFFF0F0F0), // Gradient yerine düz renk
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser 
                      ? const Radius.circular(20) 
                      : const Radius.circular(6),
                  bottomRight: message.isUser 
                      ? const Radius.circular(6) 
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        gradient: isUser 
            ? const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              )
            : const LinearGradient(
                colors: [Color(0xFFC8A2C8), Color(0xFFE6C9FF)],
              ),
        borderRadius: BorderRadius.circular(17.5),
        boxShadow: [
          BoxShadow(
            color: (isUser ? Colors.green : Colors.purple).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy_rounded, // Bot için robot ikonu
        color: Colors.white,
        size: 20,
      ),
    );
  }
}