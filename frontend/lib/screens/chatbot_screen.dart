import 'package:flutter/material.dart';
import 'package:neurograph/services/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Sohbet mesajını temsil eden sınıf.
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final GeminiService _geminiService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _messages.add(ChatMessage(
      text: "Merhaba! Ben NeuroGraph'ın beyin sağlığı asistanıyım. Uygulama veya genel beyin sağlığı hakkında sorularını yanıtlayabilirim.",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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
    
    Kullanıcının sorularını bu bilgiler ışığında, yardımsever ve bilgilendirici bir şekilde cevaplamalısın.
    """;

    final combinedPrompt = "$systemPrompt\n\nKullanıcı: $userMessage";

    // Sohbet yanıtı için "..." içeren bir mesaj ekle
    final botMessageIndex = _messages.length;
    _messages.add(ChatMessage(text: "...", isUser: false));

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
      appBar: AppBar(
        title: const Text('Gemini Chat'),
        backgroundColor: const Color(0xFFC8A2C8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatMessageWidget(message: message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
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
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFC8A2C8) : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: message.isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: message.isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}
