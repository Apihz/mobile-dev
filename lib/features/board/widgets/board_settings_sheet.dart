import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../board_display_settings.dart';

//bottom sheet that lets the user pick how task cards look and how they sort
class BoardSettingsSheet extends StatefulWidget {
  final BoardDisplaySettings settings;
  final void Function(BoardDisplaySettings settings) onChanged;

  const BoardSettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<BoardSettingsSheet> createState() => _BoardSettingsSheetState();
}

class _BoardSettingsSheetState extends State<BoardSettingsSheet> {
  late BoardDisplaySettings _settings;

  //sort options: the value saved in code -> the label shown to the user
  final Map<String, String> _sortOptions = {
    'default': 'Default',
    'priority': 'Priority',
    'deadline': 'Deadline',
    'title': 'Title (A-Z)',
    'newest': 'Newest first',
  };

  @override
  void initState() {
    super.initState();
    //work on a copy so we can update the board live as the user changes things
    _settings = widget.settings.copy();
  }

  //update one setting then tell the board to rebuild
  void _apply() {
    setState(() {});
    widget.onChanged(_settings.copy());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                'Card display',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Choose what shows on each task card',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),

            SwitchListTile(
              value: _settings.showPriority,
              activeThumbColor: AppColors.onSurface,
              secondary: const Icon(Icons.flag_outlined, color: AppColors.muted),
              title: const Text('Priority badge',style: TextStyle(color: AppColors.onSurface, fontSize: 15),),
              subtitle: const Text('Show the task priority label',style: TextStyle(color: AppColors.muted, fontSize: 12),),
              onChanged: (value) {
                _settings.showPriority = value;
                _apply();
              },
            ),
            SwitchListTile(
              value: _settings.showDescription,
              activeThumbColor: AppColors.onSurface,
              secondary: const Icon(Icons.notes_outlined, color: AppColors.muted),
              title: const Text('Description',style: TextStyle(color: AppColors.onSurface, fontSize: 15),),
              subtitle: const Text('Show a short preview of the description',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              onChanged: (value) {
                _settings.showDescription = value;
                _apply();
              },
            ),
            SwitchListTile(
              value: _settings.showDeadline,
              activeThumbColor: AppColors.onSurface,
              secondary: const Icon(Icons.calendar_today_outlined, color: AppColors.muted),
              title: const Text('Deadline',style: TextStyle(color: AppColors.onSurface, fontSize: 15),),
              subtitle: const Text('Show the due date when set',style: TextStyle(color: AppColors.muted, fontSize: 12),),
              onChanged: (value) {
                _settings.showDeadline = value;
                _apply();
              },
            ),
            SwitchListTile(
              value: _settings.compact,
              activeThumbColor: AppColors.onSurface,
              secondary: const Icon(Icons.density_small, color: AppColors.muted),
              title: const Text('Compact cards',style: TextStyle(color: AppColors.onSurface, fontSize: 15),),
              subtitle: const Text('Tighter spacing to fit more tasks',style: TextStyle(color: AppColors.muted, fontSize: 12),),
              onChanged: (value) {
                _settings.compact = value;
                _apply();
              },
            ),

            const Divider(
                color: AppColors.border, height: 24, indent: 20, endIndent: 20),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Sort tasks by',style: TextStyle(color: AppColors.onSurface,fontSize: 16,fontWeight: FontWeight.w600,),),
            ),
            //one pill per sort option
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sortOptions.keys.map((key) {
                  return _buildSortChip(key, _sortOptions[key]!);
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  //a tappable pill for picking the sort option
  Widget _buildSortChip(String value, String label) {
    final bool selected = _settings.sortBy == value;
    return GestureDetector(
      onTap: () {
        _settings.sortBy = value;
        _apply();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.onSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.onSurface : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.muted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
