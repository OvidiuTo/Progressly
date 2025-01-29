import 'package:flutter/material.dart';
import '../models/habit_frequency.dart';
import '../utils/styles.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _habitNameController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  bool _hasReminder = false;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Reminder Time: ${_selectedTime.format(context)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.textSecondary.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<HabitFrequency>(
                        value: _selectedFrequency,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        items: HabitFrequency.values.map((frequency) {
                          return DropdownMenuItem<HabitFrequency>(
                            value: frequency,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(frequency.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (HabitFrequency? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFrequency = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Enable Reminder',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'Get notified at the selected time',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    value: _hasReminder,
                    activeColor: AppColors.primary,
                    onChanged: (bool value) {
                      setState(() {
                        _hasReminder = value;
                      });
                    },
                  ),
                ],
              ),
            ),
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
                        'time': _selectedTime,
                        'frequency': _selectedFrequency,
                        'hasReminder': _hasReminder,
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
