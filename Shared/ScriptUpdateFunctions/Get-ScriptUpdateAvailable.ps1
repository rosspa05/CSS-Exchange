﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

. $PSScriptRoot\Invoke-WebRequestWithProxyDetection.ps1

<#
    Determines if the script has an update available.
#>
function Get-ScriptUpdateAvailable {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $VersionsUrl = "https://github.com/microsoft/CSS-Exchange/releases/latest/download/ScriptVersions.csv"
    )

    $BuildVersion = ""

    $scriptName = $script:MyInvocation.MyCommand.Name
    $scriptPath = [IO.Path]::GetDirectoryName($script:MyInvocation.MyCommand.Path)
    $scriptFullName = (Join-Path $scriptPath $scriptName)

    $result = [PSCustomObject]@{
        ScriptName         = $scriptName
        OriginalScriptName = $scriptName
        CurrentVersion     = $BuildVersion
        LatestVersion      = ""
        UpdateFound        = $false
        Error              = $null
    }

    if ((Get-AuthenticodeSignature -FilePath $scriptFullName).Status -eq "NotSigned") {
        Write-Warning "This script appears to be an unsigned test build. Skipping version check."
    } else {
        try {
            $versionData = [Text.Encoding]::UTF8.GetString((Invoke-WebRequestWithProxyDetection $VersionsUrl -UseBasicParsing).Content) | ConvertFrom-Csv
            $fileMatch = $versionData | Where-Object {
                $scriptName -match "\b$([System.IO.Path]::GetFileNameWithoutExtension($_.File))\b"
            }
            $latestVersion = $fileMatch.Version
            $result.LatestVersion = $latestVersion
            if ($null -ne $latestVersion -and $latestVersion -ne $BuildVersion) {
                $result.UpdateFound = $true
                $result.OriginalScriptName = $fileMatch.File
            }

            Write-Verbose "Current version: $($result.CurrentVersion) Latest version: $($result.LatestVersion) Update found: $($result.UpdateFound)"
        } catch {
            Write-Verbose "Unable to check for updates: $($_.Exception)"
            $result.Error = $_
        }
    }

    return $result
}
