<#
.SYNOPSIS
 Script d'example pour l'article PowerShell
#>
param(
    [Parameter(ParameterSetName="subname", Mandatory)]
    [string]
    $subname,

    [Parameter(ParameterSetName="subid", Mandatory)]
    [string]
    $subid,
    
    
    [Parameter(Mandatory)]
    $inputFile
)
if ($PsCmdlet.ParameterSetName -eq "subname") {
    Write-Host "Nom de la souscription: $subname"
} else {
    Write-Host "Identifiant de la souscription: $subid"
}

Write-Host $inputFile