import 'package:flutter/foundation.dart';
import 'package:todo_app/services/auth/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _error;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  String? _pendingSharedTaskId;
  int _retryCount = 0;
  static const int maxRetries = 3;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?['uid'];

  String? get pendingSharedTaskId => _pendingSharedTaskId;
  set pendingSharedTaskId(String? value) {
    _pendingSharedTaskId = value;
    if (value != null) {
      print('Pending shared task ID set: $value');
    }
    notifyListeners();
  }

  AuthViewModel() {
    _initializeAuth();
    // Listen for auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _currentUser = {
          'uid': user.uid,
          'email': user.email,
          'displayName':
              user.displayName ?? user.email?.split('@')[0] ?? user.uid,
        };
        print('User authenticated: ${user.uid}');
        // Check for pending tasks after authentication
        if (_pendingSharedTaskId != null) {
          print('Found pending shared task: $_pendingSharedTaskId');
        }
      } else {
        _currentUser = null;
        _pendingSharedTaskId = null;
      }
      notifyListeners();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      _currentUser = _authService.currentUser;
    } catch (e) {
      print('Auth initialization error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    _retryCount = 0;
    notifyListeners();

    try {
      bool success = false;
      Map<String, dynamic>? result;

      while (!success && _retryCount < maxRetries) {
        result = await _authService.signInWithEmailAndPassword(email, password);
        success = result['success'];

        if (!success) {
          _retryCount++;
          if (_retryCount < maxRetries) {
            // Wait before retrying
            await Future.delayed(Duration(milliseconds: 500 * _retryCount));
          }
        }
      }

      _isLoading = false;

      if (success) {
        _currentUser = result?['user'];
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result?['error'] ?? 'Failed to sign in';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String email, String password, String displayName) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.registerWithEmailAndPassword(
          email, password, displayName);

      _isLoading = false;

      if (result['success']) {
        // Sign out immediately after successful registration
        await signOut();
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'Failed to register';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Registration error: $e');
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _pendingSharedTaskId = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
