# Plugin: cd_rc (PowerShell port)
# Description: Replaces vanilla cd with a directory-stack-aware cd, custom formatting of the stack, and common directory-change helpers.
# Author: Anon
# Date: 2026
# Version: 1.0

# XXX:
# there is a builtin Push-Location and Pop-Location

# -- state
$global:__DirectoryStack = @($PWD.Path)

# -- core functions
function global:mkdircd {
    if ($args.Count -eq 0) { return }

    foreach ($d in $args) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
    __mypushd $args[-1]
}

function global:cdUp {
    $levels = if ($args.Count -eq 0) { 1 } else { [int]$args[0] }

    $target = $PWD.Path
    for ($i = 0; $i -lt $levels; $i++) {
        $parent = Split-Path $target -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $target) { break }
        $target = $parent
    }
    __mypushd $target
}

function global:__mypushd ([string]$Path) {
    try {
        Set-Location -LiteralPath $Path -ErrorAction Stop
        $global:__DirectoryStack += $PWD.Path
        __mydirs
    } catch {
        Write-Error "cd: $_"
        return $false
    }
}

function global:__mypopd {
    if ($global:__DirectoryStack.Count -lt 2) {
        Write-Error "popd: directory stack is empty"
        return $false
    }

    $target = $global:__DirectoryStack[-2]
    try {
        Set-Location -LiteralPath $target -ErrorAction Stop
        $global:__DirectoryStack = $global:__DirectoryStack[0..($global:__DirectoryStack.Count - 2)]
        __mydirs
    } catch {
        Write-Error "popd: $_"
        return $false
    }
}

function global:__mydirs {
    $ln = 0
    for ($i = $global:__DirectoryStack.Count - 1; $i -ge 0; $i--) {
        $d = $global:__DirectoryStack[$i]
        if (Test-Path -LiteralPath $d -PathType Container) {
            $color = [System.ConsoleColor]::Cyan
        } else {
            $color = [System.ConsoleColor]::Red
        }

        $label = "{0,2}: " -f $ln
        Write-Host -NoNewLine $label -ForegroundColor $color
        Write-Host $d -ForegroundColor ([System.ConsoleColor]::White)
        $ln++
    }
}

# -- wrappers

# NOTE: cd.. can't be a function name in PowerShell

Remove-Item Alias:cd    -Force
Remove-Item Alias:popd  -Force
Remove-Item Alias:pushd -Force

function global:cdh  { __mypushd $HOME }
function global:cdu  { cdUp @args }
function global:cd   { __mypushd $args }
function global:popd { __mypopd }
function global:pop  { __mypopd }
function global:dirs { __mydirs }
