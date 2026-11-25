import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';

/// Barre blanche à grand titre foncé des écrans « Confirm » du kit. Les
/// autres écrans gardent la barre indigo du thème.
PreferredSizeWidget lightAppBar(
  String title, {
  Widget? leading,
  List<Widget>? actions,
}) => AppBar(
  leading: leading,
  actions: actions,
  backgroundColor: Colors.white,
  foregroundColor: AppColors.text,
  surfaceTintColor: Colors.transparent,
  title: Text(
    title,
    style: const TextStyle(
      color: AppColors.text,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
  ),
);
