<#
.SYNOPSIS
 Script d'example pour l'article PowerShell
#>
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    $inputFile
)

Write-Host $inputFile