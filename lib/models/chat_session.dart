class ChatSession {
  String id;
  String title;
  String folder;
  List<Map<String, dynamic>> messages;
  String modelId;

  ChatSession({
    required this.id, 
    required this.title, 
    required this.messages, 
    required this.modelId,
    this.folder = 'General',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'folder': folder,
    'messages': messages,
    'modelId': modelId,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    folder: json['folder'] ?? 'General',
    messages: List<Map<String, dynamic>>.from(json['messages']),
    modelId: json['modelId'],
  );
}
