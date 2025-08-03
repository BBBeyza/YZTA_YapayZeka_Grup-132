import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // video_player import'u
import 'package:chewie/chewie.dart'; // chewie import'u
import 'package:neurograph/screens/drawing_test.dart';

class TutorialScreen extends StatefulWidget {
  final String testKey;
  final String testTitle;
  final String instruction;
  final String videoUrl; // Bu URL asset path'i veya network URL'i olabilir

  const TutorialScreen({
    super.key,
    required this.testKey,
    required this.testTitle,
    required this.instruction,
    required this.videoUrl,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoadingVideo = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (widget.videoUrl.isEmpty) {
      print("Video URL'si boş. Lütfen geçerli bir URL sağlayın.");
      setState(() {
        _isLoadingVideo = false;
        _errorMessage = "Video URL'si boş.";
      });
      return;
    }

    // Video URL'sinin asset mi yoksa network mü olduğunu kontrol edin
    if (widget.videoUrl.startsWith('assets/')) {
      _videoPlayerController = VideoPlayerController.asset(widget.videoUrl);
    } else {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }

    try {
      await _videoPlayerController.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,  // Otomatik oynat
          looping: true,   // Sürekli döngüye al
          showControls: false, // Oynatma kontrollerini gizle
          // Videonun kendi en-boy oranını kullan, eğer yoksa 16:9 varsay.
          aspectRatio: _videoPlayerController.value.aspectRatio.isFinite && _videoPlayerController.value.aspectRatio > 0
              ? _videoPlayerController.value.aspectRatio
              : 16 / 9,
          placeholder: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Video yüklenemedi: $errorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
        _isLoadingVideo = false;
      });
      // Otomatik oynatma ChewieController'da ayarlandığı için burada tekrar oynatma komutuna gerek yok.
      // _videoPlayerController.play();
    } catch (e) {
      print("Video oynatıcı başlatılırken hata oluştu: $e");
      setState(() {
        _isLoadingVideo = false;
        _errorMessage = 'Video yüklenemedi veya oynatılamıyor: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    // Controller'ları düzgünce dispose edin
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.testTitle}'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // İçerik alanı - scrollable
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      widget.instruction,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    _isLoadingVideo
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : _errorMessage.isNotEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                        : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                        ? SizedBox(
                      height: MediaQuery.of(context).size.width * 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Chewie(
                          controller: _chewieController!,
                        ),
                      ),
                    )
                        : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Video yüklenemedi veya oynatılamıyor.'),
                      ),
                    ),
                    const SizedBox(height: 20), // Video ile buton arası boşluk
                  ],
                ),
              ),
            ),
          ),
          // Sabit buton alanı
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DrawingTestScreen(
                          testKey: widget.testKey,
                          testTitle: widget.testTitle,
                          testInstruction: widget.instruction,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Çizime Başla',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}