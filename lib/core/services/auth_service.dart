import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Pengguna yang sedang aktif saat ini
  User? get currentUser => _auth.currentUser;

  // Masuk via Google (Sign in with Google)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna membatalkan dialog login
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Gagal login dengan Google: $e';
    }
  }

  // Registrasi Akun Baru
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Simpan nama display pengguna
      if (credential.user != null && name.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Terjadi kesalahan sistem: $e';
    }
  }

  // Masuk / Login Akun
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Terjadi kesalahan sistem: $e';
    }
  }

  // Logout / Keluar
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // Konversi kode error Firebase menjadi pesan bahasa Indonesia yang mudah dipahami
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-credential':
        return 'Email atau password salah. Silakan periksa kembali.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau masuk.';
      case 'invalid-email':
        return 'Format penulisan email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'network-request-failed':
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
      case 'user-disabled':
        return 'Akun pengguna ini telah dinonaktifkan oleh administrator.';
      case 'operation-not-allowed':
        return 'Metode login Email/Password belum diaktifkan di Firebase Console.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}
