import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggingOut = false;

  // Kayıt olma metodu - improved error handling
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Firebase'in başlatıldığından emin ol
      await Firebase.initializeApp();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;

      if (user != null) {
        try {
          // Display name güncelleme
          await user.updateDisplayName(fullName);
          await user.reload(); // Kullanıcı bilgilerini yenile
        } catch (e) {
          print("Display name güncelleme hatası: $e");
        }
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth kayıt hatası: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Genel kayıt hatası: $e");
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Kayıt işlemi sırasında beklenmeyen bir hata oluştu: $e',
      );
    }
  }

  // Giriş yapma metodu - improved with better error handling
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase'in başlatıldığından emin ol
      await Firebase.initializeApp();

      // Mevcut kullanıcı varsa önce çıkış yap
      if (_auth.currentUser != null && !_isLoggingOut) {
        await _safeSignOut();
        // Auth state'in temizlenmesini bekle
        await Future.delayed(const Duration(milliseconds: 500));
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      
      if (user != null) {
        // Kullanıcı bilgilerini yenile
        await user.reload();
        // Auth state değişikliğini bekle
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth giriş hatası: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Genel giriş hatası: $e");
      throw FirebaseAuthException(
        code: 'unknown', 
        message: 'Giriş işlemi sırasında beklenmeyen bir hata oluştu: $e',
      );
    }
  }

  Future<void> _safeSignOut() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    try {
      await _auth.signOut();
      // Auth state değişikliğini bekle
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print("Çıkış hatası: $e");
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> signOut() async {
    await _safeSignOut();
  }

  // Kullanıcı durumu akışı - improved error handling
  Stream<User?> get user {
    try {
      return _auth.authStateChanges().handleError((error) {
        print("Auth state stream hatası: $error");
        return null;
      });
    } catch (e) {
      print("Auth state stream hatası: $e");
      return Stream.value(null);
    }
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

  // Şifre sıfırlama metodu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Şifre sıfırlama hatası: ${e.code} - ${e.message}");
      rethrow;
    }
  }
}