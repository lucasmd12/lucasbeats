import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class QuestionnaireService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Criar novo questionário
  Future<void> createQuestionnaire(QuestionnaireModel questionnaire) async {
    try {
      await _firestore.collection('questionnaires').doc(questionnaire.id).set(questionnaire.toMap());
    } catch (e) {
      debugPrint('Erro ao criar questionário: $e');
      throw Exception('Falha ao criar questionário: $e');
    }
  }
  
  // Obter todos os questionários
  Stream<List<QuestionnaireModel>> getQuestionnaires() {
    return _firestore
        .collection('questionnaires')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return QuestionnaireModel.fromMap(doc.data());
      }).toList();
    });
  }
  
  // Obter questionários ativos
  Stream<List<QuestionnaireModel>> getActiveQuestionnaires() {
    return _firestore
        .collection('questionnaires')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return QuestionnaireModel.fromMap(doc.data());
      }).toList();
    });
  }
  
  // Atualizar questionário
  Future<void> updateQuestionnaire(QuestionnaireModel questionnaire) async {
    try {
      await _firestore.collection('questionnaires').doc(questionnaire.id).update(questionnaire.toMap());
    } catch (e) {
      debugPrint('Erro ao atualizar questionário: $e');
      throw Exception('Falha ao atualizar questionário: $e');
    }
  }
  
  // Excluir questionário
  Future<void> deleteQuestionnaire(String questionnaireId) async {
    try {
      await _firestore.collection('questionnaires').doc(questionnaireId).delete();
    } catch (e) {
      debugPrint('Erro ao excluir questionário: $e');
      throw Exception('Falha ao excluir questionário: $e');
    }
  }
  
  // Ativar/desativar questionário
  Future<void> toggleQuestionnaireStatus(String questionnaireId, bool isActive) async {
    try {
      await _firestore.collection('questionnaires').doc(questionnaireId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('Erro ao alterar status do questionário: $e');
      throw Exception('Falha ao alterar status do questionário: $e');
    }
  }
  
  // Enviar resposta de questionário
  Future<void> submitQuestionnaireResponse(String questionnaireId, String userId, Map<String, dynamic> responses) async {
    try {
      await _firestore.collection('questionnaire_responses').add({
        'questionnaireId': questionnaireId,
        'userId': userId,
        'responses': responses,
        'submittedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erro ao enviar resposta de questionário: $e');
      throw Exception('Falha ao enviar resposta de questionário: $e');
    }
  }
}
