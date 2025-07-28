import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      await result.user?.updateDisplayName(fullName);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Kayıt hatası: ${e.message}");
      return null;
    }
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Giriş hatası: ${e.message}");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  User? get currentUser => _auth.currentUser;
}
