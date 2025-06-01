import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar um usuário no Firestore.
class UserModel {
  final String uid;
  final String username; // Nome de usuário (usado em AuthService)
  final String? email; // Email do usuário
  final String? gameName; // Nome no jogo (usado em AuthService)
  final String? whatsapp; // WhatsApp (usado em AuthService)
  final String role; // Cargo/função (ex: owner, admin, member)
  final String? joinDate; // Data de ingresso (ISO String)
  final String? fotoUrl; // URL da foto de perfil
  String? canalVozAtual; // ID do canal de voz atual
  bool online; // Status de presença
  Timestamp? ultimoPing; // Último ping de atividade
  List<String> fcmTokens; // Tokens FCM
  String? clanId; // ID do clã (se aplicável)

  UserModel({
    required this.uid,
    required this.username,
    this.email,
    this.gameName,
    this.whatsapp,
    required this.role,
    this.joinDate,
    this.fotoUrl,
    this.canalVozAtual,
    this.online = false,
    this.ultimoPing,
    this.fcmTokens = const [],
    this.clanId,
  });

  // Getter para compatibilidade onde 'displayName' é esperado
  String get displayName => username;

  // Getter para compatibilidade onde \'nome\' é esperado (usado em outros arquivos)
  String get nome => username;

  // Getter para compatibilidade onde \'canal\' é esperado (usado em chat_list_tab.dart)
  String? get canal => canalVozAtual;

  /// Converte um documento do Firestore em um objeto UserModel.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Verifica se doc.data() não é nulo antes de tentar acessá-lo
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Retorna um UserModel padrão ou lança um erro se os dados forem nulos
      // Aqui, vamos retornar um modelo com valores padrão ou vazios para evitar null checks
      // Ajuste conforme a lógica de negócio necessária
      print("Erro: Documento Firestore sem dados para o ID: ${doc.id}");
      return UserModel(
        uid: doc.id,
        username: 'Usuário Inválido',
        role: 'member',
        // Defina outros campos obrigatórios com valores padrão
      );
    }

    return UserModel(
      uid: doc.id,
      username: data['username'] ?? 'Usuário Indefinido',
      email: data['email'],
      gameName: data['gameName'],
      whatsapp: data['whatsapp'],
      role: data['role'] ?? 'member', // Default role
      joinDate: data['joinDate'],
      fotoUrl: data['fotoUrl'],
      canalVozAtual: data['canalVozAtual'],
      online: data['online'] ?? false,
      ultimoPing: data['ultimoPing'] as Timestamp?,
      // Garante que fcmTokens seja sempre uma lista, mesmo que nula ou não seja lista no Firestore
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      clanId: data['clanId'],
    );
  }

  /// Converte um Map (geralmente de JSON ou dados locais) em um objeto UserModel.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? 'Usuário Indefinido',
      email: map['email'],
      gameName: map['gameName'],
      whatsapp: map['whatsapp'],
      role: map['role'] ?? 'member',
      joinDate: map['joinDate'],
      fotoUrl: map['fotoUrl'],
      canalVozAtual: map['canalVozAtual'],
      online: map['online'] ?? false,
      ultimoPing: map['ultimoPing'] != null
          ? (map['ultimoPing'] is Timestamp
              ? map['ultimoPing']
              : Timestamp.fromDate(DateTime.parse(map['ultimoPing'] as String)))
          : null,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      clanId: map['clanId'],
    );
  }

  /// Converte o objeto UserModel em um Map para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      // uid não é incluído aqui, pois é o ID do documento
      'username': username,
      // Usa 'this.' para clareza, embora não estritamente necessário
      if (this.email != null) 'email': this.email,
      if (this.gameName != null) 'gameName': this.gameName,
      if (this.whatsapp != null) 'whatsapp': this.whatsapp,
      'role': this.role,
      if (this.joinDate != null) 'joinDate': this.joinDate,
      if (this.fotoUrl != null) 'fotoUrl': this.fotoUrl,
      if (this.canalVozAtual != null) 'canalVozAtual': this.canalVozAtual,
      'online': this.online,
      // Usa FieldValue.serverTimestamp() apenas se ultimoPing for nulo ao salvar
      'ultimoPing': this.ultimoPing ?? FieldValue.serverTimestamp(),
      'fcmTokens': this.fcmTokens,
      if (this.clanId != null) 'clanId': this.clanId,
    };
  }
}

