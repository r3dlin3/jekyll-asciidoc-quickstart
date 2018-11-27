<#
.SYNOPSIS
 Script d'example pour l'article PowerShell
#>
param(
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    $ComputerName
)

Write-Host $ComputerName