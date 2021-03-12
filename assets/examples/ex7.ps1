<#
.SYNOPSIS
 Script d'example pour l'article PowerShell
#>
param()

function Get-Output {
    [CmdletBinding()]
    param (

    )
    Write-Host "Hello1"
    "Hello2"
    Write-Output "Hello3"
    return "Hello4"
}
$a = Get-Output

Write-Host "Contenu de `$a:"
$a