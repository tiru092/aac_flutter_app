import 'package:hive/hive.dart';

part 'symbol.g.dart';

@HiveType(typeId: 0)
class Symbol extends HiveObject {
  @HiveField(0)
  String label;

  @HiveField(1)
  String imagePath;

  @HiveField(2)
  String category;

  @HiveField(3)
  DateTime dateCreated;

  @HiveField(4)
  bool isDefault;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? id;

  @HiveField(7)
  String? speechText;

  @HiveField(8)
  int? colorCode;

  Symbol({
    this.id,
    required this.label,
    required this.imagePath,
    required this.category,
    DateTime? dateCreated,
    this.isDefault = false,
    this.description,
    this.speechText,
    this.colorCode,
  }) : dateCreated = dateCreated ?? DateTime.now();

  // Copy constructor for editing
  Symbol copyWith({
    String? id,
    String? label,
    String? imagePath,
    String? category,
    DateTime? dateCreated,
    bool? isDefault,
    String? description,
    String? speechText,
    int? colorCode,
  }) {
    return Symbol(
      id: id ?? this.id,
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      dateCreated: dateCreated ?? this.dateCreated,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
      speechText: speechText ?? this.speechText,
      colorCode: colorCode ?? this.colorCode,
    );
  }

  @override
  String toString() {
    return 'Symbol(label: $label, category: $category, imagePath: $imagePath)';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'imagePath': imagePath,
    'category': category,
    'dateCreated': dateCreated.toIso8601String(),
    'isDefault': isDefault,
    'description': description,
    'speechText': speechText,
    'colorCode': colorCode,
  };

  factory Symbol.fromJson(Map<String, dynamic> json) => Symbol(
    id: json['id'],
    label: json['label'],
    imagePath: json['imagePath'],
    category: json['category'],
    dateCreated: DateTime.parse(json['dateCreated']),
    isDefault: json['isDefault'] ?? false,
    description: json['description'],
    speechText: json['speechText'],
    colorCode: json['colorCode'],
  );
}

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String iconPath;

  @HiveField(2)
  int colorCode;

  @HiveField(3)
  DateTime dateCreated;

  @HiveField(4)
  bool isDefault;

  Category({
    required this.name,
    required this.iconPath,
    required this.colorCode,
    DateTime? dateCreated,
    this.isDefault = false,
  }) : dateCreated = dateCreated ?? DateTime.now();

  Category copyWith({
    String? name,
    String? iconPath,
    int? colorCode,
    DateTime? dateCreated,
    bool? isDefault,
  }) {
    return Category(
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      colorCode: colorCode ?? this.colorCode,
      dateCreated: dateCreated ?? this.dateCreated,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'Category(name: $name, iconPath: $iconPath)';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'iconPath': iconPath,
    'colorCode': colorCode,
    'dateCreated': dateCreated.toIso8601String(),
    'isDefault': isDefault,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'],
    iconPath: json['iconPath'],
    colorCode: json['colorCode'],
    dateCreated: DateTime.parse(json['dateCreated']),
    isDefault: json['isDefault'] ?? false,
  );
}

class CustomVoice {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final bool isDefault;

  CustomVoice({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory CustomVoice.fromJson(Map<String, dynamic> json) {
    return CustomVoice(
      id: json['id'],
      name: json['name'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }
}
