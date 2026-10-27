import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, text, isUser, createdAt];
}
