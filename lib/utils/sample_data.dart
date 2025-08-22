import '../models/symbol.dart';

class SampleData {
  static List<Category> getSampleCategories() {
    return [
      Category(
        name: 'Food & Drinks',
        iconPath: 'assets/icons/food.png',
        colorCode: 0xFFFF6B6B, // Red
      ),
      Category(
        name: 'Vehicles',
        iconPath: 'assets/icons/vehicles.png',
        colorCode: 0xFF4ECDC4, // Teal
      ),
      Category(
        name: 'Emotions',
        iconPath: 'assets/icons/emotions.png',
        colorCode: 0xFFFFE66D, // Yellow
      ),
      Category(
        name: 'Actions',
        iconPath: 'assets/icons/actions.png',
        colorCode: 0xFF6C63FF, // Purple
      ),
      Category(
        name: 'Family',
        iconPath: 'assets/icons/family.png',
        colorCode: 0xFFFF9F43, // Orange
      ),
      Category(
        name: 'Basic Needs',
        iconPath: 'assets/icons/needs.png',
        colorCode: 0xFF51CF66, // Green
      ),
    ];
  }

  static List<Symbol> getSampleSymbols() {
    return [
      // Food & Drinks
      Symbol(
        label: 'Apple',
        imagePath: 'assets/symbols/Apple.png',
        category: 'Food & Drinks',
        description: 'Red apple fruit',
      ),
      Symbol(
        label: 'Water',
        imagePath: 'assets/symbols/Water.png',
        category: 'Food & Drinks',
        description: 'Glass of water',
      ),
      Symbol(
        label: 'Milk',
        imagePath: 'assets/symbols/milk.png',
        category: 'Food & Drinks',
        description: 'Glass of milk',
      ),
      Symbol(
        label: 'Bread',
        imagePath: 'assets/symbols/bread.png',
        category: 'Food & Drinks',
        description: 'Slice of bread',
      ),
      Symbol(
        label: 'Banana',
        imagePath: 'assets/symbols/banana.png',
        category: 'Food & Drinks',
        description: 'Yellow banana',
      ),
      Symbol(
        label: 'Cookie',
        imagePath: 'assets/symbols/cookie.png',
        category: 'Food & Drinks',
        description: 'Chocolate chip cookie',
      ),

      // Vehicles
      Symbol(
        label: 'Car',
        imagePath: 'assets/symbols/Car.png',
        category: 'Vehicles',
        description: 'Red car',
      ),
      Symbol(
        label: 'Bus',
        imagePath: 'assets/symbols/bus.png',
        category: 'Vehicles',
        description: 'Yellow school bus',
      ),
      Symbol(
        label: 'Train',
        imagePath: 'assets/symbols/train.png',
        category: 'Vehicles',
        description: 'Blue train',
      ),
      Symbol(
        label: 'Airplane',
        imagePath: 'assets/symbols/airplane.png',
        category: 'Vehicles',
        description: 'White airplane',
      ),
      Symbol(
        label: 'Bike',
        imagePath: 'assets/symbols/bike.png',
        category: 'Vehicles',
        description: 'Red bicycle',
      ),

      // Emotions
      Symbol(
        label: 'Happy',
        imagePath: 'assets/symbols/happy.png',
        category: 'Emotions',
        description: 'Happy face',
      ),
      Symbol(
        label: 'Sad',
        imagePath: 'assets/symbols/sad.png',
        category: 'Emotions',
        description: 'Sad face',
      ),
      Symbol(
        label: 'Angry',
        imagePath: 'assets/symbols/angry.png',
        category: 'Emotions',
        description: 'Angry face',
      ),
      Symbol(
        label: 'Excited',
        imagePath: 'assets/symbols/excited.png',
        category: 'Emotions',
        description: 'Excited face',
      ),
      Symbol(
        label: 'Sleepy',
        imagePath: 'assets/symbols/sleepy.png',
        category: 'Emotions',
        description: 'Sleepy face',
      ),

      // Actions
      Symbol(
        label: 'Eat',
        imagePath: 'assets/symbols/eat.png',
        category: 'Actions',
        description: 'Eating',
      ),
      Symbol(
        label: 'Drink',
        imagePath: 'assets/symbols/drink.png',
        category: 'Actions',
        description: 'Drinking',
      ),
      Symbol(
        label: 'Play',
        imagePath: 'assets/symbols/play.png',
        category: 'Actions',
        description: 'Playing',
      ),
      Symbol(
        label: 'Sleep',
        imagePath: 'assets/symbols/sleep.png',
        category: 'Actions',
        description: 'Sleeping',
      ),
      Symbol(
        label: 'Walk',
        imagePath: 'assets/symbols/walk.png',
        category: 'Actions',
        description: 'Walking',
      ),
      Symbol(
        label: 'Run',
        imagePath: 'assets/symbols/run.png',
        category: 'Actions',
        description: 'Running',
      ),

      // Family
      Symbol(
        label: 'Mom',
        imagePath: 'assets/symbols/mom.png',
        category: 'Family',
        description: 'Mother',
      ),
      Symbol(
        label: 'Dad',
        imagePath: 'assets/symbols/dad.png',
        category: 'Family',
        description: 'Father',
      ),
      Symbol(
        label: 'Brother',
        imagePath: 'assets/symbols/brother.png',
        category: 'Family',
        description: 'Brother',
      ),
      Symbol(
        label: 'Sister',
        imagePath: 'assets/symbols/sister.png',
        category: 'Family',
        description: 'Sister',
      ),
      Symbol(
        label: 'Baby',
        imagePath: 'assets/symbols/baby.png',
        category: 'Family',
        description: 'Baby',
      ),

      // Basic Needs
      Symbol(
        label: 'Toilet',
        imagePath: 'assets/symbols/toilet.png',
        category: 'Basic Needs',
        description: 'Bathroom',
      ),
      Symbol(
        label: 'Help',
        imagePath: 'assets/symbols/help.png',
        category: 'Basic Needs',
        description: 'Need help',
      ),
      Symbol(
        label: 'More',
        imagePath: 'assets/symbols/more.png',
        category: 'Basic Needs',
        description: 'Want more',
      ),
      Symbol(
        label: 'Stop',
        imagePath: 'assets/symbols/stop.png',
        category: 'Basic Needs',
        description: 'Stop',
      ),
      Symbol(
        label: 'Please',
        imagePath: 'assets/symbols/please.png',
        category: 'Basic Needs',
        description: 'Please',
      ),
      Symbol(
        label: 'Thank You',
        imagePath: 'assets/symbols/thankyou.png',
        category: 'Basic Needs',
        description: 'Thank you',
      ),
    ];
  }

  static Map<String, String> getCategoryEmojis() {
    return {
      'Food & Drinks': '🍎',
      'Vehicles': '🚗',
      'Emotions': '😊',
      'Actions': '🏃',
      'Family': '👨‍👩‍👧‍👦',
      'Basic Needs': '🙏',
    };
  }
}