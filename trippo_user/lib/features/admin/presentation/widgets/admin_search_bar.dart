import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';

/// Reusable search bar widget for admin screens
class AdminSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool showFilter;
  final TextEditingController? controller;

  const AdminSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onFilterTap,
    this.showFilter = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search, color: AdminTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AdminTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AdminTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AdminTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Filter button
          if (showFilter) ...[
            const SizedBox(width: 8),
            Material(
              color: AdminTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

