import '../models/user_model.dart';
import 'category_repository.dart';
import 'database_helper.dart';
import 'user_repository.dart';

class DatabaseInitializer {
  static Future<UserModel> initialize() async {
    await DatabaseHelper.instance.database;

    final userRepo = UserRepository();
    final user = await userRepo.getOrCreateDefaultUser();

    final catRepo = CategoryRepository();
    final categories = await catRepo.getCategories(user.id);
    if (categories.isEmpty) {
      await catRepo.insertDefaultCategories(user.id);
    }

    return user;
  }
}