import 'package:flutter/material.dart';
import '../common/app_dropdown_field.dart';

class TestDropdownImport extends StatelessWidget {
  const TestDropdownImport({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSearchableDropdown<String>(
      label: 'Test',
      hintText: 'Test',
      items: const [],
    );
  }
}
