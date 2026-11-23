class ChatSession {
  String id;
  String title;
  String folder;
  bool isArchived;
  bool isPinned;
  List<Map<String, dynamic>> messages;
  String modelId;
  String? systemPromptOverride; // FIX: Tambah variabel ini
  double? temperatureOverride;  // FIX: Tambah variabel ini

  ChatSession({
    required this.id, 
    required this.title, 
    required this.messages, 
    required this.modelId,
    this.folder = 'General',
    this.isArchived = false,
    this.isPinned = false,
    this.systemPromptOverride,
    this.temperatureOverride,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'folder': folder,
    'isArchived': isArchived,
    'isPinned': isPinned,
    'messages': messages,
    'modelId': modelId,
    'systemPromptOverride': systemPromptOverride,
    'temperatureOverride': temperatureOverride,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    folder: json['folder'] ?? 'General',
    isArchived: json['isArchived'] ?? false,
    isPinned: json['isPinned'] ?? false,
    messages: List<Map<String, dynamic>>.from(json['messages']),
    modelId: json['modelId'],
    systemPromptOverride: json['systemPromptOverride'],
    temperatureOverride: json['temperatureOverride'],
  );
}
