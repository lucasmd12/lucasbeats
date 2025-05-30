import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/mission_model.dart';

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Criar nova missão
  Future<void> createMission(MissionModel mission) async {
    try {
      await _firestore.collection('missions').doc(mission.id).set(mission.toMap());
    } catch (e) {
      debugPrint('Erro ao criar missão: $e');
      throw Exception('Falha ao criar missão: $e');
    }
  }
  
  // Obter todas as missões
  Stream<List<MissionModel>> getMissions() {
    return _firestore
        .collection('missions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MissionModel.fromMap(doc.data());
      }).toList();
    });
  }
  
  // Obter missões de um usuário específico
  Stream<List<MissionModel>> getUserMissions(String userId) {
    return _firestore
        .collection('missions')
        .where('assignedTo', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MissionModel.fromMap(doc.data());
      }).toList();
    });
  }
  
  // Atualizar missão
  Future<void> updateMission(MissionModel mission) async {
    try {
      await _firestore.collection('missions').doc(mission.id).update(mission.toMap());
    } catch (e) {
      debugPrint('Erro ao atualizar missão: $e');
      throw Exception('Falha ao atualizar missão: $e');
    }
  }
  
  // Excluir missão
  Future<void> deleteMission(String missionId) async {
    try {
      await _firestore.collection('missions').doc(missionId).delete();
    } catch (e) {
      debugPrint('Erro ao excluir missão: $e');
      throw Exception('Falha ao excluir missão: $e');
    }
  }
  
  // Atualizar status da missão
  Future<void> updateMissionStatus(String missionId, String status) async {
    try {
      await _firestore.collection('missions').doc(missionId).update({
        'status': status,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar status da missão: $e');
      throw Exception('Falha ao atualizar status da missão: $e');
    }
  }
  
  // Atribuir missão a usuários
  Future<void> assignMissionToUsers(String missionId, List<String> userIds) async {
    try {
      await _firestore.collection('missions').doc(missionId).update({
        'assignedTo': userIds,
      });
    } catch (e) {
      debugPrint('Erro ao atribuir missão a usuários: $e');
      throw Exception('Falha ao atribuir missão a usuários: $e');
    }
  }
}
