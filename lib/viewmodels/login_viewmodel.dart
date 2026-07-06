import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// ViewModel pour gérer l'état et la logique de l'écran de connexion
// Hérite de ChangeNotifier pour pouvoir notifier la vue en cas de changement d'état
class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  LoginViewModel({required AuthService authService}) : _authService = authService;

  // Variables privées représentant l'état de la vue
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  User? _currentUser;

  // Getters publics pour exposer l'état à la vue de façon sécurisée (lecture seule)
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  User? get currentUser => _currentUser;

  // Modifie l'adresse email saisie par l'utilisateur
  void setEmail(String value) {
    _email = value;
    if (_errorMessage != null) {
      _errorMessage = null; // Réinitialise l'erreur dès que l'utilisateur écrit à nouveau
    }
    notifyListeners(); // Notifie l'écran pour rafraîchir l'affichage
  }

  // Modifie le mot de passe saisi
  void setPassword(String value) {
    _password = value;
    if (_errorMessage != null) {
      _errorMessage = null; // Réinitialise l'erreur
    }
    notifyListeners();
  }

  // Alterne l'affichage en clair / masqué du mot de passe
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Valide localement les champs saisis avant l'envoi vers le backend
  bool validateInputs() {
    if (_email.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir votre adresse email.';
      notifyListeners();
      return false;
    }
    // Validation par expression régulière (regex) du format de l'email
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
    return true; // Tous les champs sont valides
  }

  // Action d'authentification (déclenchée par le bouton de connexion)
  Future<bool> login() async {
    // 1. Validation locale
    if (!validateInputs()) {
      return false;
    }

    // 2. Activation du chargement (affichage d'un indicateur de progression)
    _isLoading = true;
    _errorMessage = null;

    try {
      // 3. Appel asynchrone du service d'authentification API
      _currentUser = await _authService.login(_email, _password);
      _isLoading = false;
      notifyListeners();
      return true; // Connexion réussie
    } on AuthException catch (e) {
      // Cas d'erreur gérée (identifiants faux, problème réseau attendu)
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Autres erreurs imprévues
      _errorMessage = 'Une erreur inattendue est survenue. Veuillez réessayer.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Réinitialise l'état du ViewModel (ex: après déconnexion ou retour arrière)
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
