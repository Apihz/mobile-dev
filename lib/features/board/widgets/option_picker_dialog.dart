import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

//one choice shown in the picker dialog
class PickerOption {
  final String value;
  final String label;
  final Color? color; //shows a colored dot when set
  final IconData? icon; //shows an icon when set (and no color)

  const PickerOption({
    required this.value,
    required this.label,
    this.color,
    this.icon,
  });
}

class OptionPickerDialog extends StatelessWidget {
  final String title;
  final List<PickerOption> options;
  final String? selectedValue;

  const OptionPickerDialog({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
  });

  //show the dialog and return the picked value (null if dismissed)
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<PickerOption> options,
    String? selectedValue,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierColor: Colors.black26,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => OptionPickerDialog(
        title: title,
        options: options,
        selectedValue: selectedValue,
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.fromLTRB(25, 15, 15,15),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 16),
                   GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 22, color: AppColors.primary),
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 16),
              //scroll in case there are many options (like a big team)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options
                        .map((option) => _buildOption(context, option))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  //one tappable row inside the dialog
  Widget _buildOption(BuildContext context, PickerOption option) {
    final bool selected = option.value == selectedValue;
    return GestureDetector(
      onTap: () => Navigator.pop(context, option.value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            //colored dot for priority, icon for assignee
            if (option.color != null)
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                ),
              )
            else if (option.icon != null)
              Icon(option.icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 20),
            if (selected) Icon(Icons.check, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
