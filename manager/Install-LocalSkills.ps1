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
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="vercel-react-best-practices" },
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="web-design-guidelines" },
    @{ Source="https://github.com/vercel-labs/skills"; Skill="find-skills" },
    @{ Source="https://github.com/vercel-labs/agent-browser"; Skill="agent-browser" },
    @{ Source="https://github.com/squirrelscan/skills"; Skill="audit-website" },
    @{ Source="https://github.com/supabase/agent-skills"; Skill="supabase-postgres-best-practices" },
    @{ Source="https://github.com/nextlevelbuilder/ui-ux-pro-max-skill"; Skill="ui-ux-pro-max" },
    @{ Source="https://github.com/better-auth/skills"; Skill="better-auth-best-practices" },
    @{ Source="https://github.com/vercel-labs/agent-skills"; Skill="vercel-composition-patterns" },
    @{ Source="https://github.com/obra/superpowers"; Skill="brainstorming" },
    @{ Source="https://github.com/callstackincubator/agent-skills"; Skill="react-native-best-practices" },
    @{ Source="https://github.com/browser-use/browser-use"; Skill="browser-use" },
    @{ Source="https://github.com/remotion-dev/skills"; Skill="remotion-best-practices" },
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
    @{ Source="https://github.com/CodingHeader/MySkills"; Skill="instruction_repeater" },
    @{ Source="https://github.com/CodingHeader/MySkills"; Skill="multi-agent-thinker" },
    @{ Source="https://github.com/CodingHeader/MySkills"; Skill="project-steward" },
    @{ Source="https://github.com/CodingHeader/MySkills"; Skill="project-structure-creator" }
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
Write-Host "Found $($skillsToInstall.Count) skills defined in script."
if ($useUniversal) { Write-Host "Mode: Universal (.agent/skills)" }
if ($Global) { Write-Host "Scope: Global" } else { Write-Host "Scope: Project ($repoRoot)" }

# Execute in Repo Root so local .agent/skills is found there
Push-Location $repoRoot
try {
  # Group skills by Source URL to optimize installations
  $groupedSkills = $skillsToInstall | Group-Object Source

  foreach ($group in $groupedSkills) {
        $source = $group.Name
        if ([string]::IsNullOrWhiteSpace($source)) {
            Write-Warning "Found group with empty source. Skipping."
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
            Write-Host "[SKIP] All skills from $source are installed." -ForegroundColor DarkGray
            continue
        }

        # If any skill is missing, we install only the requested skills
        Write-Host "[INSTALL] Processing $source..." -ForegroundColor Cyan
        Write-Host "Missing Skills: $($missingSkills -join ', ')"

        if ($WhatIf.IsPresent) {
            Write-Host "[WHATIF] Would clone $source and install: $($missingSkills -join ', ')"
            continue
        }

        # Clone repo to temp directory
        $tempDir = Join-Path $env:TEMP "os_skill_clone_$((Get-Random).ToString())"
        try {
            Write-Host "  Cloning repository..." -ForegroundColor DarkGray
            # Use git to clone (depth 1 for speed)
            $gitArgs = "clone --depth 1 $source `"$tempDir`""
            Start-Process -FilePath "git" -ArgumentList $gitArgs -NoNewWindow -Wait -PassThru | Out-Null
            
            if (-not (Test-Path $tempDir)) {
                Write-Error "Failed to clone repository: $source"
                continue
            }

            foreach ($skillName in $missingSkills) {
                # Find the skill directory within the cloned repo
                # Strategy 1: Check if root/$skillName exists
                $skillPath = Join-Path $tempDir $skillName
                
                if (-not (Test-Path $skillPath -PathType Container)) {
                    # Strategy 2: Search recursively for directory named $skillName
                    $foundDir = Get-ChildItem -Path $tempDir -Recurse -Directory -Filter $skillName -ErrorAction SilentlyContinue | Select-Object -First 1
                    
                    if ($foundDir) {
                        $skillPath = $foundDir.FullName
                    } else {
                        Write-Warning "  Could not find directory for skill '$skillName' in cloned repo. Skipping."
                        continue
                    }
                }

                Write-Host "  Installing $skillName from $skillPath..."

                # Construct OpenSkills command for LOCAL installation
                $argsList = @('openskills@latest','install', $skillPath, '-y')
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
                    Write-Warning "  Install command for $skillName finished with code $LASTEXITCODE."
                }
            }
        }
        catch {
            Write-Warning "An error occurred while processing $source : $_"
        }
        finally {
            # Cleanup temp clone
            if (Test-Path $tempDir) { 
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue 
            }
        }
    }

  # Final Step: Sync
  Write-Host "`n[SYNC] Generating AGENTS.md..." -ForegroundColor Green
  # Added -y to sync command to avoid interactive prompts
  $syncArgs = @('openskills@latest', 'sync', '-y')
  if ($WhatIf.IsPresent) {
      Write-Host "[WHATIF] Would run: npx openskills@latest sync -y"
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

Write-Host "Done."
