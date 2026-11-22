class ChatSession {
  String id;
  String title;
  List<Map<String, String>> messages;
  String modelId;

  ChatSession({required this.id, required this.title, required this.messages, required this.modelId});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages,
    'modelId': modelId,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    messages: List<Map<String, String>>.from(json['messages'].map((x) => Map<String, String>.from(x))),
    modelId: json['modelId'],
  );
}
