import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Import Role and roleToString
import 'package:http/http.dart' as http; // Import for status code checking

class UserService {
  final ApiService _apiService = ApiService();

  Future<User?> getUserByUsername(String username) async {
    try {
      final response = await _apiService.get("/api/users/by-username?username=$username");
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']);
      } else {
        Logger.warning("Usuário com username $username não encontrado: ${response["msg"]}");
        return null;
      }
    } catch (e) {
      Logger.error("Erro ao buscar usuário por username", error: e);
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      // Assumindo que a API retorna uma lista de objetos de usuário diretamente
      final response = await _apiService.get('/api/users', requireAuth: true);

      if (response != null && response is List) {
        Logger.info('getAllUsers: Received ${response.length} users.');
        return response.map((json) => User.fromJson(json)).toList();
      } else if (response != null && response is Map && response.containsKey('data') && response['data'] is List) {
         // Se a resposta for { "data": [...] }
        final List<dynamic> userData = response['data'];
         Logger.info('getAllUsers: Received ${userData.length} users from data field.');
        return userData.map((json) => User.fromJson(json)).toList();
      }
       Logger.warning('getAllUsers: Unexpected response format: ${response.runtimeType}');
       return [];
    } catch (e) {
      Logger.error('Erro ao buscar todos os usuários', error: e);
      return [];
    }
  }

  Future<bool> updateUserRole(String userId, Role newRole, {String? clanId, String? federationId}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'role': roleToString(newRole),
      };
      if (clanId != null) requestBody['clanId'] = clanId;
      if (federationId != null) requestBody['federationId'] = federationId;

      final response = await _apiService.put(
        '/api/users/$userId/role',
 requestBody, requireAuth: true,
      );
      // API PUT requests might return 200 (OK) or 204 (No Content) on success
      return response != null && (response is http.Response && (response.statusCode == 200 || response.statusCode == 204));
    } catch (e) {
      Logger.error('Erro ao atualizar papel do usuário $userId', error: e);
      return false;
    }
  }
}


