#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
Param
(
    [string]   $ProfileLocation,
    [string[]] $TargetPaths  = @('\AppData\Local\Temp'),
    [string[]] $ExcludeUsers = @(),
    [string]   $ExportCsv
)

Clear-Host

$profilePath = if ([string]::IsNullOrWhiteSpace($ProfileLocation)) {
    Split-Path -Parent $env:USERPROFILE
} else {
    $ProfileLocation
}

if (-not (Test-Path -Path $profilePath -PathType Container))
{
    throw "Profile path '$profilePath' was not found."
}

$alwaysSkip = @('Default', 'Default User', 'Public', 'All Users')

Write-Host 'Finding user profiles... ' -NoNewline
$users = Get-ChildItem -Path $profilePath -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin $alwaysSkip -and $_.Name -notin $ExcludeUsers }
Write-Host 'OK' -ForegroundColor Green

if (-not $users)
{
    Write-Warning "No user profiles found under '$profilePath'."
    return
}

function Get-FolderSize
{
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) { return 0 }

    $measure = Get-ChildItem -Path $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum
    return [double]$measure.Sum
}

$diskSummaryAvailable = $profilePath -match '^[A-Za-z]:\\'
$totalSpaceBefore = $null
$driveLetter = $null

if ($diskSummaryAvailable)
{
    $driveLetter = $profilePath.Substring(0, 2)
    try
    {
        $totalSpaceBefore = [double](Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$driveLetter'" -ErrorAction Stop).FreeSpace
    }
    catch
    {
        Write-Warning "Could not query drive $driveLetter : $($_.Exception.Message)"
        $diskSummaryAvailable = $false
    }
}

$userStats    = [System.Collections.Generic.List[PSCustomObject]]::new()
$counter      = 0
$totalUsers   = $users.Count
$skippedItems = 0

foreach ($user in $users)
{
    $counter++
    Write-Progress -Activity 'Cleaning user profiles' -Status $user.Name -PercentComplete (($counter / $totalUsers) * 100)

    $freedBytes = 0

    foreach ($relativePath in $TargetPaths)
    {
        $fullPath = Join-Path -Path $user.FullName -ChildPath $relativePath

        if (-not (Test-Path -Path $fullPath -PathType Container)) { continue }

        $sizeBefore = Get-FolderSize -Path $fullPath

        if ($PSCmdlet.ShouldProcess($fullPath, 'Clear folder contents'))
        {
            $items = Get-ChildItem -Path $fullPath -Force -ErrorAction SilentlyContinue
            foreach ($item in $items)
            {
                try
                {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                }
                catch
                {
                    $skippedItems++
                }
            }
        }

        $sizeAfter   = Get-FolderSize -Path $fullPath
        $freedBytes += ($sizeBefore - $sizeAfter)
    }

    $userStats.Add([PSCustomObject]@{
        User         = $user.Name
        'Freed (MB)' = [math]::Round($freedBytes / 1MB, 2)
    })
}

Write-Progress -Activity 'Cleaning user profiles' -Completed

$totalSpaceAfter = $null
if ($diskSummaryAvailable)
{
    try
    {
        $totalSpaceAfter = [double](Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$driveLetter'" -ErrorAction Stop).FreeSpace
    }
    catch
    {
        $diskSummaryAvailable = $false
    }
}

Write-Host "`n================================================================================"
Write-Host '                                PER-USER DETAILS'
Write-Host '================================================================================'
$userStats | Format-Table -AutoSize

Write-Host '================================================================================'
Write-Host '                                  DISK SUMMARY'
Write-Host '================================================================================'
if ($diskSummaryAvailable)
{
    Write-Host " Before      : $([math]::Round($totalSpaceBefore / 1GB, 2)) GB"
    Write-Host " After       : $([math]::Round($totalSpaceAfter  / 1GB, 2)) GB"
    Write-Host " Difference  : $([math]::Round(($totalSpaceAfter - $totalSpaceBefore) / 1MB, 2)) MB"
}
else
{
    Write-Host ' Disk summary unavailable (non-local path or WMI query failed).'
}
if ($skippedItems -gt 0)
{
    Write-Host " Skipped items (locked/in use) : $skippedItems" -ForegroundColor Yellow
}
Write-Host "================================================================================`n"

if ($ExportCsv)
{
    $userStats | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Report exported to $ExportCsv"
}
