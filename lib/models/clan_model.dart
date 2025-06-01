import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar um Clã ou Federação no Firestore.
class ClanModel {
  final String id; // ID único do clã (ID do documento Firestore)
  final String nome;
  final String? descricao;
  final String? bandeiraUrl; // URL da imagem da bandeira/logo do clã
  final List<String> tags; // Lista de tags ou categorias do clã
  final List<String> membros; // Lista de UIDs dos membros do clã
  final List<String> administradores; // Lista de UIDs dos administradores/líderes
  final List<String> canaisVoz; // Lista de IDs dos canais de voz associados
  final List<String> canaisTexto; // Lista de IDs dos canais de texto associados
  final Timestamp criadoEm;

  ClanModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.bandeiraUrl,
    this.tags = const [],
    this.membros = const [],
    this.administradores = const [],
    this.canaisVoz = const [],
    this.canaisTexto = const [],
    required this.criadoEm,
  });

  /// Converte um documento do Firestore em um objeto ClanModel.
  factory ClanModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClanModel(
      id: doc.id,
      nome: data['nome'] ?? 'Clã Sem Nome',
      descricao: data['descricao'],
      bandeiraUrl: data['bandeiraUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      membros: List<String>.from(data['membros'] ?? []),
      administradores: List<String>.from(data['administradores'] ?? []),
      canaisVoz: List<String>.from(data['canaisVoz'] ?? []),
      canaisTexto: List<String>.from(data['canaisTexto'] ?? []),
      criadoEm: data['criadoEm'] as Timestamp? ?? Timestamp.now(), // Fallback para agora
    );
  }

  /// Converte o objeto ClanModel em um Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      // Não incluímos o ID aqui, pois ele é o ID do documento
      'nome': nome,
      if (descricao != null) 'descricao': descricao,
      if (bandeiraUrl != null) 'bandeiraUrl': bandeiraUrl,
      'tags': tags,
      'membros': membros,
      'administradores': administradores,
      'canaisVoz': canaisVoz,
      'canaisTexto': canaisTexto,
      'criadoEm': criadoEm, // Ou FieldValue.serverTimestamp() na criação inicial
    };
  }
}

