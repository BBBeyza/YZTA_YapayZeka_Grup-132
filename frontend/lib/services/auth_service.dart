import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
      // Firebase'in başlatıldığından emin ol
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase başlatılmamış');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;

      if (user != null) {
        try {
          await user.updateDisplayName(fullName);
        } catch (e) {
          print("Display name güncelleme hatası: $e");
          // Display name güncellenemese bile kullanıcı oluşturulmuş olur
        }
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth kayıt hatası: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("Genel kayıt hatası: $e");
      throw Exception('Kayıt işlemi sırasında beklenmeyen bir hata oluştu: $e');
    }
  }

  // Giriş yapma metodu
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase'in başlatıldığından emin ol
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase başlatılmamış');
      }

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
      print("Firebase Auth giriş hatası: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Genel giriş hatası: $e");
      throw Exception('Giriş işlemi sırasında beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<void> _safeSignOut() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    try {
      await _auth.signOut();
      // Firebase'in tamamen senkronize olmasını bekle
      await _auth.authStateChanges().firstWhere((user) => user == null);
    } catch (e) {
      print("Çıkış hatası: $e");
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> signOut() async {
    await _safeSignOut();
  }

  // Kullanıcı durumu akışı
  Stream<User?> get user {
    try {
      return _auth.authStateChanges();
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
}
