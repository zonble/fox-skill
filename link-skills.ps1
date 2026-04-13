param(
    [string]$SourceRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$SourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)
$TargetDirs = @(
    $(if ($env:TARGET_DIR_1) { $env:TARGET_DIR_1 } else { Join-Path $env:USERPROFILE ".codex\skills" }),
    $(if ($env:TARGET_DIR_2) { $env:TARGET_DIR_2 } else { Join-Path $env:USERPROFILE ".claude\skills" }),
    $(if ($env:TARGET_DIR_3) { $env:TARGET_DIR_3 } else { Join-Path $env:USERPROFILE ".gemini\skills" })
)

function Get-LinkTarget {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$Item
    )

    $target = $Item.Target
    if ($target -is [array]) {
        $target = $target[0]
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        return $null
    }

    return [System.IO.Path]::GetFullPath($target)
}

foreach ($dir in $TargetDirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$skillDirs = Get-ChildItem -LiteralPath $SourceRoot -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "SKILL.md")
}

foreach ($skillDir in $skillDirs) {
    foreach ($targetRoot in $TargetDirs) {
        $targetPath = Join-Path $targetRoot $skillDir.Name

        if (Test-Path -LiteralPath $targetPath) {
            $item = Get-Item -LiteralPath $targetPath -Force
            $isLink = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)

            if (-not $isLink) {
                [Console]::Error.WriteLine("warn: $targetPath exists and is not a symlink or junction, skipped")
                continue
            }

            $currentTarget = Get-LinkTarget -Item $item
            if ($currentTarget -eq $skillDir.FullName) {
                Write-Output "skip: $targetPath already points to $($skillDir.FullName)"
                continue
            }

            Remove-Item -LiteralPath $targetPath -Force
        }

        New-Item -ItemType Junction -Path $targetPath -Target $skillDir.FullName | Out-Null
        Write-Output "linked: $targetPath -> $($skillDir.FullName)"
    }
}
