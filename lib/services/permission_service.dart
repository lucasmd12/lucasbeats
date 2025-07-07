import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class PermissionService {
  // Verificar se o usuário pode criar salas de voz
  static bool canCreateVoiceRoom(User user, String roomType) {
    switch (roomType) {
      case 'clan':
        // Líder de clã ou ADM global pode criar sala de clã
        return user.clanRole == Role.leader || user.role == Role.adm;
      case 'federation':
        // Líder de federação ou ADM global pode criar sala de federação
        return user.federationRole == Role.leader || user.role == Role.adm;
      case 'global':
        // Qualquer usuário pode criar salas globais
        return true;
      case 'admin':
        // Apenas ADM global pode criar salas de admin
        return user.role == Role.adm;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode entrar em salas de voz
  static bool canJoinVoiceRoom(User user, String roomType, {String? clanId, String? federationId}) {
    switch (roomType) {
      case 'clan':
        // Deve estar no mesmo clã OU ser ADM global
        return (user.clanId != null && user.clanId == clanId) || user.role == Role.adm;
      case 'federation':
        // Deve estar na mesma federação OU ser ADM global
        return (user.federationId != null && user.federationId == federationId) || user.role == Role.adm;
      case 'global':
        // Qualquer usuário pode entrar
        return true;
      case 'admin':
        // Apenas ADM global pode entrar
        return user.role == Role.adm;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode enviar mensagens em um chat
  static bool canSendMessage(User user, String chatType, {String? clanId, String? federationId}) {
    switch (chatType) {
      case 'clan':
        // Deve estar no mesmo clã OU ser ADM global
        return (user.clanId != null && user.clanId == clanId) || user.role == Role.adm;
      case 'federation':
        // Deve estar na mesma federação OU ser ADM global
        return (user.federationId != null && user.federationId == federationId) || user.role == Role.adm;
      case 'global':
        // Qualquer usuário pode enviar mensagens globais
        return true;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode gerenciar um clã
  static bool canManageClan(User user, String? clanId) {
    // ADM global pode gerenciar qualquer clã
    if (user.role == Role.adm) return true;
    // Líder do clã pode gerenciar seu próprio clã
    if (user.clanRole == Role.leader && user.clanId == clanId) return true;
    return false;
  }

  // Verificar se o usuário pode gerenciar uma federação
  static bool canManageFederation(User user, String? federationId) {
    // Apenas ADM global pode gerenciar federações (assumindo que Admin Federação frontend mapeia para ADM backend)
    if (user.role == Role.adm) return true;
     // Lider de federação pode gerenciar sua propria federação
    if (user.federationRole == Role.leader && user.federationId == federationId) return true;
    return false;
  }

  // Verificar se o usuário pode promover outros usuários (papel global)
  // Este método pode precisar ser renomeado ou ajustado dependendo se é promoção global, de clã ou federação.
  // Assumindo promoção GLOBAL:
  static bool canPromoteUserGlobal(User promoter, User target, Role newRole) {
    // Apenas ADM global pode promover globalmente
    if (promoter.role != Role.adm) return false;

    // Não pode promover a si mesmo
    if (promoter.id == target.id) return false;

    // Não pode promover para ADM a menos que o promotor também seja ADM
    if (newRole == Role.adm && promoter.role != Role.adm) return false;

     // Não pode promover para Admin Reivindicado ou Descolado a menos que o promotor seja ADM
    if ((newRole == Role.adminReivindicado || newRole == Role.descolado) && promoter.role != Role.adm) return false;

    return true;
  }

   // Verificar se o usuário pode remover outros usuários (global)
  static bool canRemoveUserGlobal(User remover, User target) {
    // Apenas ADM global pode remover globalmente
    if (remover.role != Role.adm) return false;

    // Não pode remover a si mesmo
    if (remover.id == target.id) return false;

    // ADM não pode remover outro ADM (regra comum, ajustar se necessário)
    if (target.role == Role.adm && remover.id != target.id) return false;


    return true;
  }


  // Verificar se o usuário pode acessar o painel administrativo
  static bool canAccessAdminPanel(User user) {
    return user.role == Role.adm;
  }

  // Verificar se o usuário pode criar clãs
  static bool canCreateClan(User user) {
    // ADM global ou Líder (global?) pode criar clãs? Ajustar se for Líder de Federação, etc.
    // Assumindo que ADM global ou Líder (global) podem criar clãs
    return user.role == Role.adm || user.role == Role.leader; // Verifique esta lógica com suas regras
  }

  // Verificar se o usuário pode criar federações
  static bool canCreateFederation(User user) {
    // Apenas ADM global pode criar federações
    return user.role == Role.adm;
  }

  // Verificar se o usuário pode convidar outros para o clã
  static bool canInviteToClan(User user, String? clanId) {
    // ADM global ou Líder de Clã (no clã correto) pode convidar
    if (user.role == Role.adm) return true;
    if (user.clanRole == Role.leader && user.clanId == clanId) return true;
    return false;
  }

  // Verificar se o usuário pode expulsar membros do clã
  static bool canKickFromClan(User kicker, User target, String? clanId) {
    // ADM global pode expulsar qualquer one
    if (kicker.role == Role.adm) return true;
    // Líder de Clã (no clã correto) pode expulsar membros do seu clã
    if (kicker.clanRole == Role.leader && kicker.clanId == clanId && target.clanId == clanId) {
      // Líder não pode expulsar outro Líder do clã
      return target.clanRole != Role.leader;
    }
    return false;
  }

  // Verificar se o usuário pode ver estatísticas globais
  static bool canViewGlobalStats(User user) {
    return user.role == Role.adm;
  }

  // Verificar se o usuário pode moderar chats
  static bool canModerateChat(User user, String chatType, {String? clanId, String? federationId}) {
     // ADM global pode moderar qualquer chat
    if (user.role == Role.adm) return true;

    switch (chatType) {
      case 'clan':
        // Líder de Clã (no clã correto) pode moderar chat de clã
        return user.clanRole == Role.leader && user.clanId == clanId;
      case 'federation':
        // Líder de Federação (na federação correta) pode moderar chat de federação
        return user.federationRole == Role.leader && user.federationId == federationId;
      case 'global':
        // Apenas ADM global pode moderar chat global
        return user.role == Role.adm;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode encerrar salas de voz de outros
  static bool canEndOthersVoiceRoom(User user, String roomType, String creatorId, {String? clanId, String? federationId}) {
    // Admin pode encerrar qualquer sala
    if (user.role == Role.adm) return true;

    // Criador pode encerrar sua própria sala
    if (user.id == creatorId) return true;

    // Líder de Clã pode encerrar salas do seu clã
    if (roomType == 'clan' && user.clanRole == Role.leader && user.clanId == clanId) return true;

    // Líder de Federação pode encerrar salas da sua federação
     if (roomType == 'federation' && user.federationRole == Role.leader && user.federationId == federationId) return true;


    return false; // Caso contrário, não pode encerrar
  }


  // Obter lista de ações disponíveis para o usuário
  static List<String> getAvailableActions(User user) {
    List<String> actions = [];

    // Ações básicas para todos os usuários logados (Role.user ou superior)
    if(user.role != Role.guest) { // Assumindo que Role.guest é para não logados
       actions.addAll([
        'send_global_message',
        'join_global_voice_room',
        'create_global_voice_room', // Se qualquer usuário logado pode criar global
       ]);
    }


    // Ações para membros de clã (qualquer papel de clã ou ADM global)
    if (user.clanId != null || user.role == Role.adm) {
       actions.addAll([
        'send_clan_message',
        'join_clan_voice_room',
       ]);
    }

    // Ações para membros de federação (qualquer papel de federação ou ADM global)
    if (user.federationId != null || user.role == Role.adm) {
       actions.addAll([
        'send_federation_message',
       ]);
    }

    // Ações específicas para Líderes de Clã
    if (user.clanRole == Role.leader) {
      actions.addAll([
        'create_clan_voice_room',
        'manage_clan', // Gerenciar o próprio clã
        'invite_to_clan',
        'kick_from_clan',
        'moderate_clan_chat',
      ]);
    }

     // Ações específicas para Sub-Líderes de Clã
    if (user.clanRole == Role.subLeader) {
       actions.addAll([
         'manage_clan', // Sub-Líderes também podem gerenciar o clã? Ajustar lógica
         'kick_from_clan', // Sub-Líderes podem expulsar? Ajustar lógica
         'moderate_clan_chat', // Sub-Líderes podem moderar chat? Ajustar lógica
       ]);
    }


    // Ações específicas para Líderes de Federação
    if (user.federationRole == Role.leader) {
       actions.addAll([
         'manage_federation', // Gerenciar a própria federação
         'invite_to_federation', // Se houver convites para federação
         'kick_from_federation', // Se houver expulsão de federação
         'moderate_federation_chat', // Moderar chat de federação
         'add_clan_to_federation',
         'remove_clan_from_federation',
         'promote_to_subleader_federation', // Se puderem promover/rebaixar na federação
         'demote_subleader_federation',
         'transfer_leadership_federation',
         'add_ally',
         'add_enemy',
         'remove_ally',
         'remove_enemy',
         'update_federation_banner',
       ]);
    }

    // Ações específicas para Sub-Líderes de Federação
     if (user.federationRole == Role.subLeader) {
        actions.addAll([
          'manage_federation', // Sub-Líderes também podem gerenciar a federação?
          'moderate_federation_chat', // Sub-Líderes podem moderar chat?
        ]);
     }


    // Ações específicas para ADM Geral
    if (user.role == Role.adm) {
      actions.addAll([
        'access_admin_panel',
        'create_clan',
        'create_federation',
        'manage_any_clan', // ADM pode gerenciar qualquer clã
        'manage_any_federation', // ADM pode gerenciar qualquer federação
        'promote_user_global', // Promoção global
        'remove_user_global', // Remoção global
        'view_global_stats',
        'moderate_global_chat',
        'create_admin_voice_room',
        'join_admin_voice_room',
        'end_any_voice_room',
        // ADM pode realizar todas as ações de Líder/SubLíder de clã/federação?
        // Depende da sua lógica de negócio. Pode adicionar aqui ou confiar nas verificações acima.
      ]);
    }
      // Ações específicas para Admin Reivindicado
      if(user.role == Role.adminReivindicado) {
        actions.addAll([
          // Quais ações admins reivindicados podem fazer? Adicionar aqui
        ]);
      }

      // Ações específicas para Descolado
      if(user.role == Role.descolado) {
        actions.addAll([
          // Quais ações descolados podem fazer? Adicionar aqui
        ]);
      }


    Logger.info('Available actions for user ${user.username} (Global: ${user.role}, Clan: ${user.clanRole}, Federation: ${user.federationRole}): $actions');
    return actions;
  }

  // Verificar se o usuário tem uma ação específica
  static bool hasAction(User user, String action) {
    return getAvailableActions(user).contains(action);
  }
}
