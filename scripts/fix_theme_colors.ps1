# PowerShell script to fix deprecated color usage
# Run this from the mdms_d directory

Write-Host "Starting theme color migration..." -ForegroundColor Green

# Navigate to project directory
Set-Location "d:\oone\mdms_d"

# Get all Dart files in presentation/widgets
$dartFiles = Get-ChildItem -Path "lib\presentation\widgets" -Recurse -Filter "*.dart"

$updatedFiles = 0

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        
        # Check if file uses AppColors
        if ($content -like "*AppColors.*") {
            Write-Host "Processing: $($file.Name)" -ForegroundColor Yellow
            
            # Add theme import if missing
            if ($content -notlike "*import*app_theme.dart*") {
                # Find the last import line
                $lines = $content -split "`n"
                $lastImportIndex = -1
                for ($i = 0; $i -lt $lines.Length; $i++) {
                    if ($lines[$i] -like "import *") {
                        $lastImportIndex = $i
                    }
                }
                
                if ($lastImportIndex -ge 0) {
                    $lines[$lastImportIndex] = $lines[$lastImportIndex] + "`nimport '../../core/app_theme.dart';"
                    $content = $lines -join "`n"
                }
            }
            
            # Replace deprecated colors
            $content = $content -replace "AppColors\.textPrimary", "context.textColor"
            $content = $content -replace "AppColors\.textSecondary", "context.textSecondaryColor"
            $content = $content -replace "AppColors\.surface", "context.surfaceColor"
            $content = $content -replace "AppColors\.background", "context.backgroundColor"
            $content = $content -replace "AppColors\.border", "context.borderColor"
            $content = $content -replace "AppColors\.surfaceVariant", "context.surfaceVariantColor"
            $content = $content -replace "AppColors\.textTertiary", "context.textSecondaryColor"
            
            # Replace withOpacity with withValues
            $content = $content -replace "\.withOpacity\(([^)]+)\)", '.withValues(alpha: $1)'
            
            # Write back if changed
            if ($content -ne $originalContent) {
                Set-Content -Path $file.FullName -Value $content -Encoding UTF8
                $updatedFiles++
                Write-Host "Updated: $($file.Name)" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nMigration complete!" -ForegroundColor Green
Write-Host "Files updated: $updatedFiles" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run 'flutter analyze' to check for errors" -ForegroundColor White
Write-Host "2. Some files may need manual review for context availability" -ForegroundColor White
Write-Host "3. Files without BuildContext should use AppColors directly" -ForegroundColor White
