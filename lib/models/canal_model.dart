import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar um canal de voz no Firestore.
class CanalModel {
  final String id; // ID único do canal (geralmente o ID do documento Firestore)
  final String nome; // Nome do canal (ex: Sala de Comando)
  final List<String> membros; // Lista de UIDs dos membros atualmente no canal
  final bool ativo; // Indica se o canal está ativo/disponível
  final Timestamp? criadoEm; // Data/hora de criação do canal

  CanalModel({
    required this.id,
    required this.nome,
    this.membros = const [],
    this.ativo = true,
    this.criadoEm,
  });

  /// Converte um documento do Firestore em um objeto CanalModel.
  factory CanalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CanalModel(
      id: doc.id,
      nome: data['nome'] ?? 'Canal Sem Nome',
      // Garante que membros seja sempre uma lista de Strings
      membros: List<String>.from(data['membros'] ?? []),
      ativo: data['ativo'] ?? true,
      criadoEm: data['criadoEm'] as Timestamp?,
    );
  }

  /// Converte o objeto CanalModel em um Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      // Não incluímos o ID aqui, pois ele é o ID do documento
      'nome': nome,
      'membros': membros,
      'ativo': ativo,
      'criadoEm': criadoEm ?? FieldValue.serverTimestamp(), // Usa timestamp do servidor se nulo
    };
  }
}

