# PowerShell script to completely revert all widget files to use AppColors
Write-Host "Reverting all widgets to use AppColors..." -ForegroundColor Green

Set-Location "d:\oone\mdms_d"

# Get all Dart files in presentation/widgets
$dartFiles = Get-ChildItem -Path "lib\presentation\widgets" -Recurse -Filter "*.dart"

$revertedFiles = 0

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        
        # Remove any theme imports that were added
        $content = $content -replace "import '../themes/app_theme\.dart';\r?\n", ""
        $content = $content -replace "import '../../themes/app_theme\.dart';\r?\n", ""
        $content = $content -replace "import '../../../themes/app_theme\.dart';\r?\n", ""
        
        # Revert all context theme extensions back to AppColors
        $content = $content -replace "context\.textColor", "AppColors.textPrimary"
        $content = $content -replace "context\.textSecondaryColor", "AppColors.textSecondary"
        $content = $content -replace "context\.surfaceColor", "AppColors.surface"
        $content = $content -replace "context\.backgroundColor", "AppColors.background"
        $content = $content -replace "context\.borderColor", "AppColors.border"
        $content = $content -replace "context\.surfaceVariantColor", "AppColors.surfaceVariant"
        $content = $content -replace "context\.surfaceColorVariant", "AppColors.surfaceVariant"
        $content = $content -replace "context\.borderColorLight", "AppColors.border"
        
        # Write back if changed
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            $revertedFiles++
            Write-Host "Reverted: $($file.Name)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error reverting $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nRevert complete!" -ForegroundColor Green
Write-Host "Files reverted: $revertedFiles" -ForegroundColor Cyan
Write-Host "`nAll widgets now use AppColors directly" -ForegroundColor Yellow
