class ApiConfig {
  ApiConfig._(); // Constructeur privé pour empêcher l'instanciation de cette classe utilitaire.

  // Pour l'émulateur Android : '10.0.2.2' pointe vers la machine de développement locale (localhost).
  // Si vous utilisez un appareil physique, remplacez cette adresse par l'adresse IP locale de votre ordinateur.
  static const String baseUrl = 'http://10.0.2.2:3000';
}
