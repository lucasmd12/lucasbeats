import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obter todos os usuários
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('joinDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  }
  
  // Atualizar função do usuário
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar função do usuário: $e');
      throw Exception('Falha ao atualizar função do usuário: $e');
    }
  }
  
  // Verificar se o usuário tem permissão para gerenciar funções
  Future<bool> canManageRoles(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'member';
        return role == 'admin' || role == 'owner';
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
      return false;
    }
  }
  
  // Verificar se o usuário é o dono
  Future<bool> isOwner(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'member';
        return role == 'owner';
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar se é dono: $e');
      return false;
    }
  }
}
