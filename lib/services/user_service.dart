import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

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
}


