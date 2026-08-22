import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.isOnline,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'] ?? '';
    return UserModel(
      id: id.toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      isOnline: json['isOnline'] == true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'isOnline': isOnline,
    'lastSeen': lastSeen?.toIso8601String(),
  };

  UserModel copyWith({
    bool? isOnline,
    DateTime? lastSeen,
    String? name,
    String? avatar,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatar, isOnline, lastSeen];
}
