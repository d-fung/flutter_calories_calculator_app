// This is the class for the meal plan

class MealPlan {
  final String date;
  final int targetCalories;
  final String plan;

  MealPlan({required this.date, required this.targetCalories, required this.plan});

  // Function parses the meal plan from the database
  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      date: map['date'],
      targetCalories: map['target_calories'],
      plan: map['meal_plan'],
    );
  }

  // Function creates a map to be used to insert data into database
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'target_calories': targetCalories,
      'meal_plan': plan,
    };
  }

}