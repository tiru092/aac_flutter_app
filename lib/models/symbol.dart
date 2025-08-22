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

  Symbol({
    required this.label,
    required this.imagePath,
    required this.category,
    DateTime? dateCreated,
    this.isDefault = false,
    this.description,
  }) : dateCreated = dateCreated ?? DateTime.now();

  // Copy constructor for editing
  Symbol copyWith({
    String? label,
    String? imagePath,
    String? category,
    DateTime? dateCreated,
    bool? isDefault,
    String? description,
  }) {
    return Symbol(
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      dateCreated: dateCreated ?? this.dateCreated,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Symbol(label: $label, category: $category, imagePath: $imagePath)';
  }
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
}