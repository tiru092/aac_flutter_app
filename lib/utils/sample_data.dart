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
      // Food & Drinks (with emoji fallbacks)
      Symbol(
        label: 'Apple',
        imagePath: 'assets/symbols/Apple.png', // Real image available
        category: 'Food & Drinks',
        description: 'Red apple fruit',
      ),
      Symbol(
        label: 'Water',
        imagePath: 'assets/symbols/Water.png', // Real image available
        category: 'Food & Drinks',
        description: 'Glass of water',
      ),
      Symbol(
        label: 'Milk',
        imagePath: 'emoji:🥛', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Glass of milk',
      ),
      Symbol(
        label: 'Bread',
        imagePath: 'emoji:🍞', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Slice of bread',
      ),
      Symbol(
        label: 'Banana',
        imagePath: 'emoji:🍌', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Yellow banana',
      ),
      Symbol(
        label: 'Cookie',
        imagePath: 'emoji:🍪', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Chocolate chip cookie',
      ),
      Symbol(
        label: 'Pizza',
        imagePath: 'emoji:🍕', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Slice of pizza',
      ),
      Symbol(
        label: 'Ice Cream',
        imagePath: 'emoji:🍦', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Ice cream cone',
      ),
      Symbol(
        label: 'Juice',
        imagePath: 'emoji:🧃', // Emoji fallback
        category: 'Food & Drinks',
        description: 'Juice box',
      ),

      // Vehicles (with emoji fallbacks)
      Symbol(
        label: 'Car',
        imagePath: 'assets/symbols/Car.png', // Real image available
        category: 'Vehicles',
        description: 'Red car',
      ),
      Symbol(
        label: 'Bus',
        imagePath: 'emoji:🚌', // Emoji fallback
        category: 'Vehicles',
        description: 'Yellow school bus',
      ),
      Symbol(
        label: 'Train',
        imagePath: 'emoji:🚂', // Emoji fallback
        category: 'Vehicles',
        description: 'Blue train',
      ),
      Symbol(
        label: 'Airplane',
        imagePath: 'emoji:✈️', // Emoji fallback
        category: 'Vehicles',
        description: 'White airplane',
      ),
      Symbol(
        label: 'Bike',
        imagePath: 'emoji:🚲', // Emoji fallback
        category: 'Vehicles',
        description: 'Red bicycle',
      ),
      Symbol(
        label: 'Truck',
        imagePath: 'emoji:🚚', // Emoji fallback
        category: 'Vehicles',
        description: 'Delivery truck',
      ),
      Symbol(
        label: 'Boat',
        imagePath: 'emoji:🚤', // Emoji fallback
        category: 'Vehicles',
        description: 'Speed boat',
      ),
      Symbol(
        label: 'Helicopter',
        imagePath: 'emoji:🚁', // Emoji fallback
        category: 'Vehicles',
        description: 'Helicopter',
      ),

      // Basic Needs (using existing images and emojis)
      Symbol(
        label: 'I need',
        imagePath: 'emoji:🙋', // Emoji fallback
        category: 'Basic Needs',
        description: 'I need something',
      ),
      Symbol(
        label: 'Help',
        imagePath: 'emoji:🆘', // Emoji fallback
        category: 'Basic Needs',
        description: 'I need help',
      ),
      Symbol(
        label: 'More',
        imagePath: 'emoji:➕', // Emoji fallback
        category: 'Basic Needs',
        description: 'I want more',
      ),
      Symbol(
        label: 'Stop',
        imagePath: 'emoji:🛑', // Emoji fallback
        category: 'Basic Needs',
        description: 'Stop please',
      ),
      Symbol(
        label: 'Thank You',
        imagePath: 'emoji:🙏', // Emoji fallback
        category: 'Basic Needs',
        description: 'Thank you',
      ),
      Symbol(
        label: 'Please',
        imagePath: 'emoji:🥺', // Emoji fallback
        category: 'Basic Needs',
        description: 'Please',
      ),

      // Actions (using emojis for kids to learn)
      Symbol(
        label: 'Eat',
        imagePath: 'emoji:🍽️', // Emoji fallback
        category: 'Actions',
        description: 'Eating food',
      ),
      Symbol(
        label: 'Drink',
        imagePath: 'emoji:🥤', // Emoji fallback
        category: 'Actions',
        description: 'Drinking',
      ),
      Symbol(
        label: 'Sleep',
        imagePath: 'emoji:😴', // Emoji fallback
        category: 'Actions',
        description: 'Sleeping',
      ),
      Symbol(
        label: 'Play',
        imagePath: 'emoji:🎮', // Emoji fallback
        category: 'Actions',
        description: 'Playing games',
      ),
      Symbol(
        label: 'Walk',
        imagePath: 'emoji:🚶', // Emoji fallback
        category: 'Actions',
        description: 'Walking',
      ),
      Symbol(
        label: 'Run',
        imagePath: 'emoji:🏃', // Emoji fallback
        category: 'Actions',
        description: 'Running',
      ),

      // Family (using emojis for kids)
      Symbol(
        label: 'Mom',
        imagePath: 'emoji:👩', // Emoji fallback
        category: 'Family',
        description: 'Mother',
      ),
      Symbol(
        label: 'Dad',
        imagePath: 'emoji:👨', // Emoji fallback
        category: 'Family',
        description: 'Father',
      ),
      Symbol(
        label: 'Baby',
        imagePath: 'emoji:👶', // Emoji fallback
        category: 'Family',
        description: 'Baby',
      ),
      Symbol(
        label: 'Grandma',
        imagePath: 'emoji:👵', // Emoji fallback
        category: 'Family',
        description: 'Grandmother',
      ),
      Symbol(
        label: 'Grandpa',
        imagePath: 'emoji:👴', // Emoji fallback
        category: 'Family',
        description: 'Grandfather',
      ),

      // Emotions (using emojis for kids to learn)
      Symbol(
        label: 'Happy',
        imagePath: 'emoji:😊', // Emoji fallback
        category: 'Emotions',
        description: 'Happy feeling',
      ),
      Symbol(
        label: 'Sad',
        imagePath: 'emoji:😢', // Emoji fallback
        category: 'Emotions',
        description: 'Sad feeling',
      ),
      Symbol(
        label: 'Angry',
        imagePath: 'emoji:😡', // Emoji fallback
        category: 'Emotions',
        description: 'Angry feeling',
      ),
      Symbol(
        label: 'Excited',
        imagePath: 'emoji:🤩', // Emoji fallback
        category: 'Emotions',
        description: 'Excited feeling',
      ),
      Symbol(
        label: 'Tired',
        imagePath: 'emoji:😴', // Emoji fallback
        category: 'Emotions',
        description: 'Tired feeling',
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