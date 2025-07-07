import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart' show User;
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/screens/call_screen.dart';
import 'package:lucasbeatsfederacao/models/call_model.dart';

class MemberListItem extends StatelessWidget {
  final Member member;
  final User currentUser;
  final Function(Member, String) onMemberAction;
  final bool canManage;
  final String? clanLeaderId; // Added clanLeaderId

  const MemberListItem({
    super.key,
    required this.member,
    required this.currentUser,
    required this.onMemberAction,
    this.canManage = false,
    this.clanLeaderId, // Added clanLeaderId to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade800.withOpacity(0.8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(member.role),
              backgroundImage: member.avatarUrl.isNotEmpty 
                ? NetworkImage(member.avatarUrl)
                : null,
              child: member.avatarUrl.isEmpty
                ? Text(
                    member.username.isNotEmpty ? member.username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            ),
            if (member.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getRoleDisplayName(member.role),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          member.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: member.isOnline ? Colors.green : Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.isOnline && member.id != currentUser.id)
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                onPressed: () => _initiateCall(context),
                tooltip: 'Fazer chamada',
              ),
            
            if (canManage && member.id != currentUser.id)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (action) => onMemberAction(member, action),
                itemBuilder: (context) => _buildMenuItems(),
              ),
          ],
        ),
      ),
    );
  }

  void _initiateCall(BuildContext context) async {
    final voipService = Provider.of<VoIPService>(context, listen: false);
    
    if (voipService.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já está em uma chamada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Fazer Chamada',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja fazer uma chamada para ${member.username}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Chamar'),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      
 await voipService.initiateCall(targetId: member.id, displayName: member.username);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              call: Call(
                id: voipService.currentCall!.id,
                callerId: currentUser.id,
                receiverId: member.id,
                type: CallType.audio,
                status: CallStatus.pending,
                startTime: DateTime.now(),
              ),
              isIncoming: false,
            ),
          ),
        );
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];
    
    if (member.role == Role.clanMember) {
      items.add(const PopupMenuItem(
        value: 'promote',
        child: Row(
          children: [
            Icon(Icons.arrow_upward, color: Colors.green),
            SizedBox(width: 8),
            Text('Promover'),
          ],
        ),
      ));
    }
    
    if (member.role == Role.clanSubLeader) {
      items.add(const PopupMenuItem(
        value: 'demote',
        child: Row(
          children: [
            Icon(Icons.arrow_downward, color: Colors.orange),
            SizedBox(width: 8),
            Text('Rebaixar'),
          ],
        ),
      ));
    }
    
    // Add Transfer Leadership option if current user is the leader and not the member being listed
    if (currentUser.id == clanLeaderId && member.id != currentUser.id) {
      items.add(const PopupMenuItem(
        value: 'transferLeadership',
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.yellow),
            SizedBox(width: 8),
            Text('Transferir Liderança'),
          ],
        ),
      ));
    }
    items.add(const PopupMenuItem(
      value: 'remove',
      child: Row(
        children: [
          Icon(Icons.person_remove, color: Colors.red),
          SizedBox(width: 8),
          Text('Remover'),
        ],
      ),
    ));
    
    items.add(const PopupMenuItem(
      value: 'message',
      child: Row(
        children: [
          Icon(Icons.message, color: Colors.blue),
          SizedBox(width: 8),
          Text('Mensagem'),
        ],
      ),
    ));
    
    return items;
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.federationAdmin:
        return Colors.red;
      case Role.clanLeader:
        return Colors.orange;
      case Role.clanSubLeader:
        return Colors.yellow.shade600;
      case Role.clanMember:
        return Colors.blue;
      case Role.guest:
        return Colors.grey;
      case Role.adm:
        return Colors.purple;
      case Role.user:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(Role role) {
    switch (role) {
      case Role.federationAdmin:
        return 'ADM FEDERAÇÃO';
      case Role.clanLeader:
        return 'LÍDER CLÃ';
      case Role.clanSubLeader:
        return 'SUB-LÍDER CLÃ';
      case Role.clanMember:
        return 'MEMBRO CLÃ';
      case Role.guest:
        return 'CONVIDADO';
      case Role.adm:
        return 'ADMINISTRADOR';
      case Role.user:
        return 'USUÁRIO';
      default:
        return role.toString().split('.').last.toUpperCase();
    }
  }
}


