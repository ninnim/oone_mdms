#!/usr/bin/env python3
"""
Script to fix deprecated color usage in Flutter app
This script will replace deprecated AppColors with theme-aware alternatives
"""

import os
import re
import glob

def replace_in_file(file_path, replacements):
    """Replace patterns in a file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        for old_pattern, new_pattern in replacements.items():
            content = re.sub(old_pattern, new_pattern, content)
        
        # Only write if content changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {file_path}")
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process all Dart files"""
    
    # Define replacement patterns
    replacements = {
        # AppColors to context extensions
        r'AppColors\.textPrimary': 'context.textColor',
        r'AppColors\.textSecondary': 'context.textSecondaryColor',
        r'AppColors\.surface': 'context.surfaceColor',
        r'AppColors\.background': 'context.backgroundColor',
        r'AppColors\.border': 'context.borderColor',
        r'AppColors\.surfaceVariant': 'context.surfaceVariantColor',
        r'AppColors\.textTertiary': 'context.textSecondaryColor', # Map to secondary since no tertiary
        
        # withOpacity to withValues
        r'\.withOpacity\(([^)]+)\)': r'.withValues(alpha: \1)',
    }
    
    # Add theme import if missing
    theme_import = "import '../../core/app_theme.dart';"
    
    # Find all Dart files in presentation/widgets
    widget_files = glob.glob('lib/presentation/widgets/**/*.dart', recursive=True)
    
    updated_files = 0
    
    for file_path in widget_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check if file uses AppColors
            if 'AppColors.' in content:
                # Check if theme import exists
                if "import '../../core/app_theme.dart';" not in content and "import '../../../core/app_theme.dart';" not in content:
                    # Add theme import after the last import
                    import_pattern = r'(import [^;]+;)(?=\s*\n\s*(?:class|abstract|mixin|enum|typedef|extension|void|Widget))'
                    if re.search(import_pattern, content):
                        content = re.sub(import_pattern, r'\1\n' + theme_import, content, count=1)
                    else:
                        # Add after Flutter imports
                        flutter_import_pattern = r'(import [\'"]package:flutter[^;]+;)'
                        if re.search(flutter_import_pattern, content):
                            content = re.sub(flutter_import_pattern, r'\1\n' + theme_import, content, count=1)
            
            # Apply replacements
            original_content = content
            for old_pattern, new_pattern in replacements.items():
                content = re.sub(old_pattern, new_pattern, content)
            
            # Write if changed
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated: {file_path}")
                updated_files += 1
                
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    print(f"\nTotal files updated: {updated_files}")
    print("\nNote: Some files may still need manual review for context availability.")
    print("Files without BuildContext should use AppColors directly.")

if __name__ == "__main__":
    # Change to project directory
    os.chdir('d:/oone/mdms_d')
    main()
