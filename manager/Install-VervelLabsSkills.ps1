param(
    [switch]$SearchFallback,
    [string]$InstallScope
)

# Helper function for colored output
function Write-Panel ($Message, $Color = 'Cyan') {
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

# Function to get skill paths
function Get-SkillPaths ($SkillName) {
    $cursorPath = Join-Path ".cursor" "skills"
    $globalPath = Join-Path $HOME (Join-Path $cursorPath $SkillName)
    $localPath = Join-Path (Get-Location) (Join-Path $cursorPath $SkillName)
    return @{ Global = $globalPath; Local = $localPath }
}

# Function to test if skill is installed
function Test-SkillInstalled ($SkillName, $IsGlobal) {
    $paths = Get-SkillPaths $SkillName
    if ($IsGlobal) {
        return (Test-Path $paths.Global)
    } else {
        return (Test-Path $paths.Local)
    }
}

# Function to resolve local path for "." source
function Resolve-LocalPath ($SkillName) {
    # Assuming script is in /manager, so root is ..
    $root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $path = Join-Path $root (Join-Path "skills" $SkillName)
    return $path
}

# Function to install skill
function Install-Skill ($SkillName, $RepoUrl, $Agents, $IsGlobal) {
    $scopeFlag = if ($IsGlobal) { "" } else { "--project" }
    $agentArgs = $Agents | ForEach-Object { "-a $_" }
    
    # 1. Check if already installed
    if (Test-SkillInstalled $SkillName $IsGlobal) {
        Write-Panel "[SKIP] $SkillName already installed." 'Yellow'
        return
    }

    $sourceArg = $RepoUrl
    if ($RepoUrl -eq ".") {
        $sourceArg = Resolve-LocalPath $SkillName
        if (-not (Test-Path $sourceArg)) {
             Write-Panel "[ERROR] Local skill not found at $sourceArg" 'Red'
             return
        }
        Write-Panel "[INSTALL] Installing local skill $SkillName from $sourceArg..." 'Cyan'
    } else {
        Write-Panel "[INSTALL] Installing $SkillName from $RepoUrl..." 'Cyan'
    }
    
    # 2. Construct npx command
    $npxCmd = "npx.cmd"
    
    # Build arguments array safely
    $argsList = @("-y", "skills", "add", "$sourceArg")
    if ($RepoUrl -ne ".") {
        $argsList += "--skill"
        $argsList += "$SkillName"
    }
    $argsList += "-y"
    $argsList += $agentArgs
    
    if (-not [string]::IsNullOrEmpty($scopeFlag)) {
        $argsList += $scopeFlag
    }

    Write-Panel "[EXEC] $npxCmd $argsList" 'Gray'
    
    try {
        & $npxCmd $argsList
        if ($LASTEXITCODE -eq 0) {
            Write-Panel "[SUCCESS] $SkillName installed." 'Green'
        } else {
            Write-Panel "[FAIL] Failed to install $SkillName (Exit Code: $LASTEXITCODE)" 'Red'
        }
    } catch {
        Write-Panel "[ERROR] $_" 'Red'
    }
}

# --- Main Script ---

if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# 0. Setup
$Agents = @("windsurf", "trae", "opencode", "cursor")

# Scope settings
if ([string]::IsNullOrWhiteSpace($InstallScope)) {
    Write-Host "请选择安装范围："
    Write-Host "[G] 全局 (默认) - 安装到用户主目录"
    Write-Host "[P] 项目 - 安装到当前项目目录"
    $selection = Read-Host "请选择 (G/p)"
    if ($selection -match "^[Pp]") { $InstallScope = "Project" }
    else { $InstallScope = "Global" }
}

$scope = "Global"
$isGlobal = $true
if ($InstallScope -eq "Project") {
    $scope = "Project"
    $isGlobal = $false
}

# 1. Define Skills List (Updated with Fixes)
$Skills = @(
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="vercel-react-best-practices" },
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="web-design-guidelines" },
    @{ Source="https://github.com/vercel-labs/skills"; Skill="find-skills" },
    @{ Source="https://github.com/vercel-labs/agent-browser"; Skill="agent-browser" },
    @{ Source="https://github.com/squirrelscan/skills"; Skill="audit-website" },
    @{ Source="https://github.com/supabase/agent-skills"; Skill="postgres-best-practices" },
    @{ Source="https://github.com/nextlevelbuilder/ui-ux-pro-max-skill"; Skill="ui-ux-pro-max" },
    @{ Source="https://github.com/better-auth/skills"; Skill="best-practices" },
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="vercel-composition-patterns" },
    @{ Source="https://github.com/obra/superpowers"; Skill="brainstorming" },
    @{ Source="https://github.com/callstackincubator/agent-skills"; Skill="react-native-best-practices" },
    @{ Source="https://github.com/browser-use/browser-use"; Skill="browser-use" },
    @{ Source="https://github.com/remotion-dev/skills"; Skill="remotion" },
    @{ Source="https://github.com/anthropics/skills"; Skill="frontend-design" },
    @{ Source="https://github.com/anthropics/skills"; Skill="skill-creator" },
    @{ Source="https://github.com/anthropics/skills"; Skill="webapp-testing" },
    @{ Source="https://github.com/anthropics/skills"; Skill="web-artifacts-builder" },
    @{ Source="https://github.com/anthropics/skills"; Skill="mcp-builder" },
    @{ Source="https://github.com/anthropics/skills"; Skill="canvas-design" },
    @{ Source="https://github.com/anthropics/skills"; Skill="internal-comms" },
    @{ Source="https://github.com/anthropics/skills"; Skill="algorithmic-art" },
    @{ Source="https://github.com/anthropics/skills"; Skill="theme-factory" },
    @{ Source="https://github.com/anthropics/skills"; Skill="doc-coauthoring" },
    @{ Source="https://github.com/anthropics/skills"; Skill="pptx" },
    @{ Source="https://github.com/anthropics/skills"; Skill="xlsx" },
    @{ Source="https://github.com/anthropics/skills"; Skill="docx" },
    @{ Source="https://github.com/anthropics/skills"; Skill="pdf" },
    @{ Source="https://github.com/expo/skills"; Skill="building-native-ui" },
    @{ Source="https://github.com/expo/skills"; Skill="upgrading-expo" },
    @{ Source="https://github.com/expo/skills"; Skill="native-data-fetching" },
    @{ Source="https://github.com/expo/skills"; Skill="expo-dev-client" },
    @{ Source="https://github.com/expo/skills"; Skill="expo-deployment" },
    @{ Source="https://github.com/expo/skills"; Skill="expo-tailwind-setup" },
    @{ Source="https://github.com/expo/skills"; Skill="expo-api-routes" },
    @{ Source="https://github.com/coreyhaines31/marketingskills"; Skill="marketing-ideas" },
    @{ Source="https://github.com/coreyhaines31/marketingskills"; Skill="copy-editing" },
    @{ Source="https://github.com/coreyhaines31/marketingskills"; Skill="programmatic-seo" },
    @{ Source="https://github.com/coreyhaines31/marketingskills"; Skill="marketing-psychology" },
    @{ Source="https://github.com/coreyhaines31/marketingskills"; Skill="copywriting" },
    @{ Source="https://github.com/coreyhaines31/marketingskills"; Skill="seo-audit" },
    @{ Source="https://github.com/composiohq/awesome-claude-skills"; Skill="skill-share" },
    @{ Source="."; Skill="instruction_repeater" },
    @{ Source="."; Skill="multi-agent-thinker" },
    @{ Source="."; Skill="project-steward" },
    @{ Source="."; Skill="project-structure-creator" }
)

Write-Panel ("共 {0} 个技能；正在通过 npx skills 检查并安装..." -f $Skills.Count) 'Green'
Write-Panel ("目标代理：{0} | 范围：{1}" -f ($Agents -join ', '), $scope) 'Gray'

# 2. Install Loop
foreach ($item in $Skills) {
    Install-Skill -SkillName $item.Skill -RepoUrl $item.Source -Agents $Agents -IsGlobal $isGlobal
}

Write-Panel "所有任务完成。" 'Green'
