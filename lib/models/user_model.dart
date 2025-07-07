import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar Role
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Importar Logger para logs de debug

class User {
  final String id;
  final String username;

  final String? avatar;
  final String? bio;
  final String status;
  final String? clanId; // Pode ser nulo se não tiver clã
  final String? clanName; // Adicionado: Nome do clã
  final String? clanTag; // Adicionado: Tag do clã
  final Role clanRole; // Alterado para Role
  final String? federationId; // Pode ser nulo
  final String? federationName; // Adicionado: Nome da federação
  final String? federationTag; // Adicionado: Tag da federação
  final Role federationRole; // Adicionado: Papel na federação
  final Role role; // Alterado para Role
  final bool online;
  final DateTime? ultimaAtividade; // Pode ser nulo
  final DateTime? lastSeen; // Pode ser nulo
  final DateTime? createdAt; // Adicionado: Data de criação do usuário

  User({
    required this.id,
    required this.username,
    this.avatar, // Default value is null
    this.bio = 'Sem biografia.',
    this.status = 'offline',
    this.clanId,
    this.clanName,
    this.clanTag,
    this.clanRole = Role.member, // Valor padrão como enum
    this.federationId,
    this.federationName,
    this.federationTag,
    this.federationRole = Role.member, // Valor padrão como enum
    this.role = Role.user, // Valor padrão como enum
    this.online = false,
    this.ultimaAtividade, // Permitir nulo
    this.lastSeen, // Permitir nulo
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get a string from a potentially nested object
    String? _getStringOrIdFromMap(dynamic value) {
      if (value is String) {
        return value; // Se já é String, retorna
      } else if (value is Map<String, dynamic>) {
        // Se é um Map, tenta obter o 'id' como String?
        return value['id'] as String?;
      }
      // Log para depuração se o tipo não for o esperado
      if (value != null) {
         Logger.warning('Expected String or Map for ID, but got ${value.runtimeType}');
      }
      return null; // Retorna nulo se não for String nem Map
    }

    // Helper function to safely get a name from a potentially nested object
    String? _getNameFromMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        // Se é um Map, tenta obter o 'name' como String?
        return value['name'] as String?;
      }
      // Log para depuração se o tipo não for o esperado
       if (value != null) {
         Logger.warning('Expected Map for Name, but got ${value.runtimeType}');
      }
      return null; // Retorna nulo se não for Map
    }

    // Helper function to safely get a tag from a potentially nested object
    String? _getTagFromMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        // Se é um Map, tenta obter o 'tag' como String?
        return value['tag'] as String?;
      }
       if (value != null) {
         Logger.warning('Expected Map for Tag, but got ${value.runtimeType}');
      }
      return null; // Retorna nulo se não for Map
    }

     // Helper function to safely parse DateTime
    DateTime? _parseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          Logger.error('Failed to parse DateTime string: $value', error: e);
          return null;
        }
      }
       if (value != null) {
         Logger.warning('Expected String for DateTime, but got ${value.runtimeType}');
      }
      return null; // Retorna nulo se não for String
    }


    // Safely get clan and federation data
    final dynamic clanData = json['clan'];
    final dynamic federationData = json['federation'];

    // Safely get role and clanRole
    final dynamic rawRole = json['role'];
    final dynamic rawClanRole = json['clanRole'];

    return User(
      id: json['_id'] as String, // Assumindo que _id sempre é String e não nulo
      username: json['username'] as String, // Assumindo que username sempre é String e não nulo

      avatar: json['avatar'] as String?, // Default is null if json['avatar'] is null
      bio: json['bio'] as String?,
      status: json['status'] as String? ?? 'offline',

      // Handle clan data which might be a String ID or a Map object
      clanId: _getStringOrIdFromMap(clanData),
      clanName: _getNameFromMap(clanData),
      clanTag: _getTagFromMap(clanData),
      // Tratar rawClanRole que deveria ser String, mas pode vir diferente
      clanRole: rawClanRole is String ? roleFromString(rawClanRole) : Role.member,


      // Handle federation data which might be a String ID or a Map object
      federationId: _getStringOrIdFromMap(federationData),
      federationName: _getNameFromMap(federationData),
      federationTag: _getTagFromMap(federationData),
      // Tratar federationRole que deveria ser String, mas pode vir diferente
      federationRole: json['federationRole'] is String ? roleFromString(json['federationRole']) : Role.member,
      // Tratar rawRole que deveria ser String, mas pode vir diferente
      role: rawRole is String ? roleFromString(rawRole) : Role.user,


      online: json['online'] as bool? ?? false,
      // Usar helper function para parsear DateTime com segurança
      ultimaAtividade: _parseDateTime(json['ultimaAtividade']),
      lastSeen: _parseDateTime(json['lastSeen']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,

      'avatar': avatar,
      'bio': bio,
      'status': status,
      'clanId': clanId,
      'clanName': clanName,
      'clanTag': clanTag,
      'clanRole': roleToString(clanRole), // Convertendo de enum para string
      'federationId': federationId,
      'federationName': federationName,
      'federationTag': federationTag,
      'federationRole': roleToString(federationRole), // Convertendo de enum para string
      'role': roleToString(role), // Convertendo de enum para string
      'online': online,
      'ultimaAtividade': ultimaAtividade?.toIso8601String(), // Usar ?. para evitar erro se nulo
      'lastSeen': lastSeen?.toIso8601String(), // Usar ?. para evitar erro se nulo
      'createdAt': createdAt?.toIso8601String(), // Usar ?. para evitar erro se nulo
    };
  }

  // Getter para isOnline (compatibilidade com backend)
  bool get isOnline => online; // Já existe a propriedade 'online'

  // Getter para tag (se houver um campo 'tag' no backend para o usuário)
  String? get tag => federationTag; // Usando federationTag como 'tag' se aplicável

  // Getter para 'clan' e 'federation' para compatibilidade com o código existente
  String? get clan => clanId;
  String? get federation => federationId;
}