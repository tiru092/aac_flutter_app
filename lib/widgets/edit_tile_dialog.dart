import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
import '../utils/aac_logger.dart';
import '../services/user_profile_service.dart';
import 'dart:io';

class EditTileDialog extends StatefulWidget {
  final Symbol? symbol;
  final Function(Symbol) onSave;
  final VoidCallback? onDelete;

  const EditTileDialog({
    super.key,
    this.symbol,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditTileDialog> createState() => _EditTileDialogState();
}

class _EditTileDialogState extends State<EditTileDialog>
    with TickerProviderStateMixin {
  late TextEditingController _labelController;
  late TextEditingController _speechController;
  late TextEditingController _descriptionController;
  
  String _selectedCategory = 'Food & Drinks';
  Color _selectedColor = const Color(0xFF6C63FF);
  String? _selectedImagePath;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  final List<String> _categories = [
    'Food & Drinks',
    'Vehicles',
    'Emotions',
    'Actions',
    'Family',
    'Basic Needs',
    'Custom',
  ];
  
  final List<Color> _availableColors = [
    const Color(0xFF6C63FF), // Purple
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFFFFE66D), // Yellow
    const Color(0xFFFF6B6B), // Red
    const Color(0xFFFF9F43), // Orange
    const Color(0xFF51CF66), // Green
    const Color(0xFF74C0FC), // Blue
    const Color(0xFFFF8CC8), // Pink
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing symbol data
    _labelController = TextEditingController(text: widget.symbol?.label ?? '');
    _speechController = TextEditingController(text: widget.symbol?.label ?? '');
    _descriptionController = TextEditingController(text: widget.symbol?.description ?? '');
    
    // Add listeners to rebuild UI when text changes
    _labelController.addListener(() => setState(() {}));
    _speechController.addListener(() => setState(() {}));
    
    if (widget.symbol != null) {
      _selectedCategory = widget.symbol!.category;
      _selectedImagePath = widget.symbol!.imagePath;
      // Try to match color from category
      _selectedColor = _getColorForCategory(widget.symbol!.category);
    }
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _slideController.forward();
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food & drinks':
        return const Color(0xFFFF6B6B);
      case 'vehicles':
        return const Color(0xFF4ECDC4);
      case 'emotions':
        return const Color(0xFFFFE66D);
      case 'actions':
        return const Color(0xFF6C63FF);
      case 'family':
        return const Color(0xFFFF9F43);
      case 'basic needs':
        return const Color(0xFF51CF66);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    _buildTextFields(),
                    const SizedBox(height: 24),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    _buildColorSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.symbol == null ? CupertinoIcons.add_circled_solid : CupertinoIcons.pencil,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            widget.symbol == null ? '➕ Add New Symbol' : '✏️ Edit Symbol',
            style: TextStyle(
              fontSize: 20 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📷 Symbol Image',
          style: TextStyle(
            fontSize: 18 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _selectedImagePath != null
                ? _buildImagePreview()
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _selectedImagePath!.startsWith('assets/')
          ? Image.asset(
              _selectedImagePath!,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(_selectedImagePath!),
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.camera_fill,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add image',
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Camera • Gallery',
          style: TextStyle(
            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Symbol Details',
          style: TextStyle(
            fontSize: 18 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _labelController,
          label: 'Symbol Label',
          hint: 'What appears on the button',
          icon: CupertinoIcons.textformat,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _speechController,
          label: 'Speech Text',
          hint: 'What the device will say',
          icon: CupertinoIcons.speaker_2_fill,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description (Optional)',
          hint: 'Brief description of the symbol',
          icon: CupertinoIcons.doc_text,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: hint,
            maxLines: maxLines,
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.all(16),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                icon,
                color: _selectedColor,
                size: 20,
              ),
            ),
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📂 Category',
          style: TextStyle(
            fontSize: 18 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = category == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _selectedColor = _getColorForCategory(category);
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _selectedColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _selectedColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎨 Symbol Color',
          style: TextStyle(
            fontSize: 18 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableColors.map((color) {
            final isSelected = color == _selectedColor;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        CupertinoIcons.checkmark,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canSave = _canSave();
    final hasLabel = _labelController.text.trim().isNotEmpty;
    final hasSpeech = _speechController.text.trim().isNotEmpty;
    final hasImage = _selectedImagePath != null;
    
    // Build error message for what's missing
    List<String> missing = [];
    if (!hasLabel) missing.add('Label');
    if (!hasSpeech) missing.add('Speech text');
    if (!hasImage) missing.add('Image');
    
    return Column(
      children: [
        // Show error message when save is disabled
        if (!canSave && missing.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Required: ${missing.join(', ')}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Save button
        Container(
          width: double.infinity,
          height: 56,
          child: CupertinoButton(
            color: canSave ? _selectedColor : Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            onPressed: canSave ? _handleSave : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: canSave ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.symbol == null ? 'Add Symbol' : 'Save Changes',
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: canSave ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.symbol != null && widget.onDelete != null) ...[
          const SizedBox(height: 16),
          // Delete button
          Container(
            width: double.infinity,
            height: 56,
            child: CupertinoButton(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(20),
              onPressed: _handleDelete,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.trash_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Symbol',
                    style: TextStyle(
                      fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _canSave() {
    final hasLabel = _labelController.text.trim().isNotEmpty;
    final hasSpeech = _speechController.text.trim().isNotEmpty;
    final hasImage = _selectedImagePath != null;
    
    // Debug: Log what's missing
    if (!hasLabel) AACLogger.debug('Label is empty', tag: 'EditDialog');
    if (!hasSpeech) AACLogger.debug('Speech text is empty', tag: 'EditDialog');
    if (!hasImage) AACLogger.debug('No image selected', tag: 'EditDialog');
    
    return hasLabel && hasSpeech && hasImage;
  }

  void _handleSave() async {
    AACLogger.debug('_handleSave called', tag: 'EditDialog');
    
    if (!_canSave()) {
      AACLogger.debug('_canSave() returned false, save aborted', tag: 'EditDialog');
      return;
    }

    AACLogger.debug('Creating symbol with ID: ${widget.symbol?.id}', tag: 'EditDialog');
    AACLogger.debug('Label: ${_labelController.text.trim()}', tag: 'EditDialog');
    AACLogger.debug('Speech: ${_speechController.text.trim()}', tag: 'EditDialog');
    AACLogger.debug('Image Path: $_selectedImagePath', tag: 'EditDialog');

    // Create updated symbol with same ID if editing existing symbol
    final symbolId = widget.symbol?.id ?? 'symbol_${DateTime.now().millisecondsSinceEpoch}';
    
    final symbol = Symbol(
      id: symbolId,
      label: _labelController.text.trim(),
      imagePath: _selectedImagePath!,
      category: _selectedCategory,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      isDefault: widget.symbol?.isDefault ?? false,
      dateCreated: widget.symbol?.dateCreated ?? DateTime.now(),
    );

    await AACHelper.accessibleHapticFeedback();
    
    AACLogger.debug('About to call UserProfileService methods', tag: 'EditDialog');
    
    // If editing existing symbol, update it in the profile
    if (widget.symbol != null) {
      AACLogger.debug('Updating existing symbol in profile', tag: 'EditDialog');
      await UserProfileService.updateSymbolInActiveProfile(widget.symbol!, symbol);
    } else {
      AACLogger.debug('Adding new symbol to profile', tag: 'EditDialog');
      // If creating new symbol, add it to the profile
      await UserProfileService.addSymbolToActiveProfile(symbol);
    }
    
    AACLogger.debug('Calling widget.onSave callback', tag: 'EditDialog');
    widget.onSave(symbol);
    
    AACLogger.debug('Popping dialog', tag: 'EditDialog');
    Navigator.pop(context);
  }

  void _handleDelete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Symbol?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.symbol != null) {
      await AACHelper.accessibleHapticFeedback();
      await UserProfileService.deleteSymbolFromActiveProfile(widget.symbol!);
      widget.onDelete?.call();
      Navigator.pop(context);
    }
  }

  void _showImagePickerOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera_fill),
                SizedBox(width: 8),
                Text('Take Photo'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_fill),
                SizedBox(width: 8),
                Text('Choose from Gallery'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      AACLogger.error('Error picking image: $e', tag: 'EditDialog');
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _speechController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}