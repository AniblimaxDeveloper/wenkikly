class ChatSession {
  String id;
  String title;
  String folder;
  List<Map<String, dynamic>> messages;
  String modelId;
  String? systemPromptOverride;
  double? temperatureOverride;
  bool isPinned;

  ChatSession({
    required this.id, 
    required this.title, 
    required this.messages, 
    required this.modelId,
    this.folder = 'General',
    this.systemPromptOverride,
    this.temperatureOverride,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'folder': folder,
    'messages': messages,
    'modelId': modelId,
    'systemPromptOverride': systemPromptOverride,
    'temperatureOverride': temperatureOverride,
    'isPinned': isPinned,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    folder: json['folder'] ?? 'General',
    messages: List<Map<String, dynamic>>.from(json['messages']),
    modelId: json['modelId'],
    systemPromptOverride: json['systemPromptOverride'],
    temperatureOverride: json['temperatureOverride'],
    isPinned: json['isPinned'] ?? false,
  );
}
