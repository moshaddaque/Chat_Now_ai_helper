import 'package:dash_chat_2/dash_chat_2.dart';

class ChatMessage {
  String id;
  String text;
  ChatUser user;
  DateTime createdAt;
  List<ChatMedia>? medias;

  ChatMessage({
    required this.id,
    required this.text,
    required this.user,
    required this.createdAt,
    this.medias,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'medias': medias
          ?.map(
            (media) => media.toJson(),
          )
          .toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      user: ChatUser.fromJson(json['user']),
      createdAt: DateTime.parse(json['createdAt']),
      medias: json['medias'] != null
          ? (json['medias'] as List)
              .map(
                (item) => ChatMedia.fromJson(item),
              )
              .toList()
          : null,
    );
  }
}
