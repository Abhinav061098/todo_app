import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _auth.app.setAutomaticDataCollectionEnabled(true);
      await _auth.authStateChanges().first;
      _initialized = true;
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _ensureInitialized();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Failed to sign in: No user returned',
        };
      }

      return {
        'success': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'displayName':
              user.displayName ?? user.email?.split('@')[0] ?? user.uid,
        }
      };
    } on FirebaseAuthException catch (e) {
      print('AuthService signIn error: ${e.code} - ${e.message}');
      String errorMessage = 'An error occurred during sign in';
      switch (e.code) {
        case 'network-request-failed':
          errorMessage = 'Please check your internet connection';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'channel-error':
      
          await _reInitializeAuth();
          errorMessage = 'Please try again';
          break;
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('Unexpected auth error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred',
      };
    }
  }

  Future<void> _reInitializeAuth() async {
    _initialized = false;
    await _ensureInitialized();
  }

  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(displayName);
      }

      return {
        'success': true,
        'user': {
          'uid': user?.uid,
          'email': user?.email,
          'displayName': displayName,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Map<String, dynamic>? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@')[0] ?? user.uid,
    };
  }


  String? get currentUserId => _auth.currentUser?.uid;


  String? getCurrentUserDisplayName() {
    final user = _auth.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? user?.uid;
  }
}
