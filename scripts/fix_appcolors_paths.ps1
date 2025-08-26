# PowerShell script to fix AppColors import paths
Write-Host "Fixing AppColors import paths..." -ForegroundColor Green

Set-Location "d:\oone\mdms_d"

# Get all Dart files that have incorrect import paths
$errorFiles = @(
    "lib\presentation\widgets\common\app_card.dart",
    "lib\presentation\widgets\common\app_input_field.dart", 
    "lib\presentation\widgets\common\app_sidebar.dart",
    "lib\presentation\widgets\common\sidebar_drawer.dart",
    "lib\presentation\widgets\common\theme_switch.dart"
)

$fixedFiles = 0

foreach ($filePath in $errorFiles) {
    if (Test-Path $filePath) {
        try {
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8
            $originalContent = $content
            
            # Fix the import path
            $content = $content -replace "import '../themes/app_colors\.dart';", "import '../../../core/constants/app_colors.dart';"
            
            if ($content -ne $originalContent) {
                Set-Content -Path $filePath -Value $content -Encoding UTF8
                $fixedFiles++
                Write-Host "Fixed import path in: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error fixing $(Split-Path $filePath -Leaf): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`nImport path fixes complete!" -ForegroundColor Green
Write-Host "Files fixed: $fixedFiles" -ForegroundColor Cyan
