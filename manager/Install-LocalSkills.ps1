[CmdletBinding()]
param(
    [switch]$Global,
    [switch]$NoUniversal,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# Robust Windows detection for PS 5.1 and Core
$IsWin = $env:OS -eq 'Windows_NT'
if ($PSVersionTable.PSEdition -eq 'Core') {
    $IsWin = $IsWindows
}

if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $PSScriptRoot = Split-Path -Parent $scriptPath
}

# Use PSScriptRoot/.. as repo root for checking local installations if running from manager/
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Define the list of skills to install (Source + Skill Name)
# Extracted from LocalSkills.md
$rawSkills = @(
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="react-best-practices" },
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="web-design-guidelines" },
    @{ Source="https://github.com/vercel-labs/skills"; Skill="find-skills" },
    @{ Source="https://github.com/vercel-labs/agent-browser"; Skill="agent-browser" },
    @{ Source="https://github.com/squirrelscan/skills"; Skill="audit-website" },
    @{ Source="https://github.com/supabase/agent-skills"; Skill="supabase-postgres-best-practices" },
    @{ Source="https://github.com/nextlevelbuilder/ui-ux-pro-max-skill"; Skill="ui-ux-pro-max" },
    @{ Source="https://github.com/better-auth/skills"; Skill="best-practices" },
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="composition-patterns" },
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
    @{ Source="https://github.com/runkids/skillshare"; Skill="skillshare" },
    @{ Source="."; Skill="instruction_repeater" },
    @{ Source="."; Skill="multi-agent-thinker" },
    @{ Source="."; Skill="project-steward" },
    @{ Source="."; Skill="project-structure-creator" }
)

# Convert to proper objects for Group-Object to work correctly
$skillsToInstall = $rawSkills | ForEach-Object { [PSCustomObject]$_ }

function Get-SkillPaths {
  param(
    [Parameter(Mandatory=$true)][string]$Skill,
    [Parameter(Mandatory=$true)][bool]$IsGlobal,
    [Parameter(Mandatory=$true)][bool]$UseUniversal,
    [Parameter(Mandatory=$true)][string]$RepoRoot
  )

  $paths = @()
  if ($UseUniversal) {
    if ($IsGlobal) { 
        $paths += (Join-Path $HOME ".agent\skills\$Skill\SKILL.md") 
    } else { 
        $paths += (Join-Path $RepoRoot ".agent\skills\$Skill\SKILL.md") 
    }
  }

  # Fallback/Legacy paths check (Claude default)
  if ($IsGlobal) { 
      $paths += (Join-Path $HOME ".claude\skills\$Skill\SKILL.md") 
  } else { 
      $paths += (Join-Path $RepoRoot ".claude\skills\$Skill\SKILL.md") 
  }

  return $paths
}

function Test-SkillInstalled {
  param(
    [Parameter(Mandatory=$true)][string]$Skill,
    [Parameter(Mandatory=$true)][bool]$IsGlobal,
    [Parameter(Mandatory=$true)][bool]$UseUniversal,
    [Parameter(Mandatory=$true)][string]$RepoRoot
  )

  foreach ($p in (Get-SkillPaths -Skill $Skill -IsGlobal $IsGlobal -UseUniversal $UseUniversal -RepoRoot $RepoRoot)) {
    if (Test-Path -LiteralPath $p -PathType Leaf) { return $true }
  }
  return $false
}

$useUniversal = -not $NoUniversal.IsPresent
Write-Host "脚本中定义了 $($skillsToInstall.Count) 个技能。"
if ($useUniversal) { Write-Host "模式：通用 (.agent/skills)" }
if ($Global) { Write-Host "范围：全局" } else { Write-Host "范围：项目 ($repoRoot)" }

