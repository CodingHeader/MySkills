$ErrorActionPreference = 'Continue'

$agentDirs = @(
    ".trae",
    ".windsurf",
    ".cursor",
    ".claude",
    ".github",
    ".opencode",
    ".agents",
    ".agent",
    ".cline",
    ".codebuddy",
    ".codex",
    ".commandcode",
    ".continue",
    ".crush",
    ".factory",
    ".gemini",
    ".goose",
    ".junie",
    ".kilocode",
    ".kiro",
    ".kode",
    ".mcpjam",
    ".moltbot",
    ".mux",
    ".neovate",
    ".openhands",
    ".pi",
    ".pochi",
    ".qoder",
    ".qwen",
    ".roo",
    ".zencoder"
)

$currentDir = Get-Location

Write-Host "Scanning and cleaning skills directories in current folder..." -ForegroundColor Cyan
Write-Host "Current Directory: $currentDir" -ForegroundColor Gray

foreach ($dir in $agentDirs) {
    # Fix for PowerShell 5.1: Join-Path only accepts two arguments
    $agentPath = Join-Path $currentDir $dir
    $targetPath = Join-Path $agentPath "skills"
    
    if (Test-Path $targetPath) {
        try {
            Remove-Item -Path $targetPath -Recurse -Force -ErrorAction Stop
            Write-Host "[DELETED] $targetPath" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to delete $targetPath : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "Cleanup completed." -ForegroundColor Cyan
