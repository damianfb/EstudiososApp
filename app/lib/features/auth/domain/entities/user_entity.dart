import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un usuario de la app.
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, avatarUrl, createdAt];
}
