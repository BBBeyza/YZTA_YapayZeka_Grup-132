import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> 
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  
  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;
  String _selectedGender = 'Belirtilmemiş';
  DateTime? _birthDate;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Test verileri
  int _completedTests = 0;
  int _totalScore = 0;
  DateTime? _lastTestDate;
  String _currentLevel = 'Başlangıç';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _loadTestStatistics();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _loadUserData() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      });
      return;
    }

    _currentUser = currentUser;
    _nameController.text = _currentUser.displayName ?? '';
    _emailController.text = _currentUser.email ?? '';
    
    // Burada SharedPreferences veya Firestore'dan ek bilgileri yükleyebilirsiniz
    // Şimdilik örnek veriler kullanıyorum
    _phoneController.text = '+90 555 123 45 67';
    _ageController.text = '22';
    _aboutController.text = 'Nörolojik değerlendirme testlerine katılan kullanıcı.';
    _birthDate = DateTime(1995, 6, 15);
  }

  void _loadTestStatistics() {
    // Burada gerçek test verilerini yükleyeceksiniz
    // Şimdilik örnek veriler
    setState(() {
      _completedTests = 12;
      _totalScore = 850;
      _lastTestDate = DateTime.now().subtract(const Duration(days: 3));
      _currentLevel = _calculateLevel(_totalScore);
    });
  }

  String _calculateLevel(int score) {
    if (score >= 800) return 'Uzman';
    if (score >= 600) return 'İleri';
    if (score >= 400) return 'Orta';
    if (score >= 200) return 'Başlangıç';
    return 'Yeni Başlayan';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Uzman':
        return const Color.fromARGB(255, 155, 66, 180);
      case 'İleri':
        return const Color.fromARGB(255, 47, 117, 177);
      case 'Orta':
        return const Color.fromARGB(255, 59, 155, 64);
      case 'Başlangıç':
        return const Color.fromARGB(255, 218, 137, 37);
      default:
        return const Color.fromARGB(255, 120, 114, 189);
    }
  }

  Future<void> _signOut() async {
    try {
      setState(() => _isLoading = true);

      final authStateSubscription = _auth.authStateChanges().listen((_) {});
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 500));
      await authStateSubscription.cancel();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Sign out error: $e');
      if (!mounted) return;
      _showSnackBar('Oturum kapatma hatası: ${e.toString()}', false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFE1BEE7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _ageController.text = _calculateAge(picked).toString();
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => _isLoading = true);

      await _currentUser.updateDisplayName(_nameController.text.trim());

      if (_emailController.text.trim() != _currentUser.email) {
        await _currentUser.verifyBeforeUpdateEmail(
          _emailController.text.trim(),
        );
        _showSnackBar(
          'Doğrulama maili gönderildi. Lütfen emailinizi kontrol edin.',
          true,
        );
      }

      // Burada diğer bilgileri de kaydedebilirsiniz (SharedPreferences/Firestore)
      
      setState(() => _isEditing = false);
      _showSnackBar('Profil başarıyla güncellendi', true);
    } catch (e) {
      _showSnackBar('Güncelleme hatası: ${e.toString()}', false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrationDate = _currentUser.metadata.creationTime ?? DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1BEE7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Profilim',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            gradient: LinearGradient(
              colors: [Color(0xFFE1BEE7), Color.fromARGB(255, 184, 107, 198)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Profile Picture Section
                      _buildProfilePictureSection(),
                      const SizedBox(height: 30),
                      
                      // User Level Badge
                      _buildLevelBadge(),
                      const SizedBox(height: 25),
                      
                      // User Info Section
                      _buildUserInfoSection(),
                      const SizedBox(height: 20),
                      
                      // Personal Details Section
                      _buildPersonalDetailsSection(),
                      const SizedBox(height: 20),
                      
                      // Test Statistics Section
                      _buildTestStatisticsSection(),
                      const SizedBox(height: 20),
                      
                      // Account Info Section
                      _buildAccountInfoSection(registrationDate),
                      const SizedBox(height: 30),
                      
                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: GestureDetector(
        onTap: _isEditing ? _pickImage : null,
        child: Hero(
          tag: 'profile_picture',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE1BEE7).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE1BEE7).withOpacity(0.3),
                        const Color.fromARGB(255, 179, 86, 196).withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('assets/images/profile.png') as ImageProvider,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1BEE7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLevelColor(_currentLevel),
            _getLevelColor(_currentLevel).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getLevelColor(_currentLevel).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _currentLevel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isEditing) ...[
            _buildEditableField(
              controller: _nameController,
              label: 'Ad Soyad',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ] else ...[
            Text(
              _currentUser.displayName ?? 'Kullanıcı',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 109, 30, 138),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser.email ?? 'email@example.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: const Color(0xFFE1BEE7),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Kişisel Bilgiler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 118, 30, 138),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isEditing) ...[
            _buildEditableField(
              controller: _phoneController,
              label: 'Telefon',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_rounded, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Text(
                      _birthDate != null 
                          ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                          : 'Doğum Tarihi Seçin',
                      style: TextStyle(
                        color: _birthDate != null ? Colors.black87 : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Cinsiyet',
                prefixIcon: Icon(Icons.wc_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['Erkek', 'Kadın', 'Belirtilmemiş'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            _buildEditableField(
              controller: _aboutController,
              label: 'Hakkımda',
              icon: Icons.info_outline_rounded,
              maxLines: 3,
            ),
          ] else ...[
            _buildInfoRow(Icons.phone_rounded, 'Telefon', _phoneController.text),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.cake_rounded, 
              'Doğum Tarihi', 
              _birthDate != null 
                  ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                  : 'Belirtilmemiş'
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.wc_rounded, 'Cinsiyet', _selectedGender),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.info_outline_rounded, 'Hakkımda', _aboutController.text),
          ],
        ],
      ),
    );
  }

  Widget _buildTestStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: const Color(0xFFE1BEE7),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Test İstatistikleri',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 115, 30, 138),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Tamamlanan',
                  value: '$_completedTests',
                  icon: Icons.assignment_turned_in_rounded,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Toplam Puan',
                  value: '$_totalScore',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.schedule_rounded,
            'Son Test',
            _lastTestDate != null
                ? '${_lastTestDate!.day}/${_lastTestDate!.month}/${_lastTestDate!.year}'
                : 'Henüz test yapılmamış',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(DateTime registrationDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                color: const Color(0xFFE1BEE7),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Hesap Bilgileri',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 115, 30, 138),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Üyelik Tarihi',
            '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}',
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            Icons.verified_user_rounded,
            'Hesap Durumu',
            _currentUser.emailVerified ? 'Doğrulanmış' : 'Doğrulanmamış',
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF72B0D3), width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFE1BEE7).withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color.fromARGB(255, 111, 30, 138),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditing) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFE1BEE7), Color.fromARGB(255, 193, 74, 226)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE1BEE7).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _updateProfile,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text(
                'Değişiklikleri Kaydet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = _currentUser.displayName ?? '';
                  _emailController.text = _currentUser.email ?? '';
                  _profileImage = null;
                });
              },
              icon: Icon(Icons.cancel_rounded, color: Colors.grey.shade600),
              label: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFE1BEE7), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE1BEE7).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: const Text(
                'Profili Düzenle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Settings Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              // Settings sayfasına git
              _showSettingsDialog();
            },
            icon: Icon(Icons.settings_rounded, color: Colors.grey.shade700),
            label: Text(
              'Ayarlar',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Logout Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text(
              'Oturumu Kapat',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.settings_rounded, color: const Color(0xFF72B0D3)),
              const SizedBox(width: 12),
              const Text('Ayarlar'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.notifications_rounded, color: Colors.orange.shade600),
                title: const Text('Bildirimler'),
                subtitle: const Text('Bildirim ayarlarını yönet'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Bildirim ayarları yakında gelecek!', true);
                },
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_rounded, color: Colors.green.shade600),
                title: const Text('Gizlilik'),
                subtitle: const Text('Gizlilik politikası'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Gizlilik ayarları yakında gelecek!', true);
                },
              ),
              ListTile(
                leading: Icon(Icons.help_rounded, color: Colors.blue.shade600),
                title: const Text('Yardım'),
                subtitle: const Text('Sık sorulan sorular'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      "🧠 Neurograph – Sık Sorulan Sorular (SSS)",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 12),
                        Text(
                        "1. Neurograph nedir?\n"
                        "Neurograph, çizim tabanlı bilişsel testler (ör. Saat Çizme Testi, Spiral Testi) "
                        "ve uygulamalı bilişsel bataryalar (MMSE, MoCA, Stroop Testi vb.) üzerinden "
                        "kullanıcıların bilişsel sağlığını takip etmeyi sağlayan yapay zeka destekli bir mobil uygulamadır.\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "2. Neurograph hangi amaçla kullanılabilir?\n"
                        "- Bilişsel bozuklukların erken tespiti\n"
                        "- El yazısı ve çizim analizleriyle motor beceri bozukluklarının incelenmesi\n"
                        "- Düzenli bilişsel sağlık takibi\n"
                        "- Kullanıcıya özel raporlar ve öneriler sunma\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "3. Uygulama hangi teknolojileri kullanıyor?\n"
                        "- Frontend: Flutter\n"
                        "- Backend: FastAPI\n"
                        "- Veri tabanı: PostgreSQL veya Firebase\n"
                        "- Yapay Zeka: TensorFlow / Torchvision + Gemini\n"
                        "- Analiz: Görsel sınıflandırma ve NLP tabanlı değerlendirmeler\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "4. Neurograph doktorların yerini alır mı?\n"
                        "Hayır. Bu uygulama teşhis aracı değil, destekleyici bir takip aracıdır.\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "5. Testler nasıl çalışıyor?\n"
                        "- Kullanıcı test yapar\n"
                        "- Çizimler CNN tabanlı analiz edilir\n"
                        "- Bilişsel testler LLM tabanlı puanlanır\n"
                        "- Sonuçlar rapor olarak sunulur\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "6. Sonuçlar ne kadar güvenilir?\n"
                        "Bilimsel testlere dayalıdır, ancak kesin tanı için profesyonel sağlık değerlendirmesi gerekir.\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "7. Verilerim güvenli mi?\n"
                        "- Anonimleştirilerek saklanır\n"
                        "- AES şifreleme + JWT kimlik doğrulama\n"
                        "- Onay olmadan paylaşılmaz\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "8. Kimler kullanabilir?\n"
                        "- Bilişsel sağlığını takip etmek isteyen herkes\n"
                        "- Risk grubundaki bireyler\n"
                        "- Kliniklerde sağlık çalışanları\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "9. Uygulama ücretli mi olacak?\n"
                        "Temel özellikler ücretsiz olabilir, premium paket detaylı rapor ve uzman desteği sunabilir.\n",
                        ),
                        SizedBox(height: 8),
                        Text(
                        "10. Gelecek özellikler:\n"
                        "- Ses, yazı, göz takibi\n"
                        "- Uzmanlarla çevrimiçi bağlantı\n"
                        "- Topluluk desteği\n"
                        "- Genetik verilerle kişiselleştirilmiş öneriler\n",
                        ),
                      ],
                      ),
                    ),
                    actions: [
                      TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Kapat',
                        style: const TextStyle(color: Color(0xFFE1BEE7)),
                      ),
                      ),
                    ],
                    );
                  },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info_rounded, color: Colors.purple.shade600),
                title: const Text('Hakkında'),
                subtitle: const Text('Uygulama hakkında'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Kapat',
                style: TextStyle(color: const Color(0xFFE1BEE7)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_rounded, color: const Color(0xFFE1BEE7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uygulama Hakkında',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 29, 29, 29),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neurograph',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 107, 30, 138),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versiyon: 1.0.0',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nörolojik değerlendirme ve test uygulaması. '
                'Bilişsel performansınızı ölçmek ve takip etmek için geliştirilmiştir.',
              ),
              const SizedBox(height: 16),
              Text(
                '© 2024 Neurograph Team',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tamam',
                style: TextStyle(color: const Color(0xFFE1BEE7)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              const SizedBox(width: 12),
              const Text('Oturumu Kapat'),
            ],
          ),
          content: const Text(
            'Oturumunuzu kapatmak istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}