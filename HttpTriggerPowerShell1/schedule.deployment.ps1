#
# Take a JSON payload in the following format to kick off a new member deployment
# {
#    "id"                   : "An ID for the request to allow it to be tracked for it's lifetime",
#    "location"             : "An azure location for the deployment",
#    "rgName"               : "Resource group name",
#    "dashboardIp"          : "IP Address of the registrar node",
#    "subName"              : "Azure Subscription Name",
#    "templateParamsUri"    : "A link to the ARM template parameters file for the deployment"
# }
#

function ExtendJsonObject($originalObject, $propName, $propValue) {
    Add-Member -InputObject $originalObject Timestamp ((Get-Date).ToString())  
    return $originalObject
}

$payload = Get-Content $req -Raw | ConvertFrom-Json
$queueMessageObject = ExtendJsonObject $payload Timestamp ((Get-Date).ToString())
$queueMessageJson = $queueMessage | ConvertTo-Json

#Write-Output "Testing Write Output Works"

#$queueMessage | % {Write-Output $_}

Out-File -Encoding Ascii -FilePath $outputQueueItem -inputObject $queueMessageJson    
Out-File -Encoding Ascii -FilePath $res -inputObject $queueMessageJson

