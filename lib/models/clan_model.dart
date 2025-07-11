import 'dart:convert';

class CustomRole {
  final String name;
  final List<String> permissions;
  final String? color;

  CustomRole({
    required this.name,
    required this.permissions,
    this.color,
  });

  factory CustomRole.fromMap(Map<String, dynamic> map) {
    return CustomRole(
      name: map["name"] ?? "",
      permissions: List<String>.from(map["permissions"] ?? []),
      color: map["color"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "permissions": permissions,
      if (color != null) "color": color,
    };
  }
}

class Clan {
  final String id;
  final String name;
  final String tag;
  final String leaderId;
  final String? description;
  final String? bannerImageUrl; // Adicionado
  final String? flag; // Adicionado - bandeira do clã
  final List<String>? members; // IDs, não objetos
  final List<String>? subLeaders; // Adicionado para refletir o backend
  final List<String>? allies;
  final List<String>? enemies;
  final List<String>? textChannels;
  final List<String>? voiceChannels;
  final List<Map<String, dynamic>>? memberRoles; // userId -> role
  final List<CustomRole>? customRoles; // Adicionado - cargos customizados
  final String? rules;
  final DateTime? createdAt;

  Clan({
    required this.id,
    required this.name,
    required this.tag,
    required this.leaderId,
    this.description,
    this.bannerImageUrl, // Adicionado
    this.flag, // Adicionado
    this.members,
    this.subLeaders, // Adicionado ao construtor
    this.allies,
    this.enemies,
    this.textChannels,
    this.voiceChannels,
    this.memberRoles,
    this.customRoles, // Adicionado
    this.rules,
    this.createdAt,
  });

  factory Clan.fromMap(Map<String, dynamic> map) {
    return Clan(
      id: map["_id"] ?? "",
      name: map["name"] ?? "",
      tag: map["tag"] ?? "",
      leaderId: map["leader"] ?? map["leaderId"] ?? "", // Ajustado para corresponder ao backend
      description: map["description"],
      bannerImageUrl: map["banner"], // Mapeando de 'banner' do backend
      flag: map["flag"], // Adicionado
      members: List<String>.from(map["members"] ?? []),
      subLeaders: List<String>.from(map["subLeaders"] ?? []), // Mapeando subLeaders
      allies: List<String>.from(map["allies"] ?? []),
      enemies: List<String>.from(map["enemies"] ?? []),
      textChannels: List<String>.from(map["textChannels"] ?? []),
      voiceChannels: List<String>.from(map["voiceChannels"] ?? []),
      memberRoles: map["memberRoles"] != null
          ? List<Map<String, dynamic>>.from(map["memberRoles"].map((x) => Map<String, dynamic>.from(x)))
          : null,
      customRoles: map["customRoles"] != null
          ? List<CustomRole>.from(map["customRoles"].map((x) => CustomRole.fromMap(x)))
          : null, // Adicionado
      rules: map["rules"],
      createdAt: map["createdAt"] != null
          ? DateTime.parse(map["createdAt"])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "_id": id,
      "name": name,
      "tag": tag,
      "leader": leaderId, // Ajustado para corresponder ao backend
      if (description != null) "description": description,
      if (bannerImageUrl != null) "banner": bannerImageUrl, // Mapeando para 'banner' do backend
      if (flag != null) "flag": flag, // Adicionado
      if (members != null) "members": members,
      if (subLeaders != null) "subLeaders": subLeaders, // Adicionado ao toMap
      if (allies != null) "allies": allies,
      if (enemies != null) "enemies": enemies,
      if (textChannels != null) "textChannels": textChannels,
      if (voiceChannels != null) "voiceChannels": voiceChannels,
      if (memberRoles != null) "memberRoles": memberRoles,
      if (customRoles != null) "customRoles": customRoles!.map((x) => x.toMap()).toList(), // Adicionado
      if (rules != null) "rules": rules,
      if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
    };
  }

  factory Clan.fromJson(String source) => Clan.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}


