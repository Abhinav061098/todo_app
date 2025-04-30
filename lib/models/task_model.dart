class Task {
  final String? id;
  final String title;
  final String description;
  final bool isCompleted;
  final String owner;
  final List<String> sharedWith;
  final Map<String, dynamic> shareStatus;
  final String? originalTaskId;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;
  final DateTime? createdAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.owner,
    required this.sharedWith,
    required this.shareStatus,
    this.originalTaskId,
    this.lastModifiedBy,
    this.lastModifiedAt,
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      owner: json['owner'] ?? '',
      sharedWith: List<String>.from(json['sharedWith'] ?? ['default']),
      shareStatus: Map<String, dynamic>.from(json['shareStatus'] ?? {}),
      originalTaskId: json['originalTaskId'],
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModifiedAt'])
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'owner': owner,
      'sharedWith': sharedWith,
      'shareStatus': shareStatus,
      'originalTaskId': originalTaskId,
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedAt': lastModifiedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  String getShareStatus(String userId) {
    if (!shareStatus.containsKey(userId)) {
      return sharedWith.contains(userId) ? 'pending' : '';
    }
    return shareStatus[userId] ?? '';
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? owner,
    List<String>? sharedWith,
    Map<String, dynamic>? shareStatus,
    String? originalTaskId,
    String? lastModifiedBy,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      owner: owner ?? this.owner,
      sharedWith: sharedWith ?? this.sharedWith,
      shareStatus: shareStatus ?? this.shareStatus,
      originalTaskId: originalTaskId ?? this.originalTaskId,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
