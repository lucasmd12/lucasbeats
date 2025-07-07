/// Enum de papéis do usuário alinhado com o backend.
/// Inclui papéis usados no frontend que podem precisar de alinhamento com o backend.
enum Role {
  adm,         // Backend: "ADM"
  adminReivindicado, // Backend: "adminReivindicado"
  descolado,   // Backend: "descolado"
  leader,      // Backend: "Leader" (Corresponde a Leader de Clã/Federação no backend)
  subLeader,   // Backend: "SubLeader" (Corresponde a SubLeader de Clã/Federação no backend)
  member,      // Backend: "Member" (Corresponde a Member de Clã/Federação no backend)
  user,        // Backend: "User" (Papel padrão para usuários registrados sem função específica)
  federationAdmin, // Usado no frontend. No backend, admins de federação podem ser ADM ou ter um sistema de permissão diferente.
  clanLeader,      // Usado no frontend. No backend, o papel é "Leader".
  clanSubLeader,   // Usado no frontend. No backend, o papel é "SubLeader".
  clanMember,      // Usado no frontend. No backend, o papel é "Member".
  guest,           // Usado no frontend para usuários não autenticados ou com papel indefinido. Sem correspondência direta no backend.
}

extension RoleExtension on Role {
  String get displayName {
    switch (this) {
      case Role.adm: return 'Administrador Geral'; // Nome de exibição mais claro
      case Role.adminReivindicado: return 'Admin Reivindicado';
      case Role.descolado: return 'Descolado';
      case Role.leader: return 'Líder';
      case Role.subLeader: return 'Sub-Líder';
      case Role.member: return 'Membro';
      case Role.user: return 'Usuário';
      case Role.federationAdmin: return 'Admin Federação (Frontend)'; // Indica que é mais usado no frontend
      case Role.clanLeader: return 'Líder de Clã (Frontend)'; // Indica que é mais usado no frontend
      case Role.clanSubLeader: return 'Sub-Líder de Clã (Frontend)';// Indica que é mais usado no frontend
      case Role.clanMember: return 'Membro de Clã (Frontend)';    // Indica que é mais usado no frontend
      case Role.guest: return 'Convidado';
    }
  }
}

/// Converte string do backend para enum Role.
/// ATENÇÃO: Sempre alinhe os valores aqui com o backend!
/// Exemplo de uso: Role userRole = roleFromString(json["role"]);
Role roleFromString(String? roleString) {
  switch (roleString) {
    case 'ADM':
      return Role.adm;
    case 'adminReivindicado':
      return Role.adminReivindicado;
    case 'descolado':
      return Role.descolado;
    case 'Leader': // Mapeia string Leader do backend para enum Role.leader
      return Role.leader;
    case 'SubLeader': // Mapeia string SubLeader do backend para enum Role.subLeader
      return Role.subLeader;
    case 'Member': // Mapeia string Member do backend para enum Role.member
      return Role.member;
    case 'User': // Mapeia string User do backend para enum Role.user
      return Role.user;
    // Para strings do backend que podem corresponder a papéis apenas de frontend
    // ou que precisam de mapeamento especial, adicione casos aqui se necessário.
    // No entanto, o foco principal é mapear as strings que REALMENTE vêm da API
    // para os enums que usaremos na lógica.

    default:
      // Se a string não corresponde a nenhum papel conhecido do backend,
      // podemos tentar mapear alguns papéis de frontend que podem ter sido salvos,
      // ou retornar um valor padrão seguro.
       if (roleString == 'federationAdmin') return Role.federationAdmin;
       if (roleString == 'clanLeader') return Role.clanLeader;
       if (roleString == 'clanSubLeader') return Role.clanSubLeader;
       if (roleString == 'clanMember') return Role.clanMember;
       if (roleString == 'guest') return Role.guest;
       // Se ainda assim não encontrar, retorna o padrão
       return Role.user; // Valor padrão seguro
  }
}

/// Converte enum Role para string do backend.
/// Deve retornar os valores string exatos que o backend espera.
/// Exemplo de uso: String roleStr = roleToString(user.role);
String roleToString(Role role) {
  switch (role) {
    case Role.adm:
      return 'ADM';
    case Role.adminReivindicado:
      return 'adminReivindicado';
    case Role.descolado:
      return 'descolado';
    case Role.leader: // Mapeia enum Role.leader para string Leader do backend
      return 'Leader';
    case Role.subLeader: // Mapeia enum Role.subLeader para string SubLeader do backend
      return 'SubLeader';
    case Role.member: // Mapeia enum Role.member para string Member do backend
      return 'Member';
    case Role.user: // Mapeia enum Role.user para string User do backend
      return 'User';
    // Para papéis de frontend que não têm correspondência direta no backend
    // no campo 'role', pode ser necessário tratá-los de forma diferente
    // ou não incluí-los aqui se esta função for APENHAS para enviar para
    // o campo 'role' global do usuário.
    // Se for para clanRole ou federationRole, os valores string Leader, SubLeader, Member já estão cobertos.
    case Role.federationAdmin:
      // Este papel de frontend pode não ter uma string correspondente para o backend 'role'.
      // Se for para enviar como clanRole/federationRole, use 'Leader' ou 'ADM' dependendo da API.
       return 'ADM'; // Exemplo: Mapeia Admin Federação para ADM global se for o campo 'role'
    case Role.clanLeader:
       return 'Leader'; // Mapeia papel de frontend para string de backend clanRole/federationRole
    case Role.clanSubLeader:
       return 'SubLeader'; // Mapeia papel de frontend para string de backend clanRole/federationRole
    case Role.clanMember:
       return 'Member'; // Mapeia papel de frontend para string de backend clanRole/federationRole
    case Role.guest:
      // Papel de frontend, sem correspondência no backend. Pode mapear para User ou vazio dependendo do caso.
       return 'User'; // Exemplo: Mapeia Convidado para User no backend se for o campo 'role' global
  }
}

/// ANOTAÇÕES PARA O BACKEND:
/// - Sempre alinhe o enum e as funções helpers com o backend para evitar bugs de permissão e navegação.

/// EXEMPLO DE USO NO MODELO:
/// 