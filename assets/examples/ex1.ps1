<#
.SYNOPSIS
 Script d'example pour l'article PowerShell
#>
param(
    $ComputerName
)

if (-not $ComputerName) {
    Write-Error "ComputerName is mandatory"
    Exit 1
}

Write-Host $ComputerName