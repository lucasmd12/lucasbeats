import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obter usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream de alterações de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrar com email e senha
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String gameName,
    required String whatsapp,
  }) async {
    try {
      // Criar usuário no Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Criar perfil do usuário no Firestore
      await _createUserProfile(
        uid: result.user!.uid,
        username: username,
        email: email,
        gameName: gameName,
        whatsapp: whatsapp,
      );
      
      return result;
    } catch (e) {
      debugPrint('Erro ao registrar usuário: $e');
      throw Exception('Falha ao registrar: ${_getErrorMessage(e)}');
    }
  }

  // Criar perfil do usuário no Firestore
  Future<void> _createUserProfile({
    required String uid,
    required String username,
    required String email,
    required String gameName,
    required String whatsapp,
  }) async {
    try {
      // Verificar se é o primeiro usuário (será o dono)
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      String role = usersSnapshot.docs.isEmpty ? 'owner' : 'member';
      
      // Data de ingresso
      String joinDate = DateTime.now().toIso8601String();
      
      // Criar modelo de usuário
      UserModel user = UserModel(
        uid: uid,
        username: username,
        email: email,
        gameName: gameName,
        whatsapp: whatsapp,
        role: role,
        joinDate: joinDate,
      );
      
      // Salvar no Firestore
      await _firestore.collection('users').doc(uid).set(user.toMap());
    } catch (e) {
      debugPrint('Erro ao criar perfil do usuário: $e');
      throw Exception('Falha ao criar perfil: ${_getErrorMessage(e)}');
    }
  }

  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Erro ao fazer login: $e');
      throw Exception('Falha ao fazer login: ${_getErrorMessage(e)}');
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      throw Exception('Falha ao fazer logout: ${_getErrorMessage(e)}');
    }
  }

  // Obter dados do usuário atual
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter dados do usuário: $e');
      throw Exception('Falha ao obter dados do usuário: ${_getErrorMessage(e)}');
    }
  }

  // Atualizar perfil do usuário
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      throw Exception('Falha ao atualizar perfil: ${_getErrorMessage(e)}');
    }
  }

  // Verificar se o usuário é administrador ou dono
  Future<bool> isAdminOrOwner() async {
    try {
      UserModel? user = await getCurrentUserData();
      return user != null && (user.role == 'admin' || user.role == 'owner');
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
      return false;
    }
  }

  // Verificar se o usuário é dono
  Future<bool> isOwner() async {
    try {
      UserModel? user = await getCurrentUserData();
      return user != null && user.role == 'owner';
    } catch (e) {
      debugPrint('Erro ao verificar permissões de dono: $e');
      return false;
    }
  }
  
  // Converter mensagens de erro para formato amigável
  String _getErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    
    if (errorMessage.contains('email-already-in-use')) {
      return 'Este email já está em uso';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Email inválido';
    } else if (errorMessage.contains('user-not-found')) {
      return 'Usuário não encontrado';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Senha incorreta';
    } else if (errorMessage.contains('weak-password')) {
      return 'Senha muito fraca';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Problema de conexão com a internet';
    } else if (errorMessage.contains('permission-denied')) {
      return 'Permissão negada';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'Operação não permitida';
    }
    
    return 'Ocorreu um erro inesperado';
  }
}
