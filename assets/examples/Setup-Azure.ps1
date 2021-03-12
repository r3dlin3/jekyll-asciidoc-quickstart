<#
.SYNOPSIS
    Script used to setup Azure for packer
.DESCRIPTION
    Script that will create in Azure for packer:
    - The required resource groups
    - A new service principal
    - The corresponding rights
.EXAMPLE
    PS C:`> .\Setup-Azure.ps1 -Location "West Europe" -ResourceGroupImage "rg-packer-img" -ResourceGroupPacker "rg-packer" -ServicePrincipalName "MyAzurePacker"
.NOTES
    Reference: https://github.com/hashicorp/packer/blob/master/contrib/azure-setup.sh
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({$locs =Get-AzureRmLocation; ($locs.Location -contains $_ -or $locs.DisplayName -contains $_)})]
    [string]
    $Location,

    # The Resource Group that will receive the image
    [Parameter(Mandatory)]
    [string]
    $ResourceGroupImage,
    
    [Parameter(Mandatory)]
    [string]
    $ResourceGroupPacker,

    [string]
    $ServicePrincipalName = "Azure Packer"
)
$ErrorActionPreference = "stop"

Function Ensure-RG {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Location,

        # The Resource Group that will receive the image
        [Parameter(Mandatory)]
        [string]
        $ResourceGroupName
    )

    $rg = Get-AzureRmResourceGroup -name $ResourceGroupName -EA 0
    if (-not $rg) {
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
    }
}

Function New-Password {
    [OutputType('System.SecureString')]
    [CmdletBinding()]
    param(
        [int]$length = 24
    )
    $MyBuffer = [System.Byte[]]::new($length)
    $Random = [System.Random]::new()
    $Random.NextBytes($MyBuffer)
    $encodedText =[Convert]::ToBase64String($MyBuffer)

    return $encodedText
}

Function Ensure-SPN {
    param(
        [Parameter(Mandatory)]
        [string]
        $ServicePrincipalName
    )

    $app = Get-AzureRmADServicePrincipal -DisplayName $ServicePrincipalName
    if ($app) {
        $PlainPassword = "XXX"
    } else {
        
        $PlainPassword = New-Password 
        $SecureStringPassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
        $app = New-AzureRmADServicePrincipal -DisplayName $ServicePrincipalName -Password $SecureStringPassword
        $app = Get-AzureRmADServicePrincipal -DisplayName $ServicePrincipalName
    }
    $object = New-Object -TypeName PSObject -Property (@{
            'ObjectId'=$app.Id;
            'ApplicationId'=$app.ApplicationId;
            'Password'=$PlainPassword
        })
    Write-Output $object
}

Function Ensure-Assignement {
    param(
        [Parameter(Mandatory)]
        [string]
        $ObjectId,

        [Parameter(Mandatory)]
        [string]
        $ResourceGroupName,

        [string]
        $Role = "Contributor"
    )
    
    New-AzureRmRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $role -ResourceGroupName $ResourceGroupName
}

function Start-SleepProgress{
    <#
        .NOTES 
            See https://gist.github.com/ctigeek/bd637eeaeeb71c5b17f4

    #>
    param(
        [Parameter(Mandatory)]
        [uint32]
        $seconds
    )
    $doneDT = (Get-Date).AddSeconds($seconds)
    while($doneDT -gt (Get-Date)) {
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        Write-Progress "Waiting $($seconds)s ..." ` -Status "Sleeping..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        Start-Sleep -Milliseconds 980
    }
    Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining 0 -Completed
}

$ctx = Get-AzureRmContext
$TenantId = $ctx.Tenant.TenantId
$SubscriptionId = $ctx.Subscription.SubscriptionId

Write-Host "Creating RG $ResourceGroupImage"
Ensure-RG -Location $Location -ResourceGroupName $ResourceGroupImage
Write-Host -ForegroundColor green  "$ResourceGroupImage created"

Write-Host "Creating RG $ResourceGroupPacker"
Ensure-RG -Location $Location -ResourceGroupName $ResourceGroupPacker
Write-Host -ForegroundColor green  "$ResourceGroupPacker created"


Write-Host "Creating SPN $ServicePrincipalName"
$app = Ensure-SPN -ServicePrincipalName $ServicePrincipalName
Write-Host -ForegroundColor green  "$ServicePrincipalName created"

Write-Host "Waiting a bit"
Start-SleepProgress 20 #value provided by MS...

Ensure-Assignement -ObjectId $app.ObjectId -ResourceGroupName $ResourceGroupImage
Write-Host -ForegroundColor green  "Role assigned to $ResourceGroupImage"
Ensure-Assignement -ObjectId $app.ObjectId -ResourceGroupName $ResourceGroupPacker
Write-Host -ForegroundColor green  "Role assigned to $ResourceGroupPacker"


Write-Host ""
Write-Host "Use the following configuration for your packer template:"
Write-Host ""
Write-Host "{"
Write-Host "    `"tenant_id`": `"$TenantId`","
Write-Host "    `"subscription_id`": `"$SubscriptionId`","
Write-Host "    `"client_id`": `"$($app.ApplicationId)`","
Write-Host "    `"client_secret`": `"$($app.Password)`","
Write-Host "    `"managed_image_resource_group_name`": `"$ResourceGroupImage`","
Write-Host "    `"build_resource_group_name`": `"$ResourceGroupPacker`""
Write-Host "}"
Write-Host ""