# Execute in Repo Root so local .agent/skills is found there
Push-Location $repoRoot
try {
  # Group skills by Source URL to optimize installations
  $groupedSkills = $skillsToInstall | Group-Object Source

  foreach ($group in $groupedSkills) {
        $source = $group.Name
        if ([string]::IsNullOrWhiteSpace($source)) {
            Write-Warning "发现来源为空的组。跳过。"
            continue
        }

        $skillsInRepo = $group.Group.Skill

        # Check if ALL skills in this repo are already installed
        $missingSkills = @()
        foreach ($skill in $skillsInRepo) {
            $isInstalled = Test-SkillInstalled -Skill $skill -IsGlobal $Global.IsPresent -UseUniversal $useUniversal -RepoRoot $repoRoot
            if (-not $isInstalled) {
                $missingSkills += $skill
            }
        }

        if ($missingSkills.Count -eq 0) {
            Write-Host "[跳过] $source 中的所有技能已安装。" -ForegroundColor DarkGray
            continue
        }

        # If any skill is missing, we install only the requested skills
        Write-Host "[安装] 正在处理 $source..." -ForegroundColor Cyan
        Write-Host "缺失技能：$($missingSkills -join ', ')"

        if ($WhatIf.IsPresent) {
            Write-Host "[WHATIF] 将从 $source 安装：$($missingSkills -join ', ')"
            continue
        }

        # Logic for Local Source vs Remote Source
        $isLocalSource = ($source -eq ".")
        
        $tempDir = $null
        
        try {
            if ($isLocalSource) {
                # For local source, we assume the skills are in the 'skills' directory of the repoRoot
                # We don't clone, we just point to the local path
                Write-Host "  使用本地技能源..." -ForegroundColor DarkGray
                # No cloning needed
            } else {
                # Clone repo to temp directory
                $projectTempDir = Join-Path $repoRoot ".agent"
                if (-not (Test-Path $projectTempDir)) { New-Item -ItemType Directory -Path $projectTempDir -Force | Out-Null }
                $tempDir = Join-Path $projectTempDir "tmp_clone_$((Get-Random).ToString())"
                
                Write-Host "  正在克隆仓库..." -ForegroundColor DarkGray
                # Use git to clone (depth 1 for speed)
                $gitArgs = "clone --depth 1 $source `"$tempDir`""
                Start-Process -FilePath "git" -ArgumentList $gitArgs -NoNewWindow -Wait -PassThru | Out-Null
                
                if (-not (Test-Path $tempDir)) {
                    Write-Error "克隆仓库失败：$source"
                    continue
                }
            }

            foreach ($skillName in $missingSkills) {
                $skillPath = $null
                
                if ($isLocalSource) {
                    # Local skill path logic: repoRoot/skills/skillName
                    $skillPath = Join-Path $repoRoot "skills\$skillName"
                    if (-not (Test-Path $skillPath -PathType Container)) {
                        Write-Warning "  在本地 skills 目录中找不到技能 '$skillName'。"
                        continue
                    }
                } else {
                    # Remote (cloned) skill path logic
                    $found = $false

                    # Strategy 1: Check common paths (root/$skillName, root/skills/$skillName)
                    $possiblePaths = @(
                        (Join-Path $tempDir $skillName),
                        (Join-Path $tempDir "skills\$skillName"),
                        (Join-Path $tempDir "src\$skillName")
                    )

                    foreach ($p in $possiblePaths) {
                        if (Test-Path (Join-Path $p "SKILL.md") -PathType Leaf) {
                            $skillPath = $p
                            $found = $true
                            break
                        }
                    }

                    if (-not $found) {
                        # Strategy 2: Deep search for SKILL.md
                        $skillMds = Get-ChildItem -Path $tempDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue
                        
                        foreach ($md in $skillMds) {
                            $parentDir = $md.Directory
                            if ($parentDir.Name -eq $skillName) {
                                $skillPath = $parentDir.FullName
                                $found = $true
                                break
                            }
                        }
                        
                        # Fallback: if only one SKILL.md found, use it (single skill repo)
                        if (-not $found -and $skillMds.Count -eq 1) {
                            $skillPath = $skillMds[0].Directory.FullName
                            $found = $true
                        }
                    }

                    if (-not $found) {
                        Write-Warning "  在克隆的仓库中找不到技能 '$skillName' (未找到 SKILL.md)。"
                        continue
                    }
                }

                # Convert absolute path to relative path for openskills
                # openskills install requires relative path like "./.agent/tmp_clone_.../skill"
                # Since we are in $repoRoot, we can construct it relative to that.
                $relativePath = $skillPath.Substring($repoRoot.Length)
                if ($relativePath.StartsWith("\") -or $relativePath.StartsWith("/")) {
                    $relativePath = "." + $relativePath
                } else {
                    $relativePath = ".\" + $relativePath
                }
                # Ensure forward slashes for cross-platform compatibility (Node often prefers them)
                $relativePath = $relativePath -replace '\\', '/'

                Write-Host "  正在从 $relativePath 安装 $skillName..."

                # Construct OpenSkills command for LOCAL installation
                $argsList = @('openskills@latest','install', $relativePath, '-y')
                if ($useUniversal) { $argsList += '--universal' }
                if ($Global.IsPresent) { $argsList += '-g' }

                $display = "npx " + ($argsList -join ' ')
                
                # Prepare input piping to suppress prompts (reuse existing robust logic)
                if ($IsWin) {
                    $tempYesFile = Join-Path $env:TEMP "openskills_yes_$((Get-Random).ToString()).txt"
                    1..100 | ForEach-Object { "y" } | Out-File -FilePath $tempYesFile -Encoding ASCII
                    
                    try {
                        $npxArgs = $argsList -join ' '
                        # Pipe the yes file to the command
                        # Using cmd /c explicitly to handle piping robustly in PS
                        cmd /c "type `"$tempYesFile`" | npx.cmd $npxArgs"
                    }
                    finally {
                        if (Test-Path $tempYesFile) { Remove-Item $tempYesFile -ErrorAction SilentlyContinue }
                    }
                } else {
                    # Unix/Mac
                    $npxArgs = $argsList -join ' '
                    bash -c "yes | npx $npxArgs"
                }

                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "  $skillName 的安装命令完成，退出代码为 $LASTEXITCODE。"
                }
            }
        }
        catch {
            Write-Warning "处理 $source 时发生错误：$_"
        }
        finally {
            # Cleanup temp clone
            if ($null -ne $tempDir -and (Test-Path $tempDir)) { 
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue 
            }
        }
    }

  # Final Step: Sync
  Write-Host "`n[同步] 正在生成 AGENTS.md..." -ForegroundColor Green
  # Added -y to sync command to avoid interactive prompts
  $syncArgs = @('openskills@latest', 'sync', '-y')
  if ($WhatIf.IsPresent) {
      Write-Host "[WHATIF] 将运行：npx openskills@latest sync -y"
  } else {
      if ($IsWin) {
          & npx.cmd $syncArgs
      } else {
          & npx $syncArgs
      }
  }

}
catch {
  Write-Error $_
  exit 1
}
finally {
  Pop-Location
}

Write-Host "完成。"
