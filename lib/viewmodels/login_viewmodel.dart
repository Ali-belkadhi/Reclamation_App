import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  LoginViewModel({required AuthService authService}) : _authService = authService;

  // View state fields
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  User? _currentUser;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  User? get currentUser => _currentUser;

  // Setters/actions that update state and notify view listeners
  void setEmail(String value) {
    _email = value;
    if (_errorMessage != null) {
      _errorMessage = null; // Clear error when user type changes
    }
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    if (_errorMessage != null) {
      _errorMessage = null; // Clear error when user type changes
    }
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Local inline validations
  bool validateInputs() {
    if (_email.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir votre adresse email.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email.trim())) {
      _errorMessage = 'Format d\'adresse email invalide.';
      notifyListeners();
      return false;
    }
    if (_password.isEmpty) {
      _errorMessage = 'Veuillez saisir votre mot de passe.';
      notifyListeners();
      return false;
    }
    if (_password.length < 6) {
      _errorMessage = 'Le mot de passe doit comporter au moins 6 caractères.';
      notifyListeners();
      return false;
    }
    
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  // Action login
  Future<bool> login() async {
    if (!validateInputs()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(_email, _password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue. Veuillez réessayer.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _email = '';
    _password = '';
    _isLoading = false;
    _errorMessage = null;
    _isPasswordVisible = false;
    _currentUser = null;
    notifyListeners();
  }
}
