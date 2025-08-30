import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../utils/aac_helper.dart';

class AddGoalScreen extends StatefulWidget {
  final Goal? goal;

  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  GoalCategory _selectedCategory = GoalCategory.communication;
  GoalFrequency _selectedFrequency = GoalFrequency.weekly;
  int _selectedPriority = 3; // Medium priority
  List<GoalCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeForm();
  }

  Future<void> _loadCategories() async {
    try {
      // Use all available goal categories
      setState(() {
        _categories = GoalCategory.values;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categories = GoalCategory.values;
      });
    }
  }

  void _initializeForm() {
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descriptionController.text = widget.goal!.description;
      _selectedDate = widget.goal!.targetDate;
      _selectedCategory = widget.goal!.category;
      _selectedFrequency = widget.goal!.frequency;
      _selectedPriority = widget.goal!.priority;
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goal = Goal(
        id: widget.goal?.id ?? GoalService.generateGoalId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetDate: _selectedDate,
        category: _selectedCategory,
        frequency: _selectedFrequency,
        priority: _selectedPriority,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
        isCompleted: widget.goal?.isCompleted ?? false,
        completedAt: widget.goal?.completedAt,
      );

      await GoalService.saveGoal(goal);
      
      if (mounted) {
        Navigator.pop(context, goal);
      }
    } on AACException catch (e) {
      setState(() {
        _errorMessage = 'Failed to save goal: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error saving goal';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate;
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365 * 2));

    final pickedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Select Due Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context, _selectedDate),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _showCategoryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Category'),
        actions: _categories.map((category) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Text(category.displayName),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPriorityPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Priority'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPriority = 1;
              });
            },
            child: const Text('Very Low'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPriority = 2;
              });
            },
            child: const Text('Low'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPriority = 3;
              });
            },
            child: const Text('Medium'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPriority = 4;
              });
            },
            child: const Text('High'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPriority = 5;
              });
            },
            child: const Text('Very High'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Medium';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFA0AEC0); // Gray
      case 2:
        return const Color(0xFF48BB78); // Green
      case 3:
        return const Color(0xFF4299E1); // Blue
      case 4:
        return const Color(0xFFED8936); // Orange
      case 5:
        return const Color(0xFFE53E3E); // Red
      default:
        return const Color(0xFF4299E1); // Blue
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        trailing: _isLoading
            ? const CupertinoActivityIndicator(radius: 10)
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveGoal,
                child: const Text('Save'),
              ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title field
              CupertinoFormSection(
                header: const Text('Goal Details'),
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _titleController,
                    placeholder: 'Enter goal title',
                    prefix: const Text('Title'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _descriptionController,
                    placeholder: 'Enter goal description (optional)',
                    prefix: const Text('Description'),
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Settings section
              CupertinoFormSection(
                header: const Text('Goal Settings'),
                children: [
                  // Due date
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        border: Border(
                          bottom: BorderSide(color: CupertinoColors.separator),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('Due Date', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          Text(
                            _formatDate(_selectedDate),
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category
                  GestureDetector(
                    onTap: _showCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        border: Border(
                          bottom: BorderSide(color: CupertinoColors.separator),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('Category', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          Text(
                            _selectedCategory.displayName,
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Priority
                  GestureDetector(
                    onTap: _showPriorityPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                      ),
                      child: Row(
                        children: [
                          const Text('Priority', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(_selectedPriority),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPriorityLabel(_selectedPriority),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Delete button for existing goals
              if (widget.goal != null)
                CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, widget.goal); // Return the goal to be deleted
                  },
                  color: CupertinoColors.systemRed,
                  child: const Text('Delete Goal'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
