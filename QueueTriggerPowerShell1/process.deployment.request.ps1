#
# 
#

$in = Get-Content $triggerInput
Write-Output "PowerShell script processed queue message '$in'"

Set-Variable contentRoot "https://raw.githubusercontent.com/mormond" -Option Constant
Set-Variable ethereumArmTemplates "ethereum-arm-templates" -Option Constant
Set-Variable ethereumDevVm "ethereum-dev-vm" -Option Constant
Set-Variable ethereumMemberServices "ethereum-consortium-member-services" -Option Constant

function AuthenticateWithAzure($appid, $tenant, $secret) {
    $secpasswd = ConvertTo-SecureString $secret -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($appid, $secpasswd)
    $result = Login-AzureRmAccount -ServicePrincipal -Tenant $tenant -Credential $mycreds
    Write-Debug "Login result: $result"
}

function SetAzureSubscription($subName) {
    Write-Debug "Setting subscription to: $subName"
    Select-AzureRmSubscription -SubscriptionName $subName
}

function CreateNewResourceGroup($rgName, $location) {
    Write-Debug "Creating new resource group: $rgName"
    New-AzureRmResourceGroup -Location $location -Name $rgName -Force
}

function CaptureRequestParameters() {
    $requestBody = Get-Content $req -Raw | ConvertFrom-Json

    $props = @{
        location = $requestBody.location
        rgName = $requestBody.rgName
        dashboardIp = $requestBody.dashboardIp
        subName = $requestBody.subName
        templateParamsUri = $requestBody.templateParamsUri
    }
    return new-object psobject -Property $props
}

$requestParams = CaptureRequestParameters

$login = AuthenticateWithAzure $ENV:SP_AppID $ENV:SP_Tenant $ENV:SP_Secret

SetAzureSubscription $requestParams.subName
CreateNewResourceGroup $requestParams.rgName $requestParams.location

Write-Output $requestParams.dashboardIp

#
# Need to pull the params file locally due to this issue: https://github.com/Azure/azure-powershell/issues/2414 
# (Can't combine command line params with -TemplateParameterUri - only works with -TemplateParameterFile)
#
$paramsFile = "D:\Local\Temp\template.consortium.params.participant1.json"

Invoke-WebRequest -UseBasicParsing `
    -Uri $requestParams.templateParamsUri `
    -OutFile $paramsFile -Verbose

Write-Output "Params File Downloaded"

Write-Output "Starting Deployment"

$ethOutputs = New-AzureRmResourceGroupDeployment `
    -TemplateUri "$contentRoot/$ethereumArmTemplates/master/ethereum-consortium/template.consortiumMember.json" `
    -TemplateParameterFile $paramsFile `
    -ResourceGroupName $requestParams.rgName `
    -dashboardIp $requestParams.dashboardIp `
    -registrarIp $requestParams.dashboardIp 

    $consortiumMemberName = $ethOutputs.Parameters.consortiumMemberName.value
    $vnetName = "$consortiumMemberName-vnet"

Out-File -Encoding Ascii -FilePath $res -inputObject $ethOutputs