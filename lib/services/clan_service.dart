import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/channel_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:flutter/material.dart'; // Import for ChangeNotifier


class ClanService with ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  List<Clan> _clans = [];
  bool _isLoading = false;

  List<Clan> get clans => _clans;
  bool get isLoading => _isLoading;

  ClanService(this._apiService, this._authService);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<List<Clan>> fetchClansByFederation(String federationId) async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/api/federations/$federationId/clans', requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is List) {
        _clans = (response['data'] as List).map((json) => Clan.fromMap(json)).toList();
        Logger.info('Fetched ${_clans.length} clans for federation $federationId.');
        return _clans;
      } else {
        Logger.warning('Unexpected response format when fetching clans for federation $federationId: $response');
        _clans = [];
        return [];
      }
    } catch (e, s) {
      Logger.error('Error fetching clans for federation $federationId', error: e, stackTrace: s);
      _clans = [];
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all clans
  Future<List<Clan>> getAllClans() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/api/clans', requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is List) {
        final clansData = (response['data'] as List);
        _clans = clansData.map((json) => Clan.fromMap(json)).toList();
        Logger.info('Fetched ${_clans.length} total clans.');
 return _clans;
      } else {
        Logger.warning('Unexpected response format when fetching all clans: $response');
 _clans = [];
 return [];
      }
    } catch (e, s) {
      Logger.error('Error fetching all clans', error: e, stackTrace: s);
 _clans = [];
 return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Clan?> getClanDetails(String clanId) async {
    try {
      final response = await _apiService.get('/api/clans/$clanId', requireAuth: true);
      if (response != null) {
        return Clan.fromMap(response);
      }
    } catch (e) {
      Logger.error('Error fetching clan details for $clanId: $e');
    }
    return null;
  }

  Future<List<Member>> getClanMembers(String clanId) async {
    try {
      final response = await _apiService.get('/api/clans/$clanId/members', requireAuth: true);
      if (response != null && response is Map<String, dynamic> && response.containsKey('members') && response['members'] is List) {
        final membersData = response['members'] as List;
        List<Member> members = [];
        for (var memberJson in membersData) {
          members.add(Member.fromJson(memberJson));
        }
        Logger.info('Fetched ${members.length} members for clan $clanId.');
        return members;
      } else {
        Logger.warning('Unexpected response format when fetching members for clan $clanId: $response');
      }
    } catch (e, s) {
      Logger.error('Error fetching members for clan $clanId', error: e, stackTrace: s);
    }
    return [];
  }

  Future<List<Channel>> getClanChannels(String clanId) async {
    try {
      final endpoint = '/api/voice-channels/clan/$clanId';
      final response = await _apiService.get(endpoint, requireAuth: true);
      if (response != null && response is Map<String, dynamic> && response.containsKey('clanVoiceChannels') && response['clanVoiceChannels'] is List) {
        final channels = (response['clanVoiceChannels'] as List).map((data) => Channel.fromMap(data)).toList();
        Logger.info('Fetched ${channels.length} voice channels for clan $clanId.');
        return channels;
      } else {
        Logger.warning('Unexpected response format when fetching voice channels for clan $clanId: $response');
      }
    } catch (e, s) {
      Logger.error('Error fetching voice channels for clan $clanId', error: e, stackTrace: s);
    }
    return [];
  }

  Future<bool> addMember(String clanId, String userIdToAdd) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null) return false;

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader || currentUser.role == Role.adm)) {
      Logger.warning('Permission Denied [Add Member]: Only Leader/SubLeader can add members.');
      return false;
    }

    try {
      final response = await _apiService.post('/api/clans/$clanId/members', {'userId': userIdToAdd}, requireAuth: true);
      return response != null;
    } catch (e) {
      Logger.error('Error adding member $userIdToAdd to clan $clanId: $e');
      return false;
    }
  }

  Future<bool> removeMember(String userIdToRemove) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(currentUser?.clanId ?? '');
    if (currentUser == null || clan == null) {
 Logger.warning("Permission Denied [Remove Member]: Current user or clan not found.");
      return false;
    }

    String? currentUserRoleInClan;
 if (clan.memberRoles != null) {
 for (var roleMap in clan.memberRoles!) {
 if (roleMap['user'] == currentUser.id) {
 currentUserRoleInClan = roleMap['role'];
 break;
 }
      }
    }

    final clanId = currentUser.clanId!;

    try {
      await _apiService.delete('/api/clans/$clanId/members/$userIdToRemove', requireAuth: true);
      return true;
    } catch (e) {
      Logger.error('Error removing member $userIdToRemove from clan $clanId: $e');
      rethrow;
    }
  }

  Future<bool> promoteMember(String userIdToPromote) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(currentUser?.clanId ?? '');
    if (currentUser == null || clan == null) {
 Logger.warning("Permission Denied [Promote Member]: Current user or clan not found.");
      return false;
    }

    String? currentUserRoleInClan;
 if (clan.memberRoles != null) {
 for (var roleMap in clan.memberRoles!) {
 if (roleMap['user'] == currentUser.id) {
 currentUserRoleInClan = roleMap['role'];
 break;
 }
      }
    }

    final clanId = currentUser.clanId!;

    try {
      final response = await _apiService.put('/api/clans/$clanId/members/$userIdToPromote/promote', {}, requireAuth: true);
      if (response != null && response['success'] == true) {
 return true;
      } else {
 Logger.error('Failed to promote member $userIdToPromote in clan $clanId. Response: $response');
 return false;
      }
    } catch (e) {
      Logger.error('Error promoting member $userIdToPromote in clan $clanId: $e');
      rethrow;
    }
  }

  Future<bool> demoteMember(String userIdToDemote) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(currentUser?.clanId ?? '');
    if (currentUser == null || clan == null) {
      Logger.warning("Permission Denied [Demote Member]: Current user or clan not found.");
      return false;
    }

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }
    final clanId = currentUser.clanId!; // Usando clanId

 bool isLeader = currentUser.id == clan.leaderId;
 bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

 if (!(isLeader || isSubLeader || currentUser.role == Role.adm)) {
 Logger.warning('Permission Denied [Demote Member]: Only Leader/SubLeader can demote members.');
 return false;
    }

 try {
      final response = await _apiService.put('/api/clans/$clanId/members/$userIdToDemote/demote', {}, requireAuth: true);
      return response != null;
    } catch (e) {
      Logger.error('Error demoting member $userIdToDemote in clan $clanId: $e');
      rethrow;
    }
  }

  /// Transfers leadership of the clan to a new user.
  Future<bool> transferLeadership(String clanId, String newLeaderId) async {
    Logger.info('Attempting to transfer leadership for clan $clanId to user $newLeaderId');
    try {
      final response = await _apiService.put('/api/clans/$clanId/transfer/$newLeaderId', {}, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Leadership of clan $clanId successfully transferred to $newLeaderId.');
        return true;
      } else {
        Logger.warning('Failed to transfer leadership for clan $clanId to $newLeaderId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error transferring leadership for clan $clanId to $newLeaderId', error: e, stackTrace: s);
      return false;
    }
  }
  Future<Clan?> getClanById(String clanId) async {
    return await getClanDetails(clanId);
  }

  Future<Clan?> updateClanDetails(String clanId, {String? name, String? bannerImageUrl, String? tag}) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null) return null;

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader || currentUser.role == Role.adm)) {
      Logger.warning('Permission Denied [Update Clan Details]: Only Leader/SubLeader can update details.');
      return null;
    }

    Map<String, dynamic> dataToUpdate = {};
    if (name != null) dataToUpdate['name'] = name;
    if (bannerImageUrl != null) dataToUpdate['bannerImageUrl'] = bannerImageUrl;
    if (tag != null) dataToUpdate['tag'] = tag;

    if (dataToUpdate.isEmpty) {
      Logger.info('No details provided to update for clan $clanId.');
      return clan;
    }

    try {
      final response = await _apiService.put('/api/clans/$clanId', dataToUpdate, requireAuth: true);
      if (response != null) {
        return Clan.fromMap(response);
      }
    } catch (e) {
      Logger.error('Error updating details for clan $clanId: $e');
    }
    return null;
  }

   Future<Clan?> createClan(Map<String, dynamic> clanData) async {
    Logger.info('Attempting to create clan with data: $clanData');
    try {
      final response = await _apiService.post('/api/clans', clanData, requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is Map<String, dynamic>) {
        Logger.info('Clan created successfully: ${response['data']['name']}');
        return Clan.fromMap(response['data']);
      } else {
         Logger.warning('Failed to create clan. Response: $response');
         Logger.error('Failed to create clan. Full response: $response');
         // Dependendo da estrutura da sua API, você pode querer lançar uma exceção
         // throw Exception('Failed to create clan');
         return null;
      }
    } catch (e, s) {
      Logger.error('Error creating clan:', error: e, stackTrace: s);
      // Dependendo da sua lógica de tratamento de erros, você pode querer relançar a exceção
      // rethrow;
      return null;
    }
  }

  Future<bool> deleteClan(String clanId) async {
    Logger.info('Attempting to delete clan with ID: $clanId');
    try {
      // Assuming your backend has a DELETE endpoint for clans at /api/clans/{clanId}
      final response = await _apiService.delete('/api/clans/$clanId', requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Clan with ID $clanId deleted successfully.');
        return true;
      } else {
        Logger.warning('Failed to delete clan with ID $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error deleting clan with ID $clanId:', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> addCustomRole(String clanId, String name, List<String> permissions) async {
    Logger.info('Attempting to add custom role "$name" to clan $clanId');
    try {
      final response = await _apiService.post('/api/clans/$clanId/roles', {'name': name, 'permissions': permissions}, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Custom role "$name" added successfully to clan $clanId.');
        // Consider fetching updated clan details or roles after successful operation
        return true;
      } else {
        Logger.warning('Failed to add custom role "$name" to clan $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error adding custom role "$name" to clan $clanId', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> updateCustomRole(String clanId, String roleName, List<String> permissions) async {
    Logger.info('Attempting to update custom role "$roleName" in clan $clanId');
    try {
      final response = await _apiService.put('/api/clans/$clanId/roles/$roleName', {'permissions': permissions}, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Custom role "$roleName" updated successfully in clan $clanId.');
        // Consider fetching updated clan details or roles after successful operation
        return true;
      } else {
        Logger.warning('Failed to update custom role "$roleName" in clan $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error updating custom role "$roleName" in clan $clanId', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> deleteCustomRole(String clanId, String roleName) async {
    Logger.info('Attempting to delete custom role "$roleName" from clan $clanId');
    try {
      final response = await _apiService.delete('/api/clans/$clanId/roles/$roleName', requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Custom role "$roleName" deleted successfully from clan $clanId.');
        // Consider fetching updated clan details or roles after successful operation
        return true;
      } else {
        Logger.warning('Failed to delete custom role "$roleName" from clan $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error deleting custom role "$roleName" from clan $clanId', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> assignMemberRole(String clanId, String userId, String roleName) async {
    Logger.info('Attempting to assign role "$roleName" to member $userId in clan $clanId');
    try {
      final response = await _apiService.put('/api/clans/$clanId/members/$userId/assign-role', {'roleName': roleName}, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Role "$roleName" assigned successfully to member $userId in clan $clanId.');
        // Consider fetching updated members list or clan details after successful operation
        return true;
      } else {
        Logger.warning('Failed to assign role "$roleName" to member $userId in clan $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error assigning role "$roleName" to member $userId in clan $clanId', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> removeMemberRole(String clanId, String userId, String roleName) async {
    Logger.info('Attempting to remove role "$roleName" from member $userId in clan $clanId');
    try {
      final response = await _apiService.put('/api/clans/$clanId/members/$userId/remove-role', {'roleName': roleName}, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Role "$roleName" removed successfully from member $userId in clan $clanId.');
        // Consider fetching updated members list or clan details after successful operation
        return true;
      } else {
        Logger.warning('Failed to remove role "$roleName" from member $userId in clan $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error removing role "$roleName" from member $userId in clan $clanId', error: e, stackTrace: s);
      return false;
    }
  }
}