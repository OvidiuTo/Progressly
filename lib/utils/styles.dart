import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6B4EFF);
  static const secondary = Color(0xFF38B6FF);
  static const background = Color(0xFFF8F9FF);
  static const surface = Colors.white;
  static const error = Color(0xFFDC3545);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
}

class AppStyles {
  static InputDecoration textFieldDecoration(
    String label, {
    String? hint,
    IconData? icon,
    bool isPassword = false,
    VoidCallback? onTogglePassword,
    bool obscurePassword = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: AppColors.textSecondary,
              size: 22,
            )
          : null,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: onTogglePassword,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error),
      ),
      errorStyle: TextStyle(color: AppColors.error),
    );
  }

  static ButtonStyle elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextStyle linkTextStyle() {
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      inherit: true,
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      textStyle: linkTextStyle(),
    );
  }

  static BoxDecoration containerDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.1),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}
