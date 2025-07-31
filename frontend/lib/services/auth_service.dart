import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggingOut = false;

  // Kayıt olma metodu
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(fullName);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("Kayıt hatası: ${e.message}");
      throw e; // Hataları iletmek için throw kullanıyoruz
    }
  }

  // Giriş yapma metodu
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Önce mevcut oturumu temizle
      if (!_isLoggingOut && _auth.currentUser != null) {
        await _safeSignOut();
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Auth state'in güncellenmesini bekle
      await _auth.authStateChanges().firstWhere((user) => user != null);

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Giriş hatası: ${e.message}");
      rethrow;
    }
  }

  Future<void> _safeSignOut() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    try {
      await _auth.signOut();
      // Firebase'in tamamen senkronize olmasını bekle
      await _auth.authStateChanges().firstWhere((user) => user == null);
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> signOut() async {
    await _safeSignOut();
  }

  // Kullanıcı durumu akışı
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Mevcut kullanıcı
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Current user error: $e');
      return null;
    }
  }
}
