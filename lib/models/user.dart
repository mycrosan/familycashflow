class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      profilePicture: json['profile_picture'] as String?,
      createdAt: json['created_at'] is String 
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] is String 
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }
}

