# PowerShell script to fix the incorrect import paths and revert problematic changes
Write-Host "Fixing theme import issues..." -ForegroundColor Green

Set-Location "d:\oone\mdms_d"

# Get all Dart files in presentation/widgets
$dartFiles = Get-ChildItem -Path "lib\presentation\widgets" -Recurse -Filter "*.dart"

$fixedFiles = 0

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        
        # Fix wrong import path
        $content = $content -replace "import '../../core/app_theme\.dart';", "import '../themes/app_theme.dart';"
        
        # For files that have context errors, revert to AppColors temporarily
        if ($content -like "*undefined_getter*" -or $content -like "*Undefined name 'context'*" -or $content -like "*Invalid constant value*") {
            # Revert problematic changes back to AppColors
            $content = $content -replace "context\.textColor", "AppColors.textPrimary"
            $content = $content -replace "context\.textSecondaryColor", "AppColors.textSecondary"
            $content = $content -replace "context\.surfaceColor", "AppColors.surface"
            $content = $content -replace "context\.backgroundColor", "AppColors.background"
            $content = $content -replace "context\.borderColor", "AppColors.border"
            $content = $content -replace "context\.surfaceVariantColor", "AppColors.surfaceVariant"
            $content = $content -replace "context\.surfaceColorVariant", "AppColors.surfaceVariant"
            $content = $content -replace "context\.borderColorLight", "AppColors.border"
            
            # Remove theme import if reverting
            $content = $content -replace "import '../themes/app_theme\.dart';\r?\n", ""
        }
        
        # Fix withValues back to withOpacity for now (less critical)
        $content = $content -replace "\.withValues\(alpha: ([^)]+)\)", '.withOpacity($1)'
        
        # Write back if changed
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            $fixedFiles++
            Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error fixing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nFix complete!" -ForegroundColor Green
Write-Host "Files fixed: $fixedFiles" -ForegroundColor Cyan
Write-Host "`nRunning analysis..." -ForegroundColor Yellow
