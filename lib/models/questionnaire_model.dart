
class QuestionnaireModel {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final String createdBy;
  final String createdAt;
  final bool isActive;
  
  QuestionnaireModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });
  
  // Construtor de cópia com possibilidade de alterar campos
  QuestionnaireModel copyWith({
    String? id,
    String? title,
    String? description,
    List<Question>? questions,
    String? createdBy,
    String? createdAt,
    bool? isActive,
  }) {
    return QuestionnaireModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
  
  // Converter de Map para QuestionnaireModel
  factory QuestionnaireModel.fromMap(Map<String, dynamic> map) {
    return QuestionnaireModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      questions: List<Question>.from(
        (map['questions'] ?? []).map((q) => Question.fromMap(q))
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
  
  // Converter de QuestionnaireModel para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}

class Question {
  final String id;
  final String text;
  final String type; // 'text', 'multiple_choice', 'single_choice'
  final List<String>? options;
  
  Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
  });
  
  // Construtor de cópia com possibilidade de alterar campos
  Question copyWith({
    String? id,
    String? text,
    String? type,
    List<String>? options,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
    );
  }
  
  // Converter de Map para Question
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
    );
  }
  
  // Converter de Question para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'options': options,
    };
  }
}
