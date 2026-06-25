class User {
  final String id;
  final String email;
  final String name;
  final String token;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.token,
  });

  // Factory to create User from a JSON structure
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      token: json['token'] as String,
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'token': token,
    };
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';
}
