class ChatSession {
  String id;
  String title;
  String folder;
  bool isArchived;
  bool isPinned;
  List<Map<String, dynamic>> messages;
  String modelId;

  ChatSession({
    required this.id, 
    required this.title, 
    required this.messages, 
    required this.modelId,
    this.folder = 'General',
    this.isArchived = false,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'folder': folder,
    'isArchived': isArchived,
    'isPinned': isPinned,
    'messages': messages,
    'modelId': modelId,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    folder: json['folder'] ?? 'General',
    isArchived: json['isArchived'] ?? false,
    isPinned: json['isPinned'] ?? false,
    messages: List<Map<String, dynamic>>.from(json['messages']),
    modelId: json['modelId'],
  );
}
