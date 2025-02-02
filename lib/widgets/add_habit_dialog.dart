import 'package:flutter/material.dart';
import '../models/habit_frequency.dart';
import '../utils/styles.dart';
import '../models/habit_category.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _habitNameController = TextEditingController();
  HabitCategory _selectedCategory = HabitCategory.other;

  Widget _buildCategorySelector() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      physics: const NeverScrollableScrollPhysics(),
      children: HabitCategory.values.map((category) {
        final isSelected = category == _selectedCategory;

        return InkWell(
          onTap: () => setState(() => _selectedCategory = category),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? category.color
                    : AppColors.textSecondary.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    flex: 3,
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 18,
                          ),
                        )),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    flex: 2,
                    child: Text(
                      category.label,
                      style: TextStyle(
                        color: isSelected
                            ? category.color
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppStyles.containerDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Habit',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _habitNameController,
                decoration: AppStyles.textFieldDecoration(
                  'Habit Name',
                  hint: 'Enter habit name',
                  icon: Icons.edit_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppStyles.textButtonStyle(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'name': _habitNameController.text.trim(),
                        'time': TimeOfDay.now(),
                        'frequency': HabitFrequency.daily,
                        'hasReminder': false,
                        'category': _selectedCategory,
                      });
                    }
                  },
                  style: AppStyles.elevatedButtonStyle(),
                  child: const Text('Add Habit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
