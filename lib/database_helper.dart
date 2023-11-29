import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'calories_counter.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE food_calories(food TEXT PRIMARY KEY, calories INTEGER);',
        );
        await db.execute(
          'CREATE TABLE meal_plan(id INTEGER PRIMARY KEY AUTOINCREMENT, meal_plan TEXT);',
        );
      },
      version: 1,
    );
  }

  Future<void> insertCaloriesData(Map<String, String> foodData) async {
    final db = await getDatabase();
    for (var food in foodData.entries) {
      try {
        await db.insert(
          'food_calories',
          {'food': food.key, 'calories': food.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        // Handle the exception (e.g., log it or display an error message)
      }
    }
  }
}
