
class MissionModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String createdAt;
  final String status;
  final List<String> assignedTo;
  final DateTime? dueDate;
  
  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    required this.assignedTo,
    this.dueDate,
  });
  
  // Construtor de cópia com possibilidade de alterar campos
  MissionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? createdAt,
    String? status,
    List<String>? assignedTo,
    DateTime? dueDate,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
    );
  }
  
  // Converter de Map para MissionModel
  factory MissionModel.fromMap(Map<String, dynamic> map) {
    return MissionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? '',
      status: map['status'] ?? 'pending',
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    );
  }
  
  // Converter de MissionModel para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'status': status,
      'assignedTo': assignedTo,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
