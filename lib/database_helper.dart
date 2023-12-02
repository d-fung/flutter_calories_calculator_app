import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'meal_plan.dart';

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
          'CREATE TABLE meal_plan(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, target_calories INTEGER, meal_plan TEXT);',
        );
      },
      version: 1,
    );
  }

  // This method inserts the initial food data into the database
  Future<void> insertFoodData(Map<String, int> foodData) async {
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

  Future<List<MealPlan>> getAllMealPlans() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('meal_plan');

    return List.generate(maps.length, (i){
      return MealPlan.fromMap(maps[i]);
    });
  }

  Future<void> insertMealPlan(MealPlan plan) async {
    final db = await getDatabase();

    // Check if a meal plan with this date exists
    var existingPlan = await db.query(
      'meal_plan',
      where: 'date = ?',
      whereArgs: [plan.date],
    );

    if (existingPlan.isNotEmpty) {
      // Update the existing plan
      await db.update(
        'meal_plan',
        plan.toMap(),
        where: 'date = ?',
        whereArgs: [plan.date],
      );
    } else {
      // Insert new plan
      await db.insert(
        'meal_plan',
        plan.toMap(),
      );
    }
  }

  Future<void> deleteMealPlan(String date) async {
    final db = await getDatabase();
    await db.delete(
      'meal_plan',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

}
