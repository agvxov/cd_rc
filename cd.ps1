# Plugin: cd_rc (PowerShell port)
# Description: Replaces vanilla cd with a directory-stack-aware cd,
#              custom formatting of the stack, and common directory-change helpers.
# Author: Anon
# Date: 2026
# Version: 2.0

# -- core functions

function global:mkdircd {
    if ($args.Count -eq 0) { return }

    foreach ($d in $args) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
    cd $args[-1]
}

function global:cdUp {
    $levels = if ($args.Count -eq 0) { 1 } else { [int]$args[0] }

    $target = $PWD.Path
    for ($i = 0; $i -lt $levels; $i++) {
        $parent = Split-Path $target -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $target) { break }
        $target = $parent
    }
    cd $target
}

function global:__mydirs {
    $entries = @($PWD.Path) + @((Get-Location -Stack).ToArray() | ForEach-Object { $_.Path })

    $ln = 0
    foreach ($d in $entries) {
        $bad_prefix = 'Microsoft.PowerShell.Core\FileSystem::'
        $display = if ($d.StartsWith($bad_prefix)) { $d.Substring($bad_prefix.Length) } else { $d }

        $color = if (Test-Path -LiteralPath $d -PathType Container) {
            [System.ConsoleColor]::Cyan
        } else {
            [System.ConsoleColor]::Red
        }

        Write-Host -NoNewLine ("{0,2}: " -f $ln) -ForegroundColor $color
        Write-Host $display -ForegroundColor ([System.ConsoleColor]::White)
        $ln++
    }
}

# -- wrappers

Remove-Item Alias:cd    -Force -ErrorAction SilentlyContinue
Remove-Item Alias:popd  -Force -ErrorAction SilentlyContinue
Remove-Item Alias:pushd -Force -ErrorAction SilentlyContinue

function global:cd {
    Push-Location $args[0]
    if ($?) { __mydirs }
}

function global:popd { 
    Pop-Location
    if ($?) { __mydirs }
}

function global:pop  { popd }
function global:cdh  { cd $HOME }
function global:cdu  { cdUp @args }
function global:dirs { __mydirs }
function global:pushd { cd @args }  # keep pushd working as an alias
