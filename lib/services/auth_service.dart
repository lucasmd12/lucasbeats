import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Import for debugPrint
import '../models/user_model.dart';
import '../utils/logger.dart'; // Use consistent logger

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
    required String username, // Use 'username' consistently
    required String gameName,
    required String whatsapp,
  }) async {
    try {
      Logger.info("Attempting registration for email: $email");
      // Criar usuário no Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info("Auth user created: ${result.user?.uid}");

      // Atualizar display name no Auth (opcional, mas bom ter)
      try {
        await result.user?.updateDisplayName(username);
        Logger.info("Auth display name updated to: $username");
      } catch (e) {
        Logger.warning("Failed to update Auth display name: $e");
      }

      // Criar perfil do usuário no Firestore
      await _createUserProfile(
        uid: result.user!.uid,
        username: username,
        email: email,
        gameName: gameName,
        whatsapp: whatsapp,
      );

      return result;
    } on FirebaseAuthException catch (e) {
      Logger.error("Firebase Auth Registration Failed", error: e);
      throw Exception('Falha ao registrar: ${_getErrorMessage(e)}');
    } catch (e, stackTrace) {
      Logger.error("Generic Registration Failed", error: e, stackTrace: stackTrace);
      throw Exception('Falha ao registrar: Ocorreu um erro inesperado.');
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
      Logger.info("Creating Firestore profile for UID: $uid");
      // Verificar se é o primeiro usuário (será o dono)
      QuerySnapshot usersSnapshot = await _firestore.collection('users').limit(1).get();
      String role = usersSnapshot.docs.isEmpty ? 'owner' : 'member';
      Logger.info("Assigning role: $role");

      // Data de ingresso
      String joinDate = DateTime.now().toIso8601String();

      // Criar modelo de usuário (usando o UserModel atualizado)
      UserModel user = UserModel(
        uid: uid,
        username: username,
        email: email,
        gameName: gameName,
        whatsapp: whatsapp,
        role: role,
        joinDate: joinDate,
        online: true, // Marcar como online ao criar perfil
        ultimoPing: Timestamp.now(),
        fcmTokens: [], // Inicializa vazio
        // clanId e canalVozAtual são nulos por padrão
      );

      // Salvar no Firestore usando toMap()
      await _firestore.collection('users').doc(uid).set(user.toMap());
      Logger.info("Firestore profile created successfully for UID: $uid");
    } catch (e, stackTrace) {
      Logger.error("Error creating Firestore profile", error: e, stackTrace: stackTrace);
      // Considerar deletar o usuário do Auth se a criação do perfil falhar?
      // await _auth.currentUser?.delete(); // Cuidado com esta lógica
      throw Exception('Falha ao criar perfil no banco de dados.');
    }
  }

  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info("Attempting login for email: $email");
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info("Login successful for UID: ${credential.user?.uid}");
      // Atualizar status online no Firestore após login
      if (credential.user != null) {
        await _updateOnlineStatus(credential.user!.uid, true);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      Logger.error("Firebase Auth Login Failed", error: e);
      throw Exception('Falha ao fazer login: ${_getErrorMessage(e)}');
    } catch (e, stackTrace) {
      Logger.error("Generic Login Failed", error: e, stackTrace: stackTrace);
      throw Exception('Falha ao fazer login: Ocorreu um erro inesperado.');
    }
  }

  // Logout
  Future<void> signOut() async {
    final userId = _auth.currentUser?.uid;
    try {
      Logger.info("Attempting logout for UID: $userId");
      // Atualizar status offline no Firestore antes de deslogar
      if (userId != null) {
        await _updateOnlineStatus(userId, false);
      }
      await _auth.signOut();
      Logger.info("Logout successful.");
    } catch (e, stackTrace) {
      Logger.error("Logout Failed", error: e, stackTrace: stackTrace);
      throw Exception('Falha ao fazer logout.');
    }
  }

  // Obter dados do usuário atual do Firestore
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      Logger.info("getCurrentUserData: No user logged in.");
      return null;
    }
    try {
      Logger.info("Fetching Firestore data for UID: ${user.uid}");
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        Logger.info("Firestore data found for UID: ${user.uid}");
        return UserModel.fromFirestore(doc); // Use fromFirestore factory
      } else {
        Logger.warning("Firestore document not found for UID: ${user.uid}");
        return null;
      }
    } catch (e, stackTrace) {
      Logger.error("Error getting user data from Firestore", error: e, stackTrace: stackTrace);
      return null; // Retorna nulo em caso de erro, não lança exceção
    }
  }

  // Atualizar perfil do usuário no Firestore
  Future<void> updateUserProfile(UserModel user) async {
    // Garante que estamos atualizando o documento do usuário correto
    if (user.uid != _auth.currentUser?.uid) {
      Logger.error("Security Alert: Attempt to update profile for a different user.");
      throw Exception("Não autorizado a atualizar este perfil.");
    }
    try {
      Logger.info("Updating Firestore profile for UID: ${user.uid}");
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      Logger.info("Profile updated successfully.");
    } catch (e, stackTrace) {
      Logger.error("Error updating profile", error: e, stackTrace: stackTrace);
      throw Exception('Falha ao atualizar perfil.');
    }
  }

  // Atualiza o status online e último ping no Firestore
  Future<void> _updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'online': isOnline,
        'ultimoPing': FieldValue.serverTimestamp(),
        // Se ficar offline, limpar o canal atual (opcional, mas boa prática)
        if (!isOnline) 'canalVozAtual': null,
      });
      Logger.info("Online status updated for $uid: $isOnline");
    } catch (e) {
      // Não lançar exceção aqui, apenas logar, pois pode falhar se o doc não existir
      Logger.warning("Failed to update online status for $uid (may be normal if doc doesn't exist yet): $e");
    }
  }

  // Verificar se o usuário é administrador ou dono
  Future<bool> isAdminOrOwner() async {
    try {
      UserModel? user = await getCurrentUserData();
      return user != null && (user.role == 'admin' || user.role == 'owner');
    } catch (e) {
      Logger.error("Error checking admin/owner permissions", error: e);
      return false;
    }
  }

  // Verificar se o usuário é dono
  Future<bool> isOwner() async {
    try {
      UserModel? user = await getCurrentUserData();
      return user != null && user.role == 'owner';
    } catch (e) {
      Logger.error("Error checking owner permissions", error: e);
      return false;
    }
  }

  // Converter mensagens de erro Firebase Auth para formato amigável
  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Este email já está em uso por outra conta.';
      case 'invalid-email':
        return 'O formato do email fornecido é inválido.';
      case 'user-not-found':
        return 'Nenhuma conta encontrada para este email.';
      case 'wrong-password':
        return 'Senha incorreta. Por favor, tente novamente.';
      case 'weak-password':
        return 'A senha fornecida é muito fraca.';
      case 'network-request-failed':
        return 'Falha na conexão. Verifique sua internet.';
      case 'permission-denied':
        return 'Permissão negada para acessar o recurso.';
      case 'operation-not-allowed':
        return 'Login com email/senha não está habilitado.';
      case 'user-disabled':
        return 'Este usuário foi desabilitado.';
      default:
        Logger.warning("Unhandled FirebaseAuthException code: ${error.code}");
        return 'Ocorreu um erro inesperado durante a autenticação.';
    }
  }
}

