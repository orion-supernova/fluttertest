import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/appwrite_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  final AppwriteService _appwrite;
  bool _isLoading = true;
  String? _error;

  UserProvider(this._appwrite) {
    _initUser();
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _initUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to create anonymous session
      await _appwrite.anonymousLogin();

      _user = await _appwrite.createOrUpdateUser(
        nickname:
            'Agent${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error initializing user: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() async {
    print('Retrying initialization...');
    await _initUser(); // Just reuse the initialization logic
  }

  Future<void> updateNickname(String nickname) async {
    try {
      _user = await _appwrite.createOrUpdateUser(nickname: nickname);
      notifyListeners();
    } catch (e) {
      print('Error updating nickname: $e');
      rethrow;
    }
  }
}
