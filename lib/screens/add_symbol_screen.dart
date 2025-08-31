import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
import '../utils/sample_data.dart';
import '../services/user_profile_service.dart';

class AddSymbolScreen extends StatefulWidget {
  const AddSymbolScreen({super.key});

  @override
  State<AddSymbolScreen> createState() => _AddSymbolScreenState();
}

class _AddSymbolScreenState extends State<AddSymbolScreen> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  String _selectedCategory = 'Food & Drinks';
  bool _isLoading = false;
  List<Category> _categories = [];
  List<Category> _customCategories = [];
  bool _isCreatingCustomCategory = false;

  @override
  void initState() {
    super.initState();
    _categories = SampleData.getSampleCategories();
    _loadCustomCategories();
  }

  void _loadCustomCategories() async {
    // Load user-specific categories from their profile
    final userCategories = await UserProfileService.getUserCategories();
    
    setState(() {
      _customCategories = userCategories;
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF4ECDC4),
        middle: const Text(
          '✨ Add New Symbol',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: _saveSymbol,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4ECDC4).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Selection Section
                _buildImageSelectionCard(),
                
                const SizedBox(height: 24),
                
                // Symbol Details Section
                _buildSymbolDetailsCard(),
                
                const SizedBox(height: 24),
                
                // Category Selection Section
                _buildCategorySelectionCard(),
                
                const SizedBox(height: 32),
                
                // Save Button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.photo,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Symbol Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Image Preview
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 48,
                      color: Color(0xFFA0AEC0),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image Source Options
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.camera, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF38A169),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.photo_fill, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.textformat,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Symbol Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Label Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Label',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _labelController,
                placeholder: 'Enter symbol name (e.g., Apple)',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _descriptionController,
                placeholder: 'Describe what this symbol means',
                maxLines: 3,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectionCard() {
    // Combine default and custom categories
    final allCategories = [..._categories, ..._customCategories];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.folder,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showCreateCategoryDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Default Categories Header
          if (_categories.isNotEmpty) ... [
            const Text(
              'Default Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            
            // Default Category Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category.name;
                final categoryColor = Color(category.colorCode);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.name;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? categoryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCategoryEmoji(category.name),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Custom Categories Section
          if (_customCategories.isNotEmpty) ... [
            const SizedBox(height: 20),
            const Text(
              'Your Custom Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            
            // Custom Category Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _customCategories.map((category) {
                final isSelected = _selectedCategory == category.name;
                final categoryColor = Color(category.colorCode);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.name;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? categoryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🎨', // Custom category emoji
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : categoryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteCustomCategory(category),
                          child: Icon(
                            CupertinoIcons.delete,
                            size: 16,
                            color: isSelected ? Colors.white70 : categoryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: const Color(0xFF4ECDC4),
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        onPressed: _isLoading ? null : _saveSymbol,
        child: _isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.checkmark_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Symbol',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveSymbol() async {
    if (_labelController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a label for the symbol');
      return;
    }
    
    if (_selectedImage == null) {
      _showErrorDialog('Please select an image for the symbol');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Copy the selected image to the app's directory
      final appDir = await getApplicationDocumentsDirectory();
      final imageFileName = 'symbol_${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImage!.path)}';
      final imageDestination = File('${appDir.path}/symbols/$imageFileName');
      
      // Create the symbols directory if it doesn't exist
      await Directory('${appDir.path}/symbols').create(recursive: true);
      
      // Copy the image to the app's directory
      final copiedImage = await _selectedImage!.copy(imageDestination.path);
      
      // Create new symbol with the copied image path
      final newSymbol = Symbol(
        id: 'symbol_${DateTime.now().millisecondsSinceEpoch}',
        label: _labelController.text.trim(),
        imagePath: copiedImage.path,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        isDefault: false,
        dateCreated: DateTime.now(),
      );

      // Save to user profile
      await UserProfileService.addSymbolToActiveProfile(newSymbol);
      
      await AACHelper.speak('New symbol ${newSymbol.label} added successfully to ${_selectedCategory} category');
      
      if (mounted) {
        Navigator.pop(context, newSymbol);
      }
    } catch (e) {
      _showErrorDialog('Failed to save symbol: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showCreateCategoryDialog() {
    _customCategoryController.clear();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create Custom Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Enter a name for your new category:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _customCategoryController,
              placeholder: 'e.g., School, Sports, Music',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text(
              'Create',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              final categoryName = _customCategoryController.text.trim();
              if (categoryName.isNotEmpty) {
                _createCustomCategory(categoryName);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _createCustomCategory(String name) {
    // Check if category already exists
    final allCategories = [..._categories, ..._customCategories];
    final exists = allCategories.any((cat) => cat.name.toLowerCase() == name.toLowerCase());
    
    if (exists) {
      _showErrorDialog('A category with this name already exists.');
      return;
    }

    // Generate a random color for the custom category
    final colors = [
      0xFF9F7AEA, // Purple
      0xFFED8936, // Orange
      0xFF38B2AC, // Teal
      0xFFE53E3E, // Red
      0xFF3182CE, // Blue
      0xFF38A169, // Green
      0xFFD69E2E, // Yellow
      0xFFAD4E99, // Pink
    ];
    final randomColor = colors[DateTime.now().millisecond % colors.length];

    final newCategory = Category(
      name: name,
      iconPath: 'custom', // Custom categories use emoji icon
      colorCode: randomColor,
    );

    setState(() {
      _customCategories.add(newCategory);
      _selectedCategory = name; // Auto-select the new category
    });

    // In a real app, save to database/storage
    _saveCustomCategories();

    // Show success message
    AACHelper.speak('Custom category $name created successfully');
  }

  void _deleteCustomCategory(Category category) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete the "${category.name}" category?\n\nThis action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _customCategories.remove(category);
                // If the deleted category was selected, select the first default category
                if (_selectedCategory == category.name) {
                  _selectedCategory = _categories.first.name;
                }
              });
              
              // Save the updated custom categories list
              _saveUpdatedCustomCategories();
              
              AACHelper.speak('Category ${category.name} deleted');
            },
          ),
        ],
      ),
    );
  }

  void _saveCustomCategories() async {
    // Only save the newly added category (the last one in the list)
    // This prevents duplication of existing categories
    if (_customCategories.isNotEmpty) {
      final newCategory = _customCategories.last;
      await UserProfileService.addCategoryToActiveProfile(newCategory);
      // Also save to local database for immediate access
      await AACHelper.addCategory(newCategory);
    }
  }
  
  void _saveUpdatedCustomCategories() async {
    // Save all custom categories (used when deleting categories)
    // First clear existing custom categories from profile
    final profile = await UserProfileService.getActiveProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(
        userCategories: [..._customCategories],
        lastActiveAt: DateTime.now(),
      );
      await UserProfileService.saveUserProfile(updatedProfile);
      
      // Also update local database
      await AACHelper.clearCustomCategories();
      for (final category in _customCategories) {
        await AACHelper.addCategory(category);
      }
    }
  }

  String _getCategoryEmoji(String categoryName) {
    switch (categoryName) {
      case 'Food & Drinks':
        return '🍎';
      case 'Vehicles':
        return '🚗';
      case 'Emotions':
        return '😊';
      case 'Actions':
        return '🏃';
      case 'Family':
        return '👨‍👩‍👧‍👦';
      case 'Basic Needs':
        return '🙏';
      default:
        return '📝';
    }
  }
}