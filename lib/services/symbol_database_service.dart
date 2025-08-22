import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/symbol.dart';
import '../utils/sample_data.dart';

class SymbolDatabaseService {
  static const String _symbolsKey = 'custom_symbols';
  static const String _categoriesKey = 'custom_categories';

  static final SymbolDatabaseService _instance = SymbolDatabaseService._internal();
  factory SymbolDatabaseService() => _instance;
  SymbolDatabaseService._internal();

  List<Symbol> _symbols = [];
  List<Category> _categories = [];

  List<Symbol> get symbols => List.unmodifiable(_symbols);
  List<Category> get categories => List.unmodifiable(_categories);

  Future<void> initialize() async {
    await _loadSymbols();
    await _loadCategories();
    
    // If no data exists, load sample data
    if (_symbols.isEmpty) {
      _symbols = SampleData.getSampleSymbols();
      await _saveSymbols();
    }
    
    if (_categories.isEmpty) {
      _categories = SampleData.getSampleCategories();
      await _saveCategories();
    }
  }

  Future<void> addSymbol(Symbol symbol) async {
    // Generate unique ID if not provided
    final newSymbol = Symbol(
      id: symbol.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: symbol.label,
      imagePath: symbol.imagePath,
      category: symbol.category,
      description: symbol.description,
      speechText: symbol.speechText,
      colorCode: symbol.colorCode,
    );
    
    _symbols.add(newSymbol);
    await _saveSymbols();
  }

  Future<void> updateSymbol(Symbol updatedSymbol) async {
    final index = _symbols.indexWhere((s) => s.id == updatedSymbol.id);
    if (index != -1) {
      _symbols[index] = updatedSymbol;
      await _saveSymbols();
    } else {
      // If symbol doesn't exist, add it
      await addSymbol(updatedSymbol);
    }
  }

  Future<void> deleteSymbol(String symbolId) async {
    _symbols.removeWhere((s) => s.id == symbolId);
    await _saveSymbols();
  }

  Future<void> addCategory(Category category) async {
    _categories.add(category);
    await _saveCategories();
  }

  Future<void> updateCategory(Category updatedCategory) async {
    final index = _categories.indexWhere((c) => c.name == updatedCategory.name);
    if (index != -1) {
      _categories[index] = updatedCategory;
      await _saveCategories();
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    _categories.removeWhere((c) => c.name == categoryName);
    // Also remove symbols in this category or move to 'Custom'
    for (int i = 0; i < _symbols.length; i++) {
      if (_symbols[i].category == categoryName) {
        _symbols[i] = Symbol(
          id: _symbols[i].id,
          label: _symbols[i].label,
          imagePath: _symbols[i].imagePath,
          category: 'Custom',
          description: _symbols[i].description,
          speechText: _symbols[i].speechText,
          colorCode: _symbols[i].colorCode,
        );
      }
    }
    await _saveCategories();
    await _saveSymbols();
  }

  List<Symbol> getSymbolsByCategory(String categoryName) {
    return _symbols.where((s) => s.category == categoryName).toList();
  }

  Future<void> importSymbols(List<Symbol> symbols) async {
    for (final symbol in symbols) {
      await addSymbol(symbol);
    }
  }

  Future<void> exportSymbols() async {
    // This could be extended to export to file
    final symbolsJson = jsonEncode(_symbols.map((s) => s.toJson()).toList());
    final categoriesJson = jsonEncode(_categories.map((c) => c.toJson()).toList());
    
    print('Symbols Export: $symbolsJson');
    print('Categories Export: $categoriesJson');
  }

  Future<void> clearAllData() async {
    _symbols.clear();
    _categories.clear();
    await _saveSymbols();
    await _saveCategories();
  }

  Future<void> resetToDefaults() async {
    _symbols = SampleData.getSampleSymbols();
    _categories = SampleData.getSampleCategories();
    await _saveSymbols();
    await _saveCategories();
  }

  Future<void> _loadSymbols() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final symbolsJson = prefs.getString(_symbolsKey);
      
      if (symbolsJson != null) {
        final List<dynamic> symbolsList = jsonDecode(symbolsJson);
        _symbols = symbolsList.map((json) => Symbol.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading symbols: $e');
      _symbols = [];
    }
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      
      if (categoriesJson != null) {
        final List<dynamic> categoriesList = jsonDecode(categoriesJson);
        _categories = categoriesList.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading categories: $e');
      _categories = [];
    }
  }

  Future<void> _saveSymbols() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final symbolsJson = jsonEncode(_symbols.map((s) => s.toJson()).toList());
      await prefs.setString(_symbolsKey, symbolsJson);
    } catch (e) {
      print('Error saving symbols: $e');
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await prefs.setString(_categoriesKey, categoriesJson);
    } catch (e) {
      print('Error saving categories: $e');
    }
  }
}