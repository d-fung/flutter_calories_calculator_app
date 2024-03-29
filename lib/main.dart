import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'meal_plan.dart';
import 'package:intl/intl.dart';

// List of foods and their calories
final Map<String, int> foodMap = {
  'Apple': 59,
  'Banana': 151,
  'Grapes': 100,
  'Orange': 53,
  'Asparagus': 27,
  'Broccoli': 45,
  'Carrots': 50,
  'Lettuce': 5,
  'Tomato': 22,
  'Beef': 142,
  'Chicken': 136,
  'Tofu': 86,
  'Egg': 78,
  'Bread': 75,
  'Corn': 132,
  'Rice': 206,
  'Potato': 130,
  'Fish': 78,
  'Eggplant': 35,
  'Pork': 137
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async main

  // Inserts food data into the food_calories table
  final dbHelper = DatabaseHelper();
  await dbHelper.insertFoodData(foodMap);


  // Runs the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calories Calculator App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Calories Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<MealPlan> mealPlans = [];
  DateTime? filterDate;
  TextEditingController dateController = TextEditingController();

  @override
  void initState(){
    super.initState();
    loadMealPlans();
  }

  // Calls the DatabaseHelper delete method to delete a meal plan
  void _deleteMealPlan(String date) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteMealPlan(date);

    // Reload the meal plans to reflect the deletion
    loadMealPlans();
  }
  // Calls the DatabaseHelper loadMealPlans method to load the meal plans from the database
  void loadMealPlans() async {
    final dbHelper = DatabaseHelper();
    var allPlans = await dbHelper.getAllMealPlans();

    // Filter the meal plans if there is a filter date set
    setState(() {
      if (filterDate != null) {
        mealPlans = allPlans.where((plan) {
          return DateFormat('yyyy-MM-dd').parse(plan.date) == filterDate;
        }).toList();
      } else {
        mealPlans = allPlans;
      }
    });
  }

  // Function creates a date picker for the filter and reloads meal plans
  Future<void> _pickFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: filterDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        filterDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        loadMealPlans();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: "Filter by Date",
                suffixIcon: filterDate != null
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      filterDate = null;
                      dateController.clear();
                      loadMealPlans();
                    });
                  },
                )
                    : Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _pickFilterDate(context),
            ),
          ),
          Expanded(
            child: mealPlans.isEmpty
                ? Center(child: Text("No meal plans found"))
                : ListView.builder(
              itemCount: mealPlans.length,
              itemBuilder: (context, index) {
                final plan = mealPlans[index];
                return Card(
                  child: ListTile(
                    title: Text("Date: ${plan.date}"),
                    subtitle: Text("Target Calories: ${plan.targetCalories}"),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _deleteMealPlan(plan.date),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMealPlanPage(mealPlan: mealPlans[index]),
                        ),
                      ).then((_) => loadMealPlans());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddMealPlanPage()),
        ).then((_) => loadMealPlans()),
        tooltip: 'Add Meal Plan',
        child: const Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}

// Add meal plan page
class AddMealPlanPage extends StatefulWidget {
  final MealPlan? mealPlan;
  const AddMealPlanPage({Key? key, this.mealPlan}) : super(key: key);

  @override
  _AddMealPlanPageState createState() => _AddMealPlanPageState();
}

class _AddMealPlanPageState extends State<AddMealPlanPage> {
  late DateTime selectedDate;
  late int? targetCalories;
  TextEditingController targetCaloriesController = TextEditingController(); // This sets the target calories input to the value passed in
  Map<String, int> selectedFoodCounts = {};

  @override
  void initState() {
    super.initState();

    // Need this to set calories as input passed in from homepage if editing an existing mealplan
    targetCaloriesController = TextEditingController(
        text: widget.mealPlan?.targetCalories?.toString() ?? '0'
    );
    foodMap.forEach((key, value) {
      selectedFoodCounts[key] = 0;
    });

    // Initializes the meal plan
    if (widget.mealPlan != null) {
      // Parse the date from the meal plan
      selectedDate = DateFormat('yyyy-MM-dd').parse(widget.mealPlan!.date);
      targetCalories = widget.mealPlan!.targetCalories;

      var foods = widget.mealPlan!.plan.split(', ');
      for (var food in foods) {
        var parts = food.split(':');
        if (parts.length == 2) {
          selectedFoodCounts[parts[0]] = int.parse(parts[1]);
        }
      }
    } else {
      selectedDate = DateTime.now();
      targetCalories = 0;
    }
  }

  // Select a date for the meal plan
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Adds total calories from selected food items
  int _calculateTotalCalories() {
    int total = 0;
    selectedFoodCounts.forEach((food, count) {
      int caloriesPerItem = foodMap[food] ?? 0;
      total += caloriesPerItem * count;
    });
    return total;
  }

  // Calls the DatabaseHelper method to save the meal plan
  Future<void> _saveMealPlan() async {
    if (selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }

    // Checks if user selected target calories
    if (targetCalories == null) {
      _showSnackBar('Target calories must be set.');
      return;
    }

    // show error message if calorie total exceeds set limit
    int totalCalories = _calculateTotalCalories();
    if (totalCalories > targetCalories!) {
      _showSnackBar('Selected food exceeds target calories.');
      return;
    }

    String foodCounts = selectedFoodCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => "${entry.key}:${entry.value}")
        .join(', ');

    final plan = MealPlan(
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      targetCalories: targetCalories!,
      plan: foodCounts,
    );

    final dbHelper = DatabaseHelper();
    await dbHelper.insertMealPlan(plan);
    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _changeFoodCount(String food, int change) {
    setState(() {
      selectedFoodCounts[food] = (selectedFoodCounts[food]! + change).clamp(0, 99);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Meal Plan')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text("Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: targetCaloriesController,
                decoration: InputDecoration(
                  labelText: "Target Calories",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  targetCalories = int.tryParse(value);
                },
              ),
            ),
            ...selectedFoodCounts.keys.map((food) {
              return ListTile(
                title: Text(food),
                subtitle: Text("${foodMap[food]} calories"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => _changeFoodCount(food, -1),
                    ),
                    Text('${selectedFoodCounts[food]}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _changeFoodCount(food, 1),
                    ),
                  ],
                ),
              );
            }).toList(),
            ElevatedButton(
              onPressed: _saveMealPlan,
              child: Text('Save Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

