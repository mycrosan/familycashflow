class Member {
  final int? id;
  final String name;
  final String relation;
  final String? profilePicture;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    this.id,
    required this.name,
    required this.relation,
    this.profilePicture,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int?,
      name: json['name'] as String,
      relation: json['relation'] as String,
      profilePicture: json['profile_picture'] as String?,
      userId: json['user_id'] as int,
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
      'relation': relation,
      'profile_picture': profilePicture,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Member copyWith({
    int? id,
    String? name,
    String? relation,
    String? profilePicture,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      profilePicture: profilePicture ?? this.profilePicture,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Member && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Member(id: $id, name: $name, relation: $relation)';
  }

  // Getters úteis
  bool get hasProfilePicture => profilePicture != null && profilePicture!.isNotEmpty;
  String get initials => name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
}

