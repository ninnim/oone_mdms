# PowerShell script to add missing AppColors imports
Write-Host "Adding missing AppColors imports..." -ForegroundColor Green

Set-Location "d:\oone\mdms_d"

# Get all Dart files that have undefined AppColors errors
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
            
            # Check if AppColors import is missing
            if ($content -like "*AppColors*" -and $content -notlike "*import*app_colors.dart*") {
                # Add AppColors import after other imports
                $lines = $content -split "`n"
                $lastImportIndex = -1
                for ($i = 0; $i -lt $lines.Length; $i++) {
                    if ($lines[$i] -like "import *") {
                        $lastImportIndex = $i
                    }
                }
                
                if ($lastImportIndex -ge 0) {
                    $lines[$lastImportIndex] = $lines[$lastImportIndex] + "`nimport '../themes/app_colors.dart';"
                    $content = $lines -join "`n"
                    
                    Set-Content -Path $filePath -Value $content -Encoding UTF8
                    $fixedFiles++
                    Write-Host "Added AppColors import to: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Host "Error fixing $(Split-Path $filePath -Leaf): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`nImport fixes complete!" -ForegroundColor Green
Write-Host "Files fixed: $fixedFiles" -ForegroundColor Cyan
