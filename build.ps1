#!/usr/bin/env pwsh

param(
    [Parameter()]
    [switch]
    $Bootstrap,

    [Parameter()]
    [switch]
    $Test,

    [Parameter()]
    [switch]
    $Package
)

$NeededTools = @{
    Pester = "Pester latest"
}

function needsPester() {
    if (Get-Module -ListAvailable -Name Pester) {
        return $false
    }
    return $true
}

function getMissingTools () {
    $missingTools = @()

    if (needsPester) {
        $missingTools += $NeededTools.Pester
    }

    return $missingTools
}

function hasMissingTools () {
    return ((getMissingTools).Count -gt 0)
}

if ($Bootstrap) {
    $string = "Here is what your environment is missing:`n"
    $missingTools = getMissingTools

    if (($missingTools).Count -eq 0) {
        $string += "* nothing!`n`n Run this script without a flag to build or a -Clean to clean."
    }
    else {
        $missingTools | ForEach-Object {$string += "* $_`n"}
    }

    Write-Output "`n$string`n"
}
elseif (hasMissingTools) {
    Write-Output "You are missing needed tools. Run './build.ps1 -Bootstrap' to see what they are."
}
else {
    if ($Test) {
        Push-Location $PSScriptRoot\test
        $res = Invoke-Pester -OutputFormat NUnitXml -OutputFile TestsResults.xml -PassThru
        if ($env:APPVEYOR) {
            (New-Object System.Net.WebClient).UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path .\TestsResults.xml));
        }
        if ($res.FailedCount -gt 0) { throw "$($res.FailedCount) tests failed."}
        Pop-Location
    }

    if ($Package) {
        if ((Test-Path "$PSScriptRoot\out")) {
            Remove-Item -Path $PSScriptRoot\out -Recurse -Force
        }

        $null = New-Item -ItemType directory -Path $PSScriptRoot\out
        $null = New-Item -ItemType directory -Path $PSScriptRoot\out\PSNotifySend

        Copy-Item -Path "$PSScriptRoot\src\PSNotifySend.ps*1" -Destination "$PSScriptRoot\out\PSNotifySend\" -Force
        Copy-Item -Path "$PSScriptRoot\README.md" -Destination "$PSScriptRoot\out\PSNotifySend\" -Force
        Copy-Item -Path "$PSScriptRoot\LICENSE" -Destination "$PSScriptRoot\out\PSNotifySend\" -Force
        Copy-Item -Path "$PSScriptRoot\src\powershell-logo.png" -Destination "$PSScriptRoot\out\PSNotifySend\" -Force
        Copy-Item -Path "$PSScriptRoot\src\Public" -Destination "$PSScriptRoot\out\PSNotifySend\" -Force -Recurse
        Copy-Item -Path "$PSScriptRoot\src\Private" -Destination "$PSScriptRoot\out\PSNotifySend\" -Force -Recurse
    }
}
